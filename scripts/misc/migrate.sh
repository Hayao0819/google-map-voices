#!/usr/bin/env bash

set -eEuo pipefail
script_dir=$(cd "$(dirname "${0}")" && pwd)
data_dir="${script_dir}/../../data"
output_dir="${script_dir}/../../output"

temp_dir=""
extracted_dir="" # $temp_dir/extracted
converted_dir="" # $temp_dir/converted

legacy_json="${data_dir}/legacy.json"
voices_json="${data_dir}/voices.json"

init() {
	temp_dir=$(mktemp -d)
	trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM
	mkdir -p "$output_dir"
	extracted_dir="$temp_dir/extracted"
	converted_dir="$temp_dir/converted"
	mkdir -p "$extracted_dir" "$converted_dir"
}

parse_arg() {
	local OPTARG OPTIND opt
	while getopts ":h" opt; do
		case $opt in
		h)
			echo "Usage: $0 [-h]"
			echo "  -h            Show this help message"
			exit 0
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			return 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			return 1
			;;
		esac
	done
	shift $((OPTIND - 1)) || true
}

# get_new_filename new_id:int -> new_filename:string
get_new_filename() {
	local _id="$1"
	local _new_filename
	_new_filename=$(jq -r ".instructions.base[] | select(.id == $_id) | .filename" "$voices_json")
	if [[ -z "$_new_filename" ]] || [[ "$_new_filename" == "null" ]]; then
		echo "Error: No matching voice found for id '$_id'" >&2
		return 1
	fi
	echo "$_new_filename"
}

# get_new_id_by_old_id legacy_id:int -> new_id:int
get_new_id_by_legacy_id() {
	local _legacy_id="$1"
	local _new_id
	_new_id=$(jq -r ".by_id[] | select(.legacy_id == $_legacy_id) | .new_id" "$legacy_json")
	if [[ -z "$_new_id" ]] || [[ "$_new_id" == "null" ]]; then
		echo "Error: No matching new_id found for legacy_id '$_legacy_id'" >&2
		return 1
	fi
	echo "$_new_id"
}

# get_new_id_by_type legacy_type:string -> new_id:int
get_new_id_by_type() {
	local _legacy_type="$1"
	local _new_id
	_new_id=$(jq -r ".by_type[] | select(.legacy_type == \"$_legacy_type\") | .new_id" "$legacy_json")
	if [[ -z "$_new_id" ]]; then
		echo "Error: No matching new_id found for legacy_type '$_legacy_type'" >&2
		return 1
	fi
	echo "$_new_id"
}

# get_new_id_by_range_exact legacy_min:int legacy_max:int -> new_id:int
get_new_id_by_range_exact() {
	local _legacy_min="$1"
	local _legacy_max="$2"
	local _new_id
	_new_id=$(jq -r ".by_range[] | select(.legacy_min == $_legacy_min and .legacy_max == $_legacy_max) | .new_id" "$legacy_json")
	if [[ -z "$_new_id" ]] || [[ "$_new_id" == "null" ]]; then
		echo "Error: No matching new_id found for legacy range '$_legacy_min - $_legacy_max'" >&2
		return 1
	fi
	echo "$_new_id"
}

# get_new_id_by_range_numeric legacy_min:int legacy_max:int -> new_id:int
get_new_id_by_range_numeric() {
	local _legacy_min="$1"
	local _legacy_max="$2"
	local _new_id

	_new_id=$(jq -r --argjson min "$_legacy_min" --argjson max "$_legacy_max" '.by_range[] | select((.legacy_min <= $min and .legacy_max >= $max) or (.legacy_min <= $max and .legacy_max >= $min)) | .new_id' "$legacy_json")

	if [[ -z "$_new_id" ]] || [[ "$_new_id" == "null" ]]; then
		echo "Error: No matching new_id found for legacy range '$_legacy_min - $_legacy_max'" >&2
		return 1
	fi

	echo "$_new_id" | head -n 1
}

# get_new_id_by_range_value value:int -> new_id:int
get_new_id_by_range_value() {
	local _value="$1"
	local _new_id

	# jq内で数値比較を行い、指定された数値が範囲内にある項目を検索
	_new_id=$(jq -r --argjson val "$_value" '.by_range[] | select(.legacy_min <= $val and .legacy_max >= $val) | .new_id' "$legacy_json")

	if [[ -z "$_new_id" ]] || [[ "$_new_id" == "null" ]]; then
		echo "Error: No matching new_id found for value '$_value'" >&2
		return 1
	fi

	# 複数一致した場合に備えて、最初のIDのみを返す
	echo "$_new_id" | head -n 1
}

# get_old_filename old_xml_path:string new_id:int -> old_filename:string
get_old_filename() {
	local _path="$1"
	local _new_id="$2"
	local _old_filename

	# First, find the legacy_id or legacy_type corresponding to the new_id
	local legacy_info
	legacy_info=$(jq -r ".by_id[] | select(.new_id == $_new_id)" "$legacy_json")
	if [[ -z "$legacy_info" ]]; then
		legacy_info=$(jq -r ".by_type[] | select(.new_id == $_new_id)" "$legacy_json")
	fi
	if [[ -z "$legacy_info" ]]; then
		legacy_info=$(jq -r ".by_range[] | select(.new_id == $_new_id)" "$legacy_json")
	fi

	if [[ -n "$legacy_info" ]]; then
		local legacy_id
		legacy_id=$(echo "$legacy_info" | jq -r '.legacy_id // empty')
		local legacy_type
		legacy_type=$(echo "$legacy_info" | jq -r '.legacy_type // empty')
		local legacy_min
		legacy_min=$(echo "$legacy_info" | jq -r '.legacy_min // empty')
		local legacy_max
		legacy_max=$(echo "$legacy_info" | jq -r '.legacy_max // empty')

		# Use xmllint to find the original filename based on the legacy info
		if [[ -n "$legacy_id" ]]; then
			_old_filename=$(xmllint --xpath "string(//maneuver_message[@id='${legacy_id}'])" "${_path}" 2>/dev/null)
		elif [[ -n "$legacy_type" ]]; then
			_old_filename=$(xmllint --xpath "string(//predefined_message[@type='${legacy_type}'])" "${_path}" 2>/dev/null)
		elif [[ -n "$legacy_min" ]] && [[ -n "$legacy_max" ]]; then
			_old_filename=$(xmllint --xpath "string(//distance_message[@min='${legacy_min}'][@max='${legacy_max}'])" "${_path}" 2>/dev/null)
		fi
	fi

	if [[ -z "${_old_filename-""}" ]]; then
		echo "Error: No matching old filename found for new_id '$_new_id'" >&2
		return 1
	fi
	echo "$_old_filename"
}

# get_filename path:string -> xml:string
get_filename() {
	local _path="$1"
	local _output_xml="<voice_instructions>"

	# Extract maneuver_message elements using xmllint
	while read -r attr_list; do
		local _id
		local _suppressed=false
		if [[ $attr_list =~ id=\"([0-9]+)\" ]]; then
			_id="${BASH_REMATCH[1]}"
		fi
		if [[ $attr_list =~ suppressed=\"true\" ]]; then
			_suppressed=true
		fi

		if [[ "$_suppressed" == true ]]; then
			continue
		fi

		local new_id
		new_id=$(get_new_id_by_legacy_id "$_id") || continue

		if [[ -n "$new_id" ]]; then
			local old_filename
			# Use the new function to get the old filename
			old_filename=$(get_old_filename "$_path" "$new_id")
			_output_xml+="\n  <canned_message id=\"$new_id\">$old_filename</canned_message>"
		fi
	done < <(xmllint --xpath '//maneuver_message' "$_path" 2>/dev/null | grep -oP 'id="[0-9]+"[^>]*')

	# Extract predefined_message elements
	while read -r attr_list; do
		local _type
		if [[ $attr_list =~ type=\"([A-Z_]+)\" ]]; then
			_type="${BASH_REMATCH[1]}"
		fi

		local new_id
		new_id=$(get_new_id_by_type "$_type") || continue

		if [[ -n "$new_id" ]]; then
			local old_filename
			old_filename=$(get_old_filename "$_path" "$new_id")
			_output_xml+="\n  <canned_message id=\"$new_id\">${old_filename}</canned_message>"
		fi
	done < <(xmllint --xpath '//predefined_message' "$_path" 2>/dev/null | grep -oP 'type="[A-Z_]+"[^>]*')

	# Extract distance_message elements
	while read -r attr_list; do
		local _min
		local _max
		if [[ $attr_list =~ min=\"([0-9]+)\" ]]; then
			_min="${BASH_REMATCH[1]}"
		fi
		if [[ $attr_list =~ max=\"([0-9]+)\" ]]; then
			_max="${BASH_REMATCH[1]}"
		fi

		local new_id
		if [[ -n "$_min" ]] && [[ -n "$_max" ]]; then
			new_id=$(get_new_id_by_range_numeric "$_min" "$_max") || continue
		fi

		if [[ -n "$new_id" ]]; then
			local old_filename
			old_filename=$(get_old_filename "$_path" "$new_id")
			_output_xml+="\n  <canned_message id=\"$new_id\">$old_filename</canned_message>"
		fi
	done < <(xmllint --xpath '//distance_message' "$_path" 2>/dev/null | grep -oP 'min="[0-9]+"[^>]*')

	_output_xml+="\n</voice_instructions>"
	echo -e "$_output_xml" | xmllint --format -
}

get_filename "$1"
# get_old_filename "$1" "$2"

#!/usr/bin/env bash

set -eEuo pipefail

script_dir=$(cd "$(dirname "${0}")" && pwd)
export GMV_CORE_DIR="${script_dir}/../core"

target_charactor=""
target_id=()
output_dir=""
voices_json_path="$script_dir/../data/voices.json"
instructions=()
charactors=()

# shellcheck source=/dev/null
source "$GMV_CORE_DIR/voicevox.sh"

function usage() {
	echo "Usage: $0 [options] voice output" >&2
	echo "  voice: charactor name defined in $voices_json_path" >&2
	echo "  output: output directory" >&2
	echo "" >&2
	echo "Options:" >&2
	echo "  -i: target id (can be specified multiple times)" >&2
	echo "  -h: show this help message" >&2
}

function init() {
	local opt OPTARG OPTIND
	while getopts ":hi:" opt; do
		case $opt in
		h)
			usage
			return 0
			;;
		i)
			target_id+=("$OPTARG")
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			return 1
			;;
		esac
	done

	shift $((OPTIND - 1))

	target_charactor="${1:-}"
	output_dir="${2:-}"
	if [[ -z "$output_dir" ]] || [[ -z "$target_charactor" ]]; then
		usage
		return 1
	fi

	readarray -t instructions < <(jq -c '.instructions.base[]' "$voices_json_path")
	readarray -t charactors < <(jq -c '.voices[]' "$voices_json_path")

	# filter by target_id if specified
	if ((${#target_id[@]} > 0)); then
		local _filtered=() _id
		for _id in "${target_id[@]}"; do
			local _found
			_found=$(printf "%s\n" "${instructions[@]}" | jq --exit-status "select(.id == $_id)") || {
				echo "Warning: id $_id not found" >&2
				continue
			}
			_filtered+=("$_found")
			unset _found
		done
		if ((${#_filtered[@]} > 0)); then
			instructions=("${_filtered[@]}")
			unset _filtered_voices
		else
			echo "Error: no voices found for specified ids" >&2
			return 1
		fi
		unset _id
	fi

	mkdir -p "$output_dir"
}

# util: select_charactor "charactor_name" -> json
function select_charactor() {
	local _setected_json
	_selected_json="$(printf "%s\n" "${charactors[@]}" | jq "select(.name == \"$1\")")"
	if [[ -z "$_selected_json" ]]; then
		echo "Error: charactor $1 not found" >&2
		return 1
	fi
	echo "$_selected_json"
}

# util: call_charactor "charactor_name" "args..."
function call_charactor() {
	local _selected_json
	_selected_json="$(select_charactor "$1")" || return 1
	shift

	local _source _command
	_source=$(jq -r '.source' <<<"$_selected_json")
	_command=$(jq -r '.command' <<<"$_selected_json")
	if [[ -z "$_source" ]] || [[ -z "$_command" ]]; then
		echo "Error: charactor $1 has no source or command" >&2
		return 1
	fi

	# shellcheck source=/dev/null
	source "$GMV_CORE_DIR/$_source"

	"$_command" "$@"
}

function main() {
	local _charactor_source

	local _v
	for _v in "${instructions[@]}"; do
		local _id _text _filename
		_id=$(jq -r '.id' <<<"$_v")
		_text=$(jq -r '.text' <<<"$_v")
		_filename=$(jq -r '.filename' <<<"$_v")

		if [[ -z "$_text" ]]; then
			echo "Skipping id $_id (no text)"
			continue
		fi

		local _output_path="$output_dir/${_filename}.wav"

		call_charactor "$target_charactor" "$_text" "$_output_path" --speed-scale 1.1 || {
			echo "Error: failed to generate id $_id" >&2
			exit 1
		}
		echo "Generated id $_id: $_text -> $_output_path"
	done
}

init "$@" && main

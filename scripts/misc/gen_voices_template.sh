#!/usr/bin/env bash

set -eEuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
messages_xml=""
output_json=""

init() {
	local opt OPTARG OPTIND
	while getopts ":h" opt; do
		case $opt in
		h)
			echo "Usage: $0 [-h] <path to messages.xml> [<output_json>]"
			echo "  -h  Show this help message and exit"
			exit 0
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			return 1
			;;
		esac
	done
	shift $((OPTIND - 1))

	# Validate arguments
	if [[ $# -eq 0 ]]; then
		echo "Error: Missing required argument '<path to messages.xml>'" >&2
		return 1
	fi

	# Set positional arguments
	messages_xml="$1"
	output_json="${2-"${script_dir}/../../data/voices_template.json"}"

	# Check for required commands
	if ! command -v xmllint &>/dev/null; then
		echo "Error: 'xmllint' is not installed." >&2
		return 1
	fi
	if ! command -v jq &>/dev/null; then
		echo "Error: 'jq' is not installed." >&2
		return 1
	fi

	return 0
}

get_ids() {
	xmllint "$messages_xml" --xpath "/voice_instructions/canned_message/@id" | cut -d "=" -f 2 | tr -d "\""
}

get_filename_by_id() {
	local id="$1"
	xmllint "$messages_xml" --xpath "/voice_instructions/canned_message[@id='${id}']/text()"
}

main() {
	local json_line_template='{"filename": "%s", "id": %d, "text": ""}'
	local json_lines=()

	while read -r id; do
		local filename
		filename=$(get_filename_by_id "$id" | cut -d "." -f 1)
		#shellcheck disable=SC2059
		json_lines+=("$(printf "$json_line_template" "$filename" "$id")")
	done < <(get_ids)

	# Create the base instructions array
	local base_instructions
	base_instructions=$(
		jq -n \
			--slurpfile lines <(printf "%s\n" "${json_lines[@]}") \
			'$lines'
	)

	# Generate the complete JSON structure according to voices_schema.json
	jq -n \
		--argjson base_data "$base_instructions" \
		'{
			"$schema": "./voices_schema.json",
			"voices": [
				{
					"name": "template_voice",
					"source": "template.sh",
					"command": ["template", "%TEXT%", "%OUTPUT_PATH%"]
				}
			],
			"instructions": {
				"base": $base_data,
				"override": {}
			}
		}' | jq '. | to_entries | sort_by(.key) | from_entries' >"$output_json"

	echo "Processed XML and saved to $output_json" >&2
	return 0
}

init "$@" && main

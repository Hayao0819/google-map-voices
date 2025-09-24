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
	output_json="${2-"${script_dir}/../../data/legacy_template.json"}"

	# Check for required commands
	if ! command -v xmllint &>/dev/null; then
		echo "Error: 'xmllint' is not installed." >&2
		return 1
	fi
	if ! command -v jq &>/dev/null; then
		echo "Error: 'jq' is not installed." >&2
		return 1
	fi
	if ! command -v grep &>/dev/null; then
		echo "Error: 'grep' is not installed." >&2
		return 1
	fi
	if ! command -v sed &>/dev/null; then
		echo "Error: 'sed' is not installed." >&2
		return 1
	fi

	return 0
}

main() {
	# Process 'maneuver_message' and capture JSON output
	local json_by_id
	json_by_id=$(
		xmllint --xpath '/voice_instructions/maneuver_message' "$messages_xml" 2>/dev/null |
			grep -oE '<maneuver_message[^>]*>' |
			sed -E 's/.*id="([0-9]+)".*/{"legacy_id": \1, "legacy_filename": null, "new_id": null, "memo": null}/' |
			jq -s '.'
	)

	# Process 'predefined_message' and capture JSON output
	local json_by_type
	json_by_type=$(
		xmllint --xpath '/voice_instructions/predefined_message' "$messages_xml" 2>/dev/null |
			grep -oE '<predefined_message[^>]*>' |
			sed -E 's/.*type="([^"]+)".*/{"legacy_type": "\1", "new_id": 0}/' |
			jq -s '.'
	)

	# Process 'distance_message' and capture JSON output
	local json_by_range
	json_by_range=$(
		xmllint --xpath '/voice_instructions/distance_message' "$messages_xml" 2>/dev/null |
			grep -oE '<distance_message[^>]*>' |
			sed -E 's/.*min="([0-9]+)".*max="([0-9]+)".*/{"legacy_min": \1, "legacy_max": \2, "legacy_filename": null, "new_id": null}/' |
			jq -s '.'
	)

	# Combine all JSON arrays and sort by_id, with 4-space indentation
	jq -n \
		--argjson id_arr "$json_by_id" \
		--argjson type_arr "$json_by_type" \
		--argjson range_arr "$json_by_range" '
      {
        "$schema": "./legacy_schema.json",
        "by_id": ($id_arr | sort_by(.legacy_id)),
        "by_type": $type_arr,
        "by_range": $range_arr
      }
    ' | jq '. | to_entries | sort_by(.key) | from_entries' >"$output_json"

	echo "Processed XML and saved to $output_json" >&2
	return 0
}

init "$@" && main

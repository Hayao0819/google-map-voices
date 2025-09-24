#!/usr/bin/env bash

set -eEuo pipefail
script_dir=$(cd "$(dirname "${0}")" && pwd)

messages_xml="${1-""}"
if [[ -z "$messages_xml" ]]; then
	echo "Usage: $0 <path to messages.xml>"
	exit 1
fi

output_json="${2-"${script_dir}/../../data/voices_template.json"}"

if ! which xmllint >/dev/null 2>&1; then
	echo "xmllint is required. Please install it."
	exit 1
fi
if ! which jq >/dev/null 2>&1; then
	echo "jq is required. Please install it."
	exit 1
fi

get_ids() {
	xmllint "$messages_xml" --xpath "/voice_instructions/canned_message/@id" | cut -d "=" -f 2 | tr -d "\""
}

get_filename_by_id() {
	local id="$1"
	xmllint "$messages_xml" --xpath "/voice_instructions/canned_message[@id='${id}']/text()"
}

json_line_template='{"filename": "%s", "id": %d, "text": ""}'
json_lines=()

while read -r id; do
	filename=$(get_filename_by_id "$id" | cut -d "." -f 1)
	#shellcheck disable=SC2059
	json_lines+=("$(printf "$json_line_template" "$filename" "$id")")
done < <(get_ids)

# Create the base instructions array
base_instructions=$(
	jq -n \
		--slurpfile lines <(printf "%s\n" "${json_lines[@]}") \
		'$lines'
)

# Generate the complete JSON structure according to voices_schema.json
json_output=$(
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
    }'
)

echo "$json_output" | jq '.' >"$output_json"

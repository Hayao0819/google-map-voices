#!/usr/bin/env bash

set -eEuo pipefail

output_dir="${1-""}"
if [[ -z "$output_dir" ]]; then
	echo "Usage: $0 <output directory>"
	exit 1
fi

script_dir=$(cd "$(dirname "${0}")" && pwd)
export GMV_CORE_DIR="${script_dir}/../core"

# shellcheck source=/dev/null
source "$GMV_CORE_DIR/voicevox.sh"
# shellcheck source=/dev/null
source "$GMV_CORE_DIR/kiritan.sh"

voices_json_path="$script_dir/../data/voices.json"

readarray -t voices < <(jq -c '.voices[]' "$voices_json_path")

for voice in "${voices[@]}"; do
	filename=$(echo "$voice" | jq -r '.filename')
	id=$(echo "$voice" | jq -r '.id')
	text=$(echo "$voice" | jq -r '.text')

	if [[ -z "$text" ]]; then
		echo "Skipping id $id (no text)"
		continue
	fi

	output_path="$output_dir/${filename}.wav"
	mkdir -p "$(dirname "$output_path")"

	echo "Generating id $id: $text"
	kiritan "$text" "$output_path"
done

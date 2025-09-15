#!/usr/bin/env bash

set -eEuo pipefail
script_dir=$(cd "$(dirname "${0}")" && pwd)
export GMV_CORE_DIR="${script_dir}/../core"
output_dir="${script_dir}/../output"
data_dir="${script_dir}/../data"

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM

voices=("kiritan" "ttchan")

{
	for voice in "${voices[@]}"; do
		mkdir -p "$temp_dir/voices-wav/$voice"
		"$script_dir/gen.sh" "$voice" "$temp_dir/voices-wav/$voice"

		mkdir -p "$temp_dir/voices-mp3/$voice"
		"$script_dir/convert_mp3.sh" "$temp_dir/voices-wav/$voice" "$temp_dir/voices-mp3/$voice"
	done
}

{
	for voice in "${voices[@]}"; do
		cp "$data_dir/messages.plist" "$temp_dir/voices-mp3/$voice"
		cp "$data_dir/messages.xml" "$temp_dir/voices-mp3/$voice"

		mkdir -p "$output_dir/$voice"
		(
			cd "$temp_dir/voices-mp3/$voice" || exit 1

			zip -r "$output_dir/$voice/voice_instructions_unitless.zip" ./*
		)
	done
}

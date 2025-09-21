#!/usr/bin/env bash

set -eEuo pipefail
script_dir=$(cd "$(dirname "${0}")" && pwd)
export GMV_CORE_DIR="${script_dir}/../core"
output_dir="${script_dir}/../output"
data_dir="${script_dir}/../data"
temp_dir=""

voices=()

init() {
	temp_dir=$(mktemp -d)
	trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM

	mkdir -p "$output_dir"

	local OPTARG OPTIND opt
	while getopts ":h" opt; do
		case $opt in
		h)
			echo "Usage: $0 [-h] voice1 [voice2 ... voiceN]"
			echo "  -h            Show this help message"
			echo "  voice1 ...    List of voice characters to generate audio for"
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

	if (($# == 0)); then
		echo "Generate all voices" >&2
		readarray -t voices < <(jq -r ".voices[] | .name" "$data_dir/voices.json")
	else
		voices=("$@")
		echo "Generate specified voices: ${voices[*]}" >&2
		for voice in "${voices[@]}"; do
			if ! jq -e -r ".voices[] | select(.name == \"$voice\")" "$data_dir/voices.json" >/dev/null; then
				echo "Error: Voice '$voice' not found in voices.json" >&2
				return 1
			fi
		done
	fi
}

# generate_audio <voice character>
generate_audio() {
	local _voice="$1"
	local _wav_dir="$temp_dir/$_voice/voices-wav/"
	mkdir -p "$_wav_dir"
	"$script_dir/gen.sh" "$_voice" "$_wav_dir"

	local _mp3_dir="$temp_dir/$_voice/voices"
	mkdir -p "$_mp3_dir"
	"$script_dir/convert_mp3.sh" "$_wav_dir" "$_mp3_dir"

	rm -rf "$_wav_dir"
}

generate_messages() {
	local _voice="$1"
	local _msg_dir="$data_dir/$_voice/messages"
	mkdir -p "$_msg_dir"
	cp "$data_dir/messages.xml" "$_msg_dir/messages.xml"
	cp "$data_dir/messages.plist" "$_msg_dir/messages.plist"
}

generate_instructions_zip() {
	local _voice="$1"
	local _zip_dir="$temp_dir/$_voice/archive"

	local _wav_dir="$temp_dir/$_voice/voices"
	local _msg_dir="$data_dir/$_voice/messages"
	mkdir -p "$_zip_dir"
	cp -r "$_wav_dir/"* "$_zip_dir"
	cp -r "$_msg_dir/"* "$_zip_dir"
	(
		cd "$_zip_dir" || exit 1
		zip -r "$output_dir/$_voice/voice_instructions.zip" ./*
	)
}

main() {
	for voice in "${voices[@]}"; do
		echo "Generating audio for voice: $voice" >&2
		generate_audio "$voice"
		echo "Generating messages for voice: $voice" >&2
		generate_messages "$voice"
		echo "Generating instructions zip for voice: $voice" >&2
		generate_instructions_zip "$voice"
	done
}

init "$@" && main

#!/usr/bin/env bash

set -eEuo pipefail

input_dir="${1-""}"
output_dir="${2-""}"

if [[ -z "$output_dir" ]] || [[ -z $input_dir ]]; then
	echo "Usage: $0 <input directory> <output directory>"
	exit 1
fi

mkdir -p "$output_dir"
if ! which ffmpeg >/dev/null 2>&1; then
	echo "ffmpeg is required. Please install it."
	exit 1
fi

shopt -s nullglob
wav_files=("$input_dir"/*.wav)
if [ ${#wav_files[@]} -eq 0 ]; then
	echo "No .wav files found in $input_dir"
	exit 0
fi
for wav_file in "${wav_files[@]}"; do
	filename=$(basename "$wav_file" .wav)
	output_file="$output_dir/${filename}.mp3"
	echo "Converting $wav_file to $output_file"
	ffmpeg -i "$wav_file" -vn -ac 2 -ar 44100 -ab 256k -acodec libmp3lame -f mp3 "$output_file" &
done
wait

#!/usr/bin/env bash

set -eEuo pipefail

script_dir=$(cd "$(dirname "${0}")" && pwd)
export GMV_CORE_DIR="${script_dir}/../core"

target_charactor=""
output_dir=""
voices_json_path="$script_dir/../data/voices.json"
voices=()
charactors=()

# shellcheck source=/dev/null
source "$GMV_CORE_DIR/voicevox.sh"

function init() {
	target_charactor="${1:-}"
	output_dir="${2:-}"
	if [[ -z "$output_dir" ]] || [[ -z "$target_charactor" ]]; then
		echo "Usage: $0 <voice> <output directory>" >&2
		return 1
	fi

	readarray -t voices < <(jq -c '.voices.base[]' "$voices_json_path")
	readarray -t charactors < <(jq -c '.charactors[]' "$voices_json_path")

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
	for _v in "${voices[@]}"; do
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

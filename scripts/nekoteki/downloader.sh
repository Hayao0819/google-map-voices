#!/usr/bin/env bash

set -eEuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
output_path="./data.zip"
target_id=""

init() {
	local opt OPTARG OPTIND
	while getopts ":ho:" opt; do
		case $opt in
		h)
			echo "Usage: $0 [-h] id"
			echo "  -h  Show this help message and exit"
			echo "  -o  Output path (default: ./data.zip)"
			exit 0
			;;
		o)
			output_path="$OPTARG"
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			return 1
			;;
		esac
	done
	shift $((OPTIND - 1))
	if [[ $# -ne 1 ]]; then
		echo "Error: Missing required argument 'id'" >&2
		# exit 1
		return 1
	fi
	if ! [[ "$1" =~ ^[0-9]+$ ]]; then
		echo "Invalid id: $1" >&2
		# exit 1
		return 1
	fi
	target_id="$1"
	return 0
}

call_list() {
	bash "$script_dir/list.sh" "$@"
}

main() {
	local _target_json
	_target_json=$(call_list -r -i "$target_id")

	local _archive_url
	_archive_url=$(jq -r '.[0].archive_url' <<<"$_target_json")

	if [[ -z "$_archive_url" || "$_archive_url" == "null" ]]; then
		echo "Error: No archive URL found for id $target_id" >&2
		return 1
	fi

	wget -O "$output_path" "$_archive_url"
	echo "Downloaded to $output_path" >&2
	return 0
}

init "$@" && main

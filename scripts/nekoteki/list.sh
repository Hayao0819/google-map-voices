#!/usr/bin/env bash

set -eEuo pipefail

raw_json=false
page=1 # number | "all"
ids=()

# Fetch and list voices from nekoteki.jp
# Usage: fetch_voices [page] [order]
#   page: Page number (default: 1)
#   order: Order by 'time' or 'name' (default: time)
#
# Type:
#   {
#     "id": int
#     "title": string
#     "rating": float
#     "description": string
#     "unit": string
#     "lang": "ja" | "en"
#     "author": string
#     "dlcount": int
#     "ini_url": string
#     "archive_url": string
#     "preview_url": string
#   }[]
fetch_voices() {
	local _page=${1-"1"} _order=${2-"time"}
	local script_dir
	script_dir=$(cd "$(dirname "${0}")" && pwd)

	"${script_dir}/../lib/fetch.sh" -s "http://nvc.nekoteki.jp/navi_voices.json?page=$_page&order=$_order"
}

calc_pages_count() {
	local _per_page=0 _latest_id=0 _first_page=""
	_first_page=$(fetch_voices 1 time)
	_per_page=$(jq 'length' <<<"$_first_page")
	_latest_id=$(jq '.[0].id' <<<"$_first_page")
	if [[ $_per_page -eq 0 ]]; then
		echo "No voices found." >&2
		return 1
	fi
	echo $((_latest_id / _per_page))
}

fetch_all_pages() {
	local _total_pages
	_total_pages=$(calc_pages_count)
	local _concatenated="[]"
	for ((i = 1; i <= _total_pages; i++)); do
		_concatenated=$(jq -s '.[0] + .[1]' <<<"$_concatenated $(fetch_voices $i time)")
	done
	echo "$_concatenated"
}

init() {
	local opt OPTARG OPTIND
	while getopts ":hrp:ai:" opt; do
		case $opt in
		a)
			page="all"
			;;
		p)
			if [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
				page="$OPTARG"
			else
				echo "Invalid page number: $OPTARG" >&2
				return 1
			fi
			;;
		r)
			raw_json=true
			;;
		i)
			if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
				echo "Invalid id: $OPTARG" >&2
				return 1
			fi
			ids+=("$OPTARG")
			;;
		h)
			echo "Usage: $0 [-r] [-p page| -a]" >&2
			echo "  -r: Output raw JSON" >&2
			echo "  -p: Page number to fetch (default: 1)" >&2
			echo "  -a: Fetch all pages" >&2
			# echo "  -i: Specify id"
			exit 0
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
		esac
	done
	shift $((OPTIND - 1))
}

print_voices_table() {
	{
		echo -e "ID\tタイトル\t言語\t作者\tDL数"
		jq -r '.[] | "\(.id)\t\(.title)\t\(.lang)\t\(.author)\t\(.dlcount)"' <<<"$1"
	} | column -t -s $'\t'
}

print_voices() {
	if [[ $raw_json == true ]]; then
		echo "$1"
	else
		print_voices_table "$1"
	fi
}

main() {
	if ((${#ids[@]} > 0)); then
		local _all_json
		_all_json=$(fetch_all_pages)
		local _filtered_json="[]"
		for id in "${ids[@]}"; do
			_filtered_json=$(jq -s '.[0] + [.[1][] | select(.id == '"$id"')]' <<<"$_filtered_json $_all_json")
		done
		print_voices "$_filtered_json"
		return 0
	fi

	local _fetched_json
	if [[ $page == "all" ]]; then
		_fetched_json=$(fetch_all_pages)
	else
		_fetched_json=$(fetch_voices "$page" time)
	fi

	print_voices "$_fetched_json"
}

init "$@" && main

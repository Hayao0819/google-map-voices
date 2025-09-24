#!/usr/bin/env bash
#
# fetch.sh - Universal download wrapper for curl and wget
#
# This script provides a unified interface for downloading files,
# automatically detecting and using either curl or wget.
#

set -eEuo pipefail

show_help() {
	cat <<EOF
Usage: $0 [OPTIONS] URL [OUTPUT_FILE]

Download files using curl or wget (automatically detected).

Arguments:
    URL         The URL to download from
    OUTPUT_FILE Optional output file path (defaults to stdout or URL basename)

Options:
    -o FILE     Output file path
    -s, --silent    Silent mode (suppress progress)
    -f, --fail      Fail silently on HTTP errors (curl-like behavior)
    -L, --location  Follow redirects
    -H HEADER   Add custom header (format: "Name: Value")
    -A AGENT    Set user agent string
    --timeout N Set timeout in seconds (default: 30)
    -h, --help  Show this help message

Examples:
    $0 https://example.com/file.zip
    $0 -o myfile.zip https://example.com/file.zip
    $0 -s -L https://example.com/api/data.json
    $0 -H "Accept: application/json" https://api.example.com/data
EOF
}

# Default values
output_file=""
silent=false
fail_on_error=false
follow_redirects=false
headers=()
user_agent=""
timeout=30
url=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-o)
		output_file="$2"
		shift 2
		;;
	-s | --silent)
		silent=true
		shift
		;;
	-f | --fail)
		fail_on_error=true
		shift
		;;
	-L | --location)
		follow_redirects=true
		shift
		;;
	-H)
		headers+=("$2")
		shift 2
		;;
	-A)
		user_agent="$2"
		shift 2
		;;
	--timeout)
		timeout="$2"
		shift 2
		;;
	-h | --help)
		show_help
		exit 0
		;;
	-*)
		echo "Error: Unknown option $1" >&2
		exit 1
		;;
	*)
		if [[ -z "$url" ]]; then
			url="$1"
		elif [[ -z "$output_file" ]]; then
			output_file="$1"
		else
			echo "Error: Too many arguments" >&2
			exit 1
		fi
		shift
		;;
	esac
done

# Validate required arguments
if [[ -z "$url" ]]; then
	echo "Error: URL is required" >&2
	show_help
	exit 1
fi

# Detect available tool
if command -v curl &>/dev/null; then
	tool="curl"
elif command -v wget &>/dev/null; then
	tool="wget"
else
	echo "Error: Neither curl nor wget is available" >&2
	exit 1
fi

# Build command based on available tool
case "$tool" in
curl)
	cmd=(curl)

	# Basic options
	if [[ "$silent" == true ]]; then
		cmd+=(-s)
	else
		cmd+=(-#) # Progress bar
	fi

	if [[ "$fail_on_error" == true ]]; then
		cmd+=(-f)
	fi

	if [[ "$follow_redirects" == true ]]; then
		cmd+=(-L)
	fi

	# Timeout
	cmd+=(--connect-timeout "$timeout")
	cmd+=(--max-time $((timeout * 2)))

	# Headers
	for header in "${headers[@]}"; do
		cmd+=(-H "$header")
	done

	# User agent
	if [[ -n "$user_agent" ]]; then
		cmd+=(-A "$user_agent")
	fi

	# Output
	if [[ -n "$output_file" ]]; then
		cmd+=(-o "$output_file")
	fi

	# URL
	cmd+=("$url")
	;;

wget)
	cmd=(wget)

	# Basic options
	if [[ "$silent" == true ]]; then
		cmd+=(-q)
	else
		cmd+=(--progress=bar)
	fi

	# wget doesn't have exact equivalent to curl's -f, but we can simulate
	if [[ "$fail_on_error" == true ]]; then
		cmd+=(--spider)
		# First check if URL exists
		if ! "${cmd[@]}" "$url" &>/dev/null; then
			exit 22 # HTTP error exit code like curl
		fi
		cmd=(wget) # Reset command for actual download
		if [[ "$silent" == true ]]; then
			cmd+=(-q)
		else
			cmd+=(--progress=bar)
		fi
	fi

	# Follow redirects (wget follows by default, but we can limit)
	if [[ "$follow_redirects" == true ]]; then
		cmd+=(--max-redirect=5)
	else
		cmd+=(--max-redirect=0)
	fi

	# Timeout
	cmd+=(--timeout="$timeout")
	cmd+=(--connect-timeout="$timeout")

	# Headers
	for header in "${headers[@]}"; do
		cmd+=(--header="$header")
	done

	# User agent
	if [[ -n "$user_agent" ]]; then
		cmd+=(--user-agent="$user_agent")
	fi

	# Output
	if [[ -n "$output_file" ]]; then
		cmd+=(-O "$output_file")
	else
		cmd+=(-O -) # Output to stdout
	fi

	# URL
	cmd+=("$url")
	;;
esac

# Execute the command
exec "${cmd[@]}"

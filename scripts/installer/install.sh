#!/usr/bin/env bash

set -eEuo pipefail

target_zip=""
actual_zip=""

binary_url="https://github.com/Hayao0819/google-map-voices/raw/refs/heads/master/binary/%NAME%/voice_instructions_unitless.zip"
google_map_voice_path="/storage/emulated/0/Android/data/com.google.android.apps.maps/testdata/voice"

function test_adb_shell() {
	which adb >/dev/null 2>&1 || {
		echo "adb is required. Please install it." >&2
		return 1
	}
	adb shell 'echo "adb is working"' >/dev/null 2>&1 || {
		echo "adb is not working. Please check your adb setup." >&2
		return 1
	}
}

function test_root() {
	adb shell 'su -c "echo 1"' >/dev/null 2>&1 || {
		echo "Root access is required. Please root your device and enable adb root access." >&2
		return 1
	}
}

function adb_shell_su() {
	adb shell "su -c \"$*\""
}

function adb_shell() {
	adb shell "$*"
}

function adb_mktempd() {
	adb_shell mktemp -d
}

function init() {
	test_adb_shell

	target_zip="${1-""}"
	if [[ -z "$target_zip" ]]; then
		echo "Usage: $0 <path or url to voice zip>" >&2
		return 1
	fi
}

function list_map_voices() {
	adb_shell_su "ls -1 $google_map_voice_path"
}

# gen_zip_url <name>
function gen_zip_url() {
	echo "${binary_url//%NAME%/$1}"
}

function load_zip() {

	if [[ "$target_zip" == "ttchan" ]] || [[ "$target_zip" == "kiritan" ]]; then
		target_zip="$(gen_zip_url "$target_zip")"
		echo "Using binary zip from $target_zip" >&2
	fi

	if [[ "$target_zip" == http*://* ]]; then
		local _tempdir
		_tempdir="$(mktemp -d)"
		actual_zip="$_tempdir/voice_instructions_unitless.zip"
		trap 'rm -rf "$_tempdir"' EXIT HUP INT TERM
		wget -O "$actual_zip" "$target_zip"
	else
		actual_zip="$target_zip"
	fi

	if [[ ! -e "$actual_zip" ]]; then
		echo "Error: zip file $actual_zip not found" >&2
		return 1
	fi
}

function stop_map() {
	adb shell am force-stop com.google.android.apps.maps
}

function push_zip() {
	local _tempdir=""
	_tempdir="$(adb_mktempd)"
	# shellcheck disable=SC2064
	trap "adb_shell_su rm -rf \"$_tempdir\" 2> /dev/null 1>&2" EXIT HUP INT TERM

	adb push "$actual_zip" "$_tempdir/voice_instructions_unitless.zip"

	local _ids=() _id _fullpath
	readarray -t _ids < <(list_map_voices)
	if [[ ${#_ids[@]} -eq 0 ]]; then
		echo "No voice ids found in $google_map_voice_path" >&2
		return 1
	fi
	printf 'Found %d voice ids\n' "${#_ids[@]}" >&2
	for _id in "${_ids[@]}"; do
		echo "Processing id: $_id" >&2
		{
			_fullpath="${google_map_voice_path}/${_id}"
			echo "Pushing to $_fullpath" >&2
			adb_shell_su "mkdir -p $_fullpath"
			adb_shell_su "cp $_tempdir/voice_instructions_unitless.zip $_fullpath/voice_instructions_unitless.zip"
		} || {
			echo "Failed to push to $_fullpath, trying ja subdir" >&2
		}
		{
			_fullpath_ja="${_fullpath}/ja"
			echo "Pushing to $_fullpath_ja" >&2
			adb_shell_su "mkdir -p $_fullpath_ja"
			adb_shell_su "cp $_tempdir/voice_instructions_unitless.zip $_fullpath_ja/voice_instructions_unitless.zip"
		} || {
			echo "Failed to push to $_fullpath_ja" >&2
		}
		echo "Done for id: $_id" >&2
	done
}

function main() {
	init "$@"
	load_zip
	test_root
	stop_map
	push_zip
}

main "$@"

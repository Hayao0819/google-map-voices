#!/usr/bin/env bash

set -eEuo pipefail
script_dir="$(cd "$(dirname "${0}")" || exit 1; pwd)"
source "$script_dir/voicevox.sh"

# kiritan text output
kiritan(){
	local text=${1:-"こんにちは"}
	local output=${2:-"$script_dir/kiritan.wav"}

	voicevox "$script_dir/voicevox_core/models/vvms/21.vvm"  --style-id 108  --text "${text}" --out "${output}"
}

kiritan "$@"

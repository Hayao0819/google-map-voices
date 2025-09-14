#!/usr/bin/env bash

GMV_CORE_DIR="${GMV_CORE_DIR-""}"

# ttchan text output
ttchan() {
	local text=${1:-"こんにちは"}
	local output=${2:-""}

	voicevox "$GMV_CORE_DIR/voicevox_core/models/vvms/11.vvm" --style-id 47 --text "${text}" --out "${output}"
}

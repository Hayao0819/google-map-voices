#!/usr/bin/env bash

GMV_CORE_DIR="${GMV_CORE_DIR-""}"

# kiritan text output
kiritan() {
	local text=${1:-"こんにちは"}
	local output=${2:-""}
	shift 2 || true

	voicevox "$GMV_CORE_DIR/voicevox_core/models/vvms/21.vvm" --style-id 108 --text "${text}" --out "${output}" "$@"
}

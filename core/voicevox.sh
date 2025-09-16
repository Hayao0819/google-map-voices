#!/usr/bin/env bash

set -eEuo pipefail

GMV_CORE_DIR="${GMV_CORE_DIR-""}"

find_onnxruntime() {
	find "$GMV_CORE_DIR/voicevox_core/onnxruntime/lib" -name "libvoicevox_onnxruntime.so.*" | sort -V | tail -n 1
}

find_dict() {
	find "$GMV_CORE_DIR/voicevox_core/dict" -type d -name "open_jtalk_dic_utf_8-*" | sort -V | tail -n 1
}

voicevox() {
	uv run "$GMV_CORE_DIR/voicevox.py" --onnxruntime "$(find_onnxruntime)" --dict-dir "$(find_dict)" "$@"
}

# voicevox_vvm vvm_id style_id text output [options...]
voicevox_vvm(){
	local vvm_id=${1:-"1"}
	local style_id=${2:-"0"}
	local text=${3:-"こんにちは"}
	local output=${4:-"~/output.wav"}
	shift 4 || true
	voicevox "$GMV_CORE_DIR/voicevox_core/models/vvms/${vvm_id}.vvm" --style-id "${style_id}" --text "${text}" --out "${output}" "$@"
}

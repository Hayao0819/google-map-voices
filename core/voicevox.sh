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
	uv run "$GMV_CORE_DIR/run.py" --onnxruntime "$(find_onnxruntime)" --dict-dir "$(find_dict)" "$@"
}

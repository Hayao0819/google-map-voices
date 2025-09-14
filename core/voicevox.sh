#!/usr/bin/env bash

set -eEuo pipefail
library_dir="$(cd "$(dirname "${0}")" || exit 1; pwd)"

runpy="$library_dir/run.py"
core_dir="$library_dir/voicevox_core"

find_onnxruntime() {
	find "$core_dir/onnxruntime/lib" -name "libvoicevox_onnxruntime.so.*" | sort -V | tail -n 1
}

find_dict() {
	find "$core_dir/dict" -type d -name "open_jtalk_dic_utf_8-*" | sort -V | tail -n 1
}

voicevox(){
	uv run "$runpy" --onnxruntime "$(find_onnxruntime)" --dict-dir "$(find_dict)" "$@"
}


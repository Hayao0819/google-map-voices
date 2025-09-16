#!/usr/bin/env bash

GMV_CORE_DIR="${GMV_CORE_DIR-""}"

# ttchan text output [options...]
ttchan() {
	# ナースロボ＿タイプＴ ノーマル
	voicevox_vvm 11 47 "$@"
}

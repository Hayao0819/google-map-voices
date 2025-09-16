#!/usr/bin/env bash

GMV_CORE_DIR="${GMV_CORE_DIR-""}"

# kiritan text output
kiritan() {
	# 東北きりたん ノーマル
	voicevox_vvm 21 108 "$@"
}

#!/usr/bin/env bash

GMV_CORE_DIR="${GMV_CORE_DIR-""}"

zundamon() {
	# ずんだもん ノーマル
	voicevox_vvm 0 3 "$@"
}

zundamon_sexy() {
	# ずんだもん セクシー
	voicevox_vvm 0 5 "$@"
}

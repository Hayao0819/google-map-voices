#!/usr/bin/env bash

set -eEuo pipefail

binary=download-linux-x64
temp_dir="$(mktemp -d)"
script_dir=$(cd "$(dirname "${0}")" && pwd)

cd "$temp_dir" || exit 1

"${script_dir}/../lib/fetch.sh" -s -f -L -o download "https://github.com/VOICEVOX/voicevox_core/releases/latest/download/${binary}"
chmod +x download
./download -o "${script_dir}/../../core/voicevox_core" --exclude "c-api"

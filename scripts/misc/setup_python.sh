#!/usr/bin/env bash

set -eEuo pipefail

script_dir=$(cd "$(dirname "${0}")" && pwd)
project_root=$(cd "$script_dir/../.." && pwd)

cd "$project_root"

if ! command -v uv &>/dev/null; then
	echo "Error: 'uv' is not installed." >&2
	echo "Please install uv first: https://docs.astral.sh/uv/getting-started/installation/" >&2
	exit 1
fi

uv python install
uv sync
uv add --dev jsonschema

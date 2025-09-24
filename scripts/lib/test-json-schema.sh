#!/usr/bin/env bash

set -eEuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Execute test-json-schema.py using uv
exec uv run --with jsonschema "$script_dir/test-json-schema.py" "$@"
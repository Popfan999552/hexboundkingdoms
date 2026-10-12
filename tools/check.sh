#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/logs
run() {
  local check_name="$1"; shift
  if [[ "$check_name" == import ]]; then
    ./tools/godot.sh "$@" 2>&1 | tee "build/logs/$check_name.log"
  else
    # Tests must never overwrite a developer's local kingdom/settings.
    XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.hexbound/data}/test-runs/$check_name" ./tools/godot.sh "$@" 2>&1 | tee "build/logs/$check_name.log"
  fi
  if python3 tools/log_contains.py '^(SCRIPT ERROR|ERROR):' "build/logs/$check_name.log"; then
    echo "Godot reported an error during $check_name" >&2; return 1
  fi
}
run import --headless --path . --editor --import --quit
run rules --headless --path . --script tests/test_game.gd
run ui --headless --path . --script tests/test_ui.gd
run smoke --headless --path . -- --smoke

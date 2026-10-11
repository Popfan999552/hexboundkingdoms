#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/logs
run() {
  local check_name="$1"; shift
  ./tools/godot.sh "$@" 2>&1 | tee "build/logs/$check_name.log"
  if rg -q '^(SCRIPT ERROR|ERROR):' "build/logs/$check_name.log"; then
    echo "Godot reported an error during $check_name" >&2; return 1
  fi
}
run import --headless --path . --editor --import --quit
run rules --headless --path . --script tests/test_game.gd
run ui --headless --path . --script tests/test_ui.gd
run smoke --headless --path . -- --smoke

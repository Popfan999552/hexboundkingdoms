#!/usr/bin/env bash
set -euo pipefail
export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.hexbound/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.hexbound/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.hexbound/cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
exec godot "$@"

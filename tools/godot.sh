#!/bin/sh
set -e
project_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
if [ -n "$GODOT_BIN" ]; then exec "$GODOT_BIN" "$@"; fi
if [ -x "$project_dir/.tools/Godot.app/Contents/MacOS/Godot" ]; then exec "$project_dir/.tools/Godot.app/Contents/MacOS/Godot" "$@"; fi
if [ -x "$project_dir/../never-sunset-godot/.tools/Godot.app/Contents/MacOS/Godot" ]; then exec "$project_dir/../never-sunset-godot/.tools/Godot.app/Contents/MacOS/Godot" "$@"; fi
if command -v godot >/dev/null 2>&1; then exec godot "$@"; fi
echo "Godot 4.7.2 not found. Set GODOT_BIN to the engine executable." >&2
exit 127

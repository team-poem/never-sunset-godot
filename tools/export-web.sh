#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$project_dir"
mkdir -p build/web artifacts
touch build/.gdignore
tools/godot.sh --headless --path . --log-file artifacts/import.log --editor --import --quit
tools/godot.sh --headless --path . --log-file artifacts/export.log --export-release Web build/web/index.html
tools/godot.sh --headless --path . --log-file artifacts/licenses.log --script res://tools/export-licenses.gd
cp ASSET_SOURCES.md build/web/ASSET_SOURCES.md
python3 -c 'from pathlib import Path; import shutil; [p.unlink() for p in Path("build/web").glob("*.import")]; shutil.make_archive("build/never-sunset-web", "zip", "build/web")'
printf 'Web build ready: %s/build/web\n' "$project_dir"

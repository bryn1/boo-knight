#!/usr/bin/env bash
# Boo Knight asset sync: godot/assets is a symlink to ../assets so the exact
# docs/SPRITES.md paths resolve as res://assets/sprites/<file>.png. Re-create
# the link if missing and (re)import PNGs the art pass added. Never edits
# assets/ — it only links and imports.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-/home/claudecode/Games/.tools/godot/Godot_v4.7.2-stable_linux.x86_64}"

if [ ! -e "$ROOT/godot/assets/sprites" ]; then
	ln -sfn ../assets "$ROOT/godot/assets"
	echo "linked godot/assets -> ../assets"
fi

if [ -x "$GODOT" ]; then
	"$GODOT" --headless --path "$ROOT/godot" --import 2>/dev/null \
		|| echo "note: --import reported issues (fine while assets/sprites is empty; code falls back to placeholders)"
else
	echo "note: godot binary not found at $GODOT (set GODOT_BIN) — skipped import"
fi

#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$SKILL_DIR/sources" "$SKILL_DIR/reports" "$SKILL_DIR/temp"

if ls "$SKILL_DIR/sources/"*.md >/dev/null 2>&1; then
  echo "=== Source files found ==="
  for f in $(ls "$SKILL_DIR/sources/"*.md | sort); do
    basename "$f" | sed 's/\.md$//'
  done
else
  echo "NO_SOURCES_FOUND"
  realpath "$SKILL_DIR/sources/"
fi

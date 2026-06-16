#!/usr/bin/env bash
set -euo pipefail

SOURCE_FILENAME="$1"
NUM_AGENTS="$2"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

SOURCE_FILE="$SKILL_DIR/sources/$SOURCE_FILENAME"
SOURCE_FILENAME_WITHOUT_EXT="${SOURCE_FILENAME%.md}"
TEMP_DIR="$SKILL_DIR/temp/$SOURCE_FILENAME_WITHOUT_EXT"

mkdir -p "$TEMP_DIR"
for i in $(seq 1 "$NUM_AGENTS"); do
  cp "$SOURCE_FILE" "$TEMP_DIR/agent-$i.md"
done
ls -la "$TEMP_DIR"

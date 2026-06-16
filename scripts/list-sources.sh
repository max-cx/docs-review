#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

for f in $(ls "$SKILL_DIR/sources/"*.md | sort); do
  echo "$f: $(wc -l < "$f") lines"
done

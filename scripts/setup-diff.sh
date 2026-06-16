#!/usr/bin/env bash
set -euo pipefail

REPO_PATH="$1"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$SKILL_DIR/temp"

cd "$REPO_PATH"
git log -1 --format="%H %s"
git diff HEAD~1..HEAD > "$SKILL_DIR/temp/commit-diff.txt"
wc -l "$SKILL_DIR/temp/commit-diff.txt"

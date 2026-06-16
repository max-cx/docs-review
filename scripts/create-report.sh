#!/usr/bin/env bash
set -euo pipefail

USER_REQUEST="$1"
COMMIT_HASH="$2"
COMMIT_SUBJECT="$3"

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPORT_DIR="$SKILL_DIR/reports"
mkdir -p "$REPORT_DIR"

REPORT_FILE="$REPORT_DIR/review-$(date +%Y-%m-%d-%H:%M:%S).md"

cat > "$REPORT_FILE" <<EOF
AI review report
(Do not use preview to read this report unless your previews are set to a monospace font.)

**User request:** $USER_REQUEST

**Commit:** $COMMIT_HASH
**Subject:** $COMMIT_SUBJECT
EOF

echo "$REPORT_FILE"

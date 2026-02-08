#!/usr/bin/env bash
# Module 2: Lean Loader
# Splits large workspace files into lean version + docs/ extracts.
# Usage: ./module-2-lean-loader.sh <file> [--apply]
# Default: --dry-run (shows what would change, modifies nothing)
# Scope: ONLY workspace files (AGENTS.md, SOUL.md, etc.) — never repo/taskboard/shared

set -euo pipefail

FILE="${1:-}"
MODE="${2:---dry-run}"
THRESHOLD=3000  # bytes — files above this are candidates

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Usage: $0 <workspace-file.md> [--dry-run|--apply]"
  echo "  --dry-run (default): show analysis, change nothing"
  echo "  --apply: create lean version + docs/ extracts"
  exit 1
fi

BASENAME=$(basename "$FILE")
DIR=$(dirname "$FILE")
SIZE=$(wc -c < "$FILE" | tr -d ' ')
LINES=$(wc -l < "$FILE" | tr -d ' ')

echo "# Lean Loader Analysis"
echo ""
echo "**File:** \`${BASENAME}\`"
echo "**Size:** ${SIZE} bytes (${LINES} lines)"
echo "**Mode:** ${MODE}"
echo ""

if [ "$SIZE" -lt "$THRESHOLD" ]; then
  echo "✅ File is already lean (< ${THRESHOLD}B). No action needed."
  exit 0
fi

# Count H2 sections
echo "## Sections found"
echo ""
grep -n "^## " "$FILE" | while IFS= read -r line; do
  echo "- ${line}"
done

echo ""
echo "## Recommendation"
echo ""
echo "Split into:"
echo "- \`${BASENAME}\` (lean) — keep first 30-40 lines + section summaries"
echo "- \`docs/agent/\` — move detailed rules per section"
echo ""

if [ "$MODE" = "--apply" ]; then
  echo "⚠️ --apply mode: Auto-splitting not implemented yet."
  echo "Use module-1 audit output + manual editing for now."
  echo "Future: will auto-extract H2 sections > 500B to docs/"
else
  echo "ℹ️ Dry-run mode. Use --apply to execute changes."
fi

#!/usr/bin/env bash
# Module 4: Handoff Generator
# Creates HANDOFF.md with session state for continuity across rotations.
# Usage: ./module-4-handoff.sh [workspace_path] [--apply]
# Default: --dry-run (shows template, writes nothing)

set -euo pipefail

WORKSPACE="${1:-.}"
MODE="${2:---dry-run}"
HANDOFF_DIR="${WORKSPACE}/shared/handoff"
HANDOFF_FILE="${HANDOFF_DIR}/latest.md"
TIMESTAMP=$(date -Iseconds)
DATE=$(date +%Y-%m-%d)

generate_handoff() {
  cat << TEMPLATE
# Session Handoff

**Generated:** ${TIMESTAMP}
**Agent:** $(whoami)@$(hostname)

## Context
_What was this session about? (Fill in before closing session)_

- Active task:
- Phase:
- Key files touched:

## Done (this session)
_What was accomplished?_

-

## Next Steps
_What should the next session do first?_

1.

## Blockers
_Anything preventing progress?_

- None

## Key Decisions
_Important choices made this session that future sessions need to know._

-

## Links
- Taskboard: \`shared/state/taskboard.tasks.json\`
- Daily notes: \`memory/${DATE}.md\`
TEMPLATE
}

echo "# Handoff Generator"
echo ""
echo "**Workspace:** \`${WORKSPACE}\`"
echo "**Mode:** ${MODE}"
echo ""

if [ "$MODE" = "--apply" ]; then
  mkdir -p "$HANDOFF_DIR"
  generate_handoff > "$HANDOFF_FILE"
  echo "✅ Created: \`${HANDOFF_FILE}\`"
  echo ""
  echo "Edit this file before closing your session!"
else
  echo "## Preview (dry-run)"
  echo ""
  generate_handoff
  echo ""
  echo "---"
  echo "ℹ️ Use --apply to write to \`${HANDOFF_FILE}\`"
fi

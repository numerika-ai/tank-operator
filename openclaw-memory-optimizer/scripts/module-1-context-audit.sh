#!/usr/bin/env bash
# Module 1: Context Audit
# Scans OpenClaw workspace and reports file sizes loaded at session start.
# Usage: ./module-1-context-audit.sh [workspace_path]
# Default: current directory

set -euo pipefail

WORKSPACE="${1:-.}"
REPORT=""
TOTAL=0
WARN_THRESHOLD=3000  # bytes — files above this get flagged

# Files typically loaded at session start (OpenClaw convention)
BOOT_FILES=(
  "SOUL.md"
  "IDENTITY.md"
  "USER.md"
  "AGENTS.md"
  "TOOLS.md"
  "HEARTBEAT.md"
  "MEMORY.md"
  "BOOTSTRAP.md"
)

echo "# Context Audit Report"
echo ""
echo "**Workspace:** \`${WORKSPACE}\`"
echo "**Date:** $(date -Iseconds)"
echo ""
echo "## Boot Files (loaded at session start)"
echo ""
echo "| File | Size (bytes) | Status |"
echo "|------|-------------|--------|"

for f in "${BOOT_FILES[@]}"; do
  filepath="${WORKSPACE}/${f}"
  if [ -f "$filepath" ]; then
    size=$(wc -c < "$filepath" | tr -d ' ')
    TOTAL=$((TOTAL + size))
    if [ "$size" -gt "$WARN_THRESHOLD" ]; then
      status="⚠️ LARGE — consider splitting"
    elif [ "$size" -eq 0 ]; then
      status="✅ Empty (no cost)"
    else
      status="✅ OK"
    fi
    echo "| ${f} | ${size} | ${status} |"
  else
    echo "| ${f} | — | ⬜ Not found |"
  fi
done

echo ""
echo "**Total boot files:** ${TOTAL} bytes (~$((TOTAL / 4)) tokens est.)"
echo ""

# Check memory/ directory
MEMORY_DIR="${WORKSPACE}/memory"
if [ -d "$MEMORY_DIR" ]; then
  echo "## Daily Memory Files"
  echo ""
  today=$(date +%Y-%m-%d)
  yesterday=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d 2>/dev/null || echo "unknown")
  
  mem_count=$(find "$MEMORY_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
  mem_total=$(find "$MEMORY_DIR" -name "*.md" -type f -exec cat {} + 2>/dev/null | wc -c | tr -d ' ')
  
  echo "- Total daily files: ${mem_count}"
  echo "- Total size: ${mem_total} bytes"
  
  if [ -f "${MEMORY_DIR}/${today}.md" ]; then
    today_size=$(wc -c < "${MEMORY_DIR}/${today}.md" | tr -d ' ')
    echo "- Today (${today}): ${today_size} bytes"
    TOTAL=$((TOTAL + today_size))
  fi
  
  if [ -f "${MEMORY_DIR}/${yesterday}.md" ] 2>/dev/null; then
    yest_size=$(wc -c < "${MEMORY_DIR}/${yesterday}.md" | tr -d ' ')
    echo "- Yesterday (${yesterday}): ${yest_size} bytes"
    TOTAL=$((TOTAL + yest_size))
  fi
  echo ""
fi

# Check docs/ (should NOT be loaded at boot)
DOCS_DIR="${WORKSPACE}/docs"
if [ -d "$DOCS_DIR" ]; then
  docs_count=$(find "$DOCS_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
  docs_total=$(find "$DOCS_DIR" -name "*.md" -type f -exec cat {} + 2>/dev/null | wc -c | tr -d ' ')
  echo "## On-Demand Files (docs/)"
  echo ""
  echo "- Files: ${docs_count}"
  echo "- Total size: ${docs_total} bytes (NOT loaded at boot ✅)"
  echo ""
fi

# Summary
echo "## Summary"
echo ""
echo "- **Total context at boot:** ${TOTAL} bytes (~$((TOTAL / 4)) tokens est.)"
echo ""

if [ "$TOTAL" -gt 20000 ]; then
  echo "🔴 **CRITICAL:** Boot context > 20KB. Aggressive optimization needed."
elif [ "$TOTAL" -gt 10000 ]; then
  echo "🟡 **WARNING:** Boot context > 10KB. Consider splitting large files."
elif [ "$TOTAL" -gt 5000 ]; then
  echo "🟢 **GOOD:** Boot context < 10KB. Minor optimizations possible."
else
  echo "✅ **EXCELLENT:** Boot context < 5KB. Well optimized."
fi

echo ""
echo "## Recommendations"
echo ""

# Find largest boot file
largest=""
largest_size=0
for f in "${BOOT_FILES[@]}"; do
  filepath="${WORKSPACE}/${f}"
  if [ -f "$filepath" ]; then
    size=$(wc -c < "$filepath" | tr -d ' ')
    if [ "$size" -gt "$largest_size" ]; then
      largest="$f"
      largest_size="$size"
    fi
  fi
done

if [ "$largest_size" -gt "$WARN_THRESHOLD" ]; then
  echo "1. **Split \`${largest}\`** (${largest_size}B) — extract detailed rules to docs/"
fi

echo "2. Keep HEARTBEAT.md empty unless you have periodic tasks"
echo "3. Use MEMORY.md only in main session (never in groups)"
echo "4. Load docs/ files on-demand, not at boot"

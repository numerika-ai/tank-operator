---
name: openclaw-memory-optimizer
description: "Optimize OpenClaw memory and token usage. Use when auditing workspace context size, splitting large files, routing skills dynamically, generating session handoffs, or managing memory tiers (hot/warm/cold). Covers: context audit, lean loading, skill routing, handoff generation, memory tiering."
---

# OpenClaw Memory Optimizer

5 independent modules to reduce token waste and improve session continuity.

## Quick Start

### Audit your workspace
```bash
scripts/module-1-context-audit.sh /path/to/workspace
```

### Check if a file needs splitting
```bash
scripts/module-2-lean-loader.sh AGENTS.md          # dry-run
scripts/module-2-lean-loader.sh AGENTS.md --apply   # execute
```

### Route skills (find relevant ones for a query)
```bash
python3 scripts/module-3-skill-router.py "deploy to production" skills.json
```

### Generate session handoff
```bash
scripts/module-4-handoff.sh /path/to/workspace          # dry-run
scripts/module-4-handoff.sh /path/to/workspace --apply   # write file
```

### Classify memory tiers
```bash
python3 scripts/module-5-memory-tier.py /path/to/memory/
```

## Modules

| # | Module | What it does | Dependencies |
|---|--------|-------------|-------------|
| 1 | Context Audit | Scans workspace, reports sizes | bash |
| 2 | Lean Loader | Splits large files (dry-run default) | bash |
| 3 | Skill Router | Keyword-matches relevant skills | python3 stdlib |
| 4 | Handoff Generator | Creates HANDOFF.md for session rotation | bash |
| 5 | Memory Tier Manager | Scores memory entries hot/warm/cold | python3 stdlib |

## Safety Rules
- All modules default to `--dry-run` — no changes without `--apply`
- Lean Loader scope: ONLY workspace files (never repo/taskboard/shared)
- Module inputs are explicit (files/paths), no implicit state

## Templates
- `assets/templates/HANDOFF.template.md` — handoff format
- `assets/templates/AGENTS-LEAN.template.md` — optimized AGENTS.md example

## Architecture
See `references/architecture.md` for design details and `references/testing-guide.md` for per-module testing.

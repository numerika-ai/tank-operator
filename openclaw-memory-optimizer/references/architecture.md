# Architecture: openclaw-memory-optimizer

## Design Principles
1. **Modular** — each module is standalone, zero inter-module dependencies
2. **Safe by default** — all modifications require `--apply` flag
3. **No LLM** — all analysis uses heuristics/keyword matching
4. **Stdlib only** — Python modules use no external packages
5. **Workspace only** — never touches repo/taskboard/shared state

## Module Dependencies

```
Module 1 (Audit)     → bash only, reads files
Module 2 (Lean)      → bash only, reads/writes workspace files
Module 3 (Router)    → python3 stdlib, reads skill metadata
Module 4 (Handoff)   → bash only, writes handoff file
Module 5 (Tiers)     → python3 stdlib, reads memory files
```

## Data Flow

```
Workspace files → Module 1 (Audit) → Report
                → Module 2 (Lean)  → Optimized files + docs/
Skills dir      → Module 3 (Router) → Ranked skill list
Session state   → Module 4 (Handoff) → HANDOFF.md
Memory dir      → Module 5 (Tiers)  → Tier classification
```

## Integration with OpenClaw
- Skill is loaded on-demand when user asks about memory/token optimization
- Scripts can be run standalone or through agent tool calls
- Templates provide starting points for workspace restructuring

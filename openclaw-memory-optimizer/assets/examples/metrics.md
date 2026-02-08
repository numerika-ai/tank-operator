# Optimization Metrics

## Token Usage Benchmarks

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Static context (boot) | ~2800 tokens | ~1200 tokens | −57% |
| AGENTS.md alone | ~2000 tokens | ~400 tokens | −80% |
| First-turn headroom (200K cap) | 197.2K | 198.8K | +1.6K |

## Module Performance (from Tank's sanity check)

| Module | Status | Notes |
|--------|--------|-------|
| 1 — Audit | ✅ | Generates report correctly |
| 2 — Lean Loader | ✅ | Dry-run safe, no file damage |
| 3 — Skill Router | ✅ | Correctly routes "weather" → weather skill |
| 4 — Handoff | ✅ | `--apply` creates handoff file |
| 5 — Memory Tiering | ✅ | HOT/WARM/COLD classification works |

## Session Cost Estimate
- ~1600 fewer tokens per session start
- At ~$15/M tokens (Opus): ~$0.024 saved per session
- Over 100 sessions/day: ~$2.40/day

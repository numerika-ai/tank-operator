# Before / After — Memory Optimization Examples

## Example 1: AGENTS.md (Wiki workspace)

### Before (7.8KB)
- All rules inline: group chat, heartbeat, bot-to-bot protocol
- Loaded every session regardless of context
- ~2000 tokens per boot

### After (1.5KB)
- Core rules only (safety, memory, tools)
- Detailed rules in `docs/agent/` loaded on-demand
- ~400 tokens per boot
- **Reduction: 81%**

## Example 2: Total Static Context

| File | Before | After |
|------|--------|-------|
| SOUL.md | 1.7KB | 1.7KB (unchanged) |
| IDENTITY.md | 0.3KB | 0.3KB (unchanged) |
| USER.md | 0.3KB | 0.3KB (unchanged) |
| AGENTS.md | 7.8KB | 1.5KB |
| TOOLS.md | 0.9KB | 0.9KB (unchanged) |
| HEARTBEAT.md | 0.2KB | 0.2KB (unchanged) |
| **Total** | **11.2KB** | **4.8KB (−57%)** |

## Key Takeaway
Move detailed/conditional rules to on-demand files. Keep boot context minimal.

# Testing Guide: openclaw-memory-optimizer

## Per-Module Tests

### Module 1: Context Audit
```bash
./scripts/module-1-context-audit.sh /path/to/workspace
# Expected: markdown report with file sizes, total, recommendations
# Pass: report generates without errors, total matches manual wc -c
```

### Module 2: Lean Loader
```bash
# Dry-run (default)
./scripts/module-2-lean-loader.sh /path/to/AGENTS.md
# Expected: analysis report, no file changes

# Apply (careful!)
./scripts/module-2-lean-loader.sh /path/to/AGENTS.md --apply
# Expected: split files created
```

### Module 3: Skill Router
```bash
# With skills.json
python3 scripts/module-3-skill-router.py "deploy to github" skills.json
# Expected: github skill ranked #1

# With --scan
python3 scripts/module-3-skill-router.py --scan /path/to/skills "weather forecast"
# Expected: weather skill ranked #1

# Test cases:
# "git push" → github
# "weather today" → weather
# "transcribe audio" → openai-whisper-api
# "check server security" → healthcheck
```

### Module 4: Handoff Generator
```bash
# Dry-run
./scripts/module-4-handoff.sh /path/to/workspace
# Expected: template preview, no files written

# Apply
./scripts/module-4-handoff.sh /path/to/workspace --apply
# Expected: shared/handoff/latest.md created
```

### Module 5: Memory Tier Manager
```bash
python3 scripts/module-5-memory-tier.py /path/to/memory/
# Note: scans workspace/memory/ directory automatically
# Expected: tier report (HOT/WARM/COLD), recommendations
# Pass: today's notes = HOT, >7 days = COLD
```

## Integration Test
1. Run Module 1 → note baseline
2. Run Module 2 on largest file → verify reduction
3. Run Module 1 again → confirm improvement
4. Run Module 5 → verify tier assignments
5. Run Module 4 → verify handoff template

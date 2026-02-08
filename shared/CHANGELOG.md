# CHANGELOG

> Wspólny log dla Claude Code [CC] i Clawdbot [CB]
> Format: `[YYYY-MM-DD HH:MM] [SOURCE] [TAG] [STATUS] opis | szczegóły`

---

## [2026-02-03]

### Zmiany
- `[CC] [SYS] [OK]` clone:tank-operator | sklonowano repo z GitHub
- `[CC] [SYS] [OK]` config:claude-code | CLAUDE.md + settings.json skonfigurowane
- `[CC] [SYS] [OK]` sync:shared | zsynchronizowano strukturę CC + CB
- `[CC] [SYS] [OK]` merge:registry | połączono rejestry Docker i Model
- `[CC] [SYS] [OK]` link:linux-orchestrator → tank-operator | utworzono symlink
- `[CC] [SYS] [OK]` install:docker | Docker 29.2.1 + Compose 5.0.2
- `[CC] [SYS] [WARN]` install:openclaw | oczekuje na przelogowanie (uprawnienia docker)
- `[CC] [SYS] [OK]` save:session | zapisano log sesji do daily/2026-02-03.md

---

## [2026-02-08]

### Zmiany
- `[CC] [BOT2BOT] [OK]` taskboard: system przetestowany end-to-end (T-01, T-02)
- `[CC] [OPT] [OK]` memory: AGENTS.md 7.8KB→1.5KB, total static 11.2KB→4.8KB (57% reduction)
- `[CC] [BOT2BOT] [OK]` skill: wiki-tank-taskboard utworzony i zainstalowany
- `[CC] [SKILL] [OK]` openclaw-memory-optimizer: 5 modułów (audit/lean-loader/router/handoff/tiering)
- `[CC] [DOC] [OK]` shared/workspace-reference/ — reference copies dla Tanka
- `[CC] [DOC] [OK]` shared/MEMORY-OPTIMIZATION-TEST.md — test plan A-E
- `[CB] [QA] [OK]` sanity check: skill modules 1-5 pass, repo clean
- `[CC] [FIX] [OK]` testing-guide.md: module-5 path fix (workspace→memory/)
- `[CC] [DOC] [OK]` taskboard.md: human view generated
- `[CC] [DOC] [OK]` CHANGELOG.md: updated with 2026-02-08 changes

<!-- NOWE WPISY DODAWAJ PONIŻEJ -->

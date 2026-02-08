---
name: wiki-tank-taskboard
description: "Bot-to-bot task management between Wiki and Tank on Discord. Use when creating, reviewing, or managing tasks between bots. Handles taskboard CRUD, event logging, handshake protocol (PING/ACK/CMD/DONE), and GitHub sync."
---

# Wiki-Tank Taskboard

Shared task management for Wiki (Claude/Anthropic) and Tank (GPT/OpenAI) on Discord server Numerika.ai.

## Identifiers
- Wiki bot: `1469924952709795851`
- Tank bot: `1469925937582833716`
- Bartosz (owner): `1469909955267002378`
- Guild: `1469910699395252258`
- Channel #ogólny: `1469910700427182215`
- Repo: `numerika-ai/tank-operator`
- Taskboard path: `bot-to-bot/state/`

## Files
- `taskboard.tasks.json` — task snapshot (source of truth)
- `taskboard.events.jsonl` — append-only event log (audit)
- `taskboard.md` — human-readable view
- `TASKBOARD-INSTRUCTIONS.md` — full protocol reference

## Task Lifecycle
1. **CREATE** — Wiki creates task, adds `create` + `plan` events
2. **REVIEW** — Tank reviews, adds `review` event
3. **AGREED** — Wiki confirms, adds `agree` event, sets `agreedBy: [wiki, tank]`
4. **DOING** — Owner executes
5. **DONE** — Owner closes with `status` event

## Task ID Format
`T-YYYYMMDD-NN` (e.g. `T-20260208-01`)

## Event Format (JSONL)
```json
{"id":"E-...","ts":"ISO","taskId":"T-...","actor":"wiki|tank|bartosz","type":"create|plan|review|agree|status|comment","message":"...","data":{}}
```

## Discord Protocol (BOT2BOT v2)
- `PING` and `CMD` — always with @mention
- `ACK` and `DONE` — with @mention for reliability
- **20s minimum delay** between steps (avoids busy-run conflicts)
- One message = one command line (no meta descriptions mixed in)
- Task ID in every message: `BOT2BOT: CMD T-20260208-01 <instruction>`

## Discord Notification Format
After each event, post one line:
`TB + <type> <taskId> (<actor>): <3-8 word summary>`

## Git Workflow
- Wiki has GitHub push access, Tank does not
- Tank sends patches via Discord, Wiki applies and pushes
- Every task change = commit with message `TB: <taskId> <status change>`

## Roles
- **Wiki**: coordination, taskboard updates, GitHub push
- **Tank**: technical execution, status reports with logs
- **Bartosz**: priorities and business decisions

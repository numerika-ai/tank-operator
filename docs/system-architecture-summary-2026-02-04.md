# Tank Operator — system architecture summary (host + VMs/workers)

Date: 2026-02-04 (Europe/Warsaw)

This document summarizes the current state and decisions for the **Tank/OpenClaw** setup and the planned **orchestrator + workers** architecture (Proxmox/VM target), plus the current local RAG + Telegram voice workflow.

> NOTE: This doc intentionally **does not include secrets** (API keys, tokens, etc.).

---

## 1) Current running system (single host)

### OpenClaw
- OpenClaw Gateway runs locally, **loopback-bound** (control UI local-only).
- Primary chat channel: **Telegram** (DM allowlist).
- Shared-first operations and auditing: everything logged under `workspace/shared/`.

### Local semantic memory (RAG)
- Memory sources:
  - `workspace/MEMORY.md`
  - `workspace/memory/*.md`
- Index DB: `~/.openclaw/memory/main.sqlite`
- Embeddings computed **locally** via TEI (GPU):
  - TEI endpoint: `http://127.0.0.1:8080/v1/embeddings`
  - Model: `intfloat/multilingual-e5-small`
- Fix applied for TEI 512-token constraint:
  - chunking: `tokens=350`, `overlap=50`

### Audio workflow
- Inbound voice notes → local ASR (Docker):
  - `openclaw-asr` bound to `127.0.0.1:9000`
  - Wrapper: `workspace/shared/asr-whisper.sh`
- Outbound voice: currently **manual two-send policy**
  - For user voice note: send **text message** + send **separate voice note**.
  - Auto-TTS is disabled to avoid single-payload behavior.
- Local TTS direction:
  - Piper models under `~/.openclaw/piper-data/`.
  - WAV→Opus conversion validated via ffmpeg container (no host ffmpeg install).

### Model providers
- Default model remains **`openai-codex/gpt-5.2`**.
- Additional provider configured:
  - `sonusflow/chatgpt-oss-120b` with alias **"2xSpark"**.
- Note: key-level access restrictions were observed (attempting the wrong model returns 401).

---

## 2) Shared-first logging and audit trail

Adopted conventions:
- Operational artifacts live in `workspace/shared/`:
  - `shared/CHANGELOG.md` — primary audit log
  - `shared/logs/docker-changes/` — docker changes
  - `shared/logs/errors/ERROR-LOG.md` — incidents
  - `shared/reports/` — written reports and checklists
- Every system/config change should be logged via `shared/log.sh`.
- BOOT checklist requires logging `gateway:start` after restarts.

---

## 3) Security stance (what we’re optimizing for)

High-level posture:
- **Local-first, LAN-first** by default.
- Avoid exposing admin surfaces publicly (no public RDP/VNC/Proxmox).
- Prefer **Zero Trust access** (Tailscale ACL / Cloudflare Access) when remote access is needed.
- Assume untrusted input (web/PR/docs) can contain malicious instructions (prompt injection).

Practical rules:
- **Least privilege** end-to-end.
- **Execution gate / approvals** for high-risk actions.
- Secrets are isolated per role/VM; never leak to logs/prompts.
- Workers are treated as “dirty zone”; orchestrator stays “clean”.

---

## 4) Target architecture: Orchestrator + Workers (Proxmox plan)

### Goal
Split responsibilities and reduce blast radius:
- Orchestrator plans and coordinates.
- Workers execute tasks inside isolated environments.

### Recommended baseline decisions (safe defaults)
- Workers execute:
  - our repo tasks + commands explicitly requested by the operator,
  - **no automatic execution** of instructions from untrusted sources (web/README/PR text).
- Crypto/trading mode:
  - autopilot **only within strict limits** + approvals for anything outside the safe zone.
- Deployment topology:
  - **Proxmox + multiple VMs**.
  - Egress: **allowlist-only** (exchanges/API, repo/registry, NTP, required telemetry).

### Suggested worker roles
- `ops-worker` (infra/VM operations): approvals required for infra-changing actions.
- `code-worker` (git/build/test): no production secrets.
- `market-worker` (browser/GUI/marketing): isolated from crypto and infra.
- `trade-worker` (crypto): egress only to exchange APIs; keys without withdrawal.

### Execution gate / approvals
Always approval:
- arbitrary shell exec outside allowlists
- infra changes
- secrets access/rotation
- deploys / protected-branch writes

Autopilot allowed (bounded):
- read-only checks and reports
- builds/tests
- trading inside strict risk limits

---

## 5) Open issues / next actions

### Voice workflow hardening
- Make voice-note replies **fail-proof** (always send text + always send voice note when inbound is voice).

### Proxmox rollout
- Install strategy still depends on safe hardware/disk plan.
- Recommended: separate host or separate disk to avoid risk to the current bare-metal system.

### Reviewer gate implementation
- Implement a concrete gate:
  - static command allow/deny checks
  - LLM reviewer that produces risk notes
  - explicit approval before execution

### Documentation & backups
- Backup/restore scripts exist and were validated.
- Continue writing short docs + commit to repo.

---

## Appendix: Quick references (local paths)

- Workspace: `~/.openclaw/workspace/`
- OpenClaw config: `~/.openclaw/openclaw.json`
- Shared audit/logs: `~/.openclaw/workspace/shared/`
- TEI embeddings endpoint: `http://127.0.0.1:8080/v1/embeddings`
- ASR endpoint: `http://127.0.0.1:9000/v1/audio/transcriptions`

# OpenClaw Memory & Token Optimization — Summary

> Collaborative review by **Wiki** (Claude/Anthropic) and **Tank** (GPT/OpenAI)
> Source document: `numerika-ai/openclaw-memory-token-optimization` (~24KB)
> Date: 2026-02-08 | Task: T-20260208-05

---

## Document Overview

"OpenClaw — Optymalizacja Pamięci i Zarządzania Tokenami" is an architectural analysis proposing a 3-layer optimization stack for OpenClaw-based multi-agent setups:

| Layer | Name | Core Idea |
|-------|------|-----------|
| 1 | Structured Memory Engine | Replace flat files with Knowledge Graph (Neo4j/SQLite) |
| 2 | Context Orchestrator | Session rotation, dynamic loading, token budgeting |
| 3 | Intelligent Token Router | Model routing by complexity (7B → 120B), cost optimization |

Proposed implementation: 4 phases over 8 weeks with metrics-driven validation.

**Top 3 priorities from document:** Dynamic Skill Loading, Session Rotation, Knowledge Graph.

---

## Our Assessment

### ✅ Adopt Now (Phase 1 — already implemented or trivial)

**1. Dynamic Skill Loading** (doc §4.3)
- Load skills on-demand, not at boot.
- We already have this: `openclaw-memory-optimizer` module 3 (Skill Router) uses heuristic matching.
- Document proposes confidence scores + LLM fallback — overkill for now, heuristics suffice.

**2. Handoff over Compaction** (doc §3.2 — "light" version)
- Instead of relying on OpenClaw's built-in compaction (lossy at worst moment), generate a handoff file at natural breakpoints.
- Implemented: module 4 (Handoff Generator) creates `shared/handoff/latest.md`.
- No need for a separate "Session Orchestrator" service — OpenClaw handles sessions natively.

**3. Tiered Memory (HOT/WARM/COLD)** (doc §2.4 — without graph)
- Classify memory files by **importance × recency** (not just dates): HOT (active/critical), WARM (recent/relevant), COLD (archive).
- Implemented: module 5 (Memory Tier Manager) with flat-file approach.
- Document's Knowledge Graph (Neo4j/SQLite) is overengineered for 2-bot setup.

**4. Context Budget Monitoring** (doc §3.1)
- Simple operational rule, no infrastructure needed:
  - **70% context** → ⚠️ WARNING: do handoff at next natural break
  - **85% context** → 🔄 ROTATION READY: handoff + close thread / new task
- Prevents compaction at worst moments. We saw this in practice (Wiki hit 137k/200k = 68%).

### 🔮 Phase 2 — Future (when RTX 3090 is ready)

**5. Model Routing / Local Inference** (doc Layer 3)
- Route TRIVIAL/SIMPLE tasks to local small models (7B on RTX 3090), COMPLEX/CRITICAL to cloud (Opus/GPT-4).
- Requires: Ollama setup on Tank's VM, routing heuristics, soft escalation fallback.
- Directly maps to module 3 (Skill Router) — extend with model selection.
- **Not urgent** — cloud API works fine for current volume.

### ❌ Rejected (overengineered for our setup)

| Proposal | Why Not |
|----------|---------|
| Knowledge Graph (Neo4j/SQLite) | Flat files + tiering work for 2 bots. Graph adds infra complexity with marginal gain. |
| Session Orchestrator as separate service | OpenClaw handles session lifecycle natively. |
| Full 8-week roadmap with 4 phases | Too much ceremony. We iterate: build → test → ship. |
| Multi-agent token pooling | Only 2 agents, independent budgets are fine. |

---

## What We Already Built (2026-02-08)

| Component | Status | Maps to Doc Section |
|-----------|--------|-------------------|
| Lean AGENTS.md (7.8KB → 1.5KB, −81%) | ✅ Done | §4.1 Context reduction |
| On-demand docs (`docs/agent/`) | ✅ Done | §4.3 Dynamic loading |
| Skill Router (module 3) | ✅ Done | §4.3 + Layer 3 (basic) |
| Handoff Generator (module 4) | ✅ Done | §3.2 Session rotation |
| Memory Tiering (module 5) | ✅ Done | §2.4 Tiered memory |
| Context Audit (module 1) | ✅ Done | §3.1 Budget monitoring |
| Lean Loader (module 2) | ✅ Done | §4.1 Boot optimization |
| Bot-to-bot protocol + taskboard | ✅ Done | (not in doc — our addition) |

---

## Key Metrics

| Metric | Before | After | Source |
|--------|--------|-------|--------|
| Static boot context | 11.2 KB | 4.8 KB (−57%) | module 1 audit |
| AGENTS.md | 7.8 KB | 1.5 KB (−81%) | manual optimization |
| First-turn headroom (200K) | ~197K | ~199K | estimated |
| Skill modules passing | — | 5/5 | Tank sanity check |

---

## Next Steps

1. **Run optimization tests A-E** from `shared/MEMORY-OPTIMIZATION-TEST.md`
2. **Context budget alerts** — add operational convention (70%/85% thresholds)
3. **Phase 2 planning** — when Bartosz greenlights RTX 3090 local model hosting
4. **Periodic review** — re-evaluate this summary monthly against actual usage

---

*Generated collaboratively by Wiki & Tank. Push: `numerika-ai/tank-operator/shared/optimization-summary.md`*

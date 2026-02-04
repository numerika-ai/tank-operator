# Tank Operator — system diagram (host + VM layout)

Date: 2026-02-04 (Europe/Warsaw)

Goal: one local **host** running OpenClaw + hypervisor, and multiple **VMs** with strong isolation, easy snapshot/clone, and optional GPU passthrough.

> This is an architecture sketch + recommended defaults. No secrets included.

---

## 1) High-level picture

```mermaid
flowchart TB
  U[Bartosz (Telegram)] -->|DM| OC[OpenClaw Gateway (host)
- default model: openai-codex/gpt-5.2
- optional model: sonusflow/chatgpt-oss-120b (2xSpark)
- shared-first logs]

  OC -->|plans / approvals| ORCH[Orchestrator (host or VM)
- no exchange secrets
- sends jobs to workers]

  subgraph HV[Hypervisor host (Proxmox or KVM)]
    ORCH --> W1[VM: trade-worker
- egress allowlist: exchanges only
- no withdrawals]
    ORCH --> W2[VM: code-worker
- build/test
- repo + registry only]
    ORCH --> W3[VM: browser/marketing
- GUI + browser automation
- isolated from crypto]
    ORCH --> W4[VM: AI-modeler (GPU passthrough)
- full RTX 3090
- local inference services]
  end

  subgraph ST[Storage (single big disk, recommended: ZFS)]
    ZFS[(ZFS pool)] --> VZD[vzdump backups]
    ZFS --> SN[Snapshots / clones]
    ZFS --> REP[Replication (zfs send/receive)]
  end

  HV --- ST
```

---

## 2) Storage: “one big disk” but with clean VM boundaries

Your instinct is right: **one big disk** can be used while still keeping VMs isolated and easy to move.

### Recommended: ZFS on the hypervisor
Why ZFS:
- instant snapshots per VM
- cheap clones
- send/receive replication to another disk/host
- data integrity checks

How it maps to VMs:
- each VM gets its own ZFS dataset/zvol → looks like a separate disk
- moving a VM becomes: **snapshot + send/receive** (or Proxmox replication)

Alternative if you don’t want ZFS:
- LVM-thin (`local-lvm`) is OK for snapshots/clones, but replication story is weaker.

---

## 3) GPU strategy (RTX 3090)

### Reality check: one consumer GPU usually can’t be “safely shared” across multiple VMs
- True vGPU requires vendor support (usually not available on consumer 3090).
- The clean approach is **GPU passthrough to exactly one VM**.

### Recommended plan
- **VM: AI-modeler** gets full RTX 3090 via passthrough.
  - run inference services there (TEI/LLM inference/whatever you need)
- other VMs stay CPU-only.

### Do you need GPU for “browser VM”?
Usually **no**.
- Headless browser automation works fine CPU-only.
- If you want smooth GUI/RDP experience, it can help, but it’s optional.

---

## 4) VM roles (minimal set that scales)

Instead of “many coder VMs”, I’d start with fewer, then split when it hurts.

### Minimum (good start)
1) **trade-worker VM** (crypto)
   - strict egress allowlist
   - secrets scoped to trading only (no withdrawals)
   - approvals for anything outside risk limits

2) **code-worker VM** (build/test)
   - repo + registry only
   - no infra secrets

3) **browser/marketing VM** (GUI + browsing)
   - isolated from crypto and infra
   - treat web as untrusted input

4) **AI-modeler VM** (GPU passthrough)
   - runs local inference services

### Where do “two coder models” fit?
Better than separate VMs:
- keep **one code-worker VM**, but support multiple models via OpenClaw model catalog:
  - default = gpt-5.2
  - optional = 2xSpark
  - later add more

If you really want isolation for “coder A” vs “coder B”, then make it:
- `code-worker-safe` (no network except repo)
- `code-worker-net` (allowlisted network)

---

## 5) Network policy (the part that saves you from yourself)

- Default: **deny-by-default egress** on each worker VM.
- Allowlist only what’s needed:
  - trade-worker → exchanges + NTP
  - code-worker → git + registry + NTP
  - browser VM → specific sites only (if possible)

Remote access:
- LAN first, later Tailscale ACL.
- No public Proxmox/RDP/VNC.

---

## 6) Next decisions (questions to finalize)

1) Hypervisor choice on this box:
   - Proxmox (simple UI, snapshots, backup tooling) vs plain Ubuntu + KVM.
2) Filesystem:
   - ZFS on hypervisor (recommended) vs LVM-thin.
3) GPU passthrough:
   - dedicate 3090 to AI-modeler VM (recommended) and keep others CPU-only.
4) Backup target:
   - second disk/NAS/other host for ZFS replication or Proxmox backups.

---

## 7) Proposed rollout (safe, incremental)

1) Start with hypervisor + ZFS on a safe disk plan.
2) Create the 4 VMs above.
3) Wire network allowlists.
4) Put secrets only into trade-worker, minimal scopes.
5) Add approval gate for high-risk actions.


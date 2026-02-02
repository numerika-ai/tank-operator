# 🐧 Tank Operator - Infrastructure & Bot Management

> **Konfiguracja dla Claude Code i Clawdbot z wspólnymi zasobami**
>
> Docker-first • AI-Ready • Shared Logging • Full Audit Trail

---

## 🎯 Co to jest?

System zarządzania infrastrukturą Linux i botami AI z:

- ✅ **Claude Code Tank Operator** - zarządzanie Dockerem, GPU, modelami AI
- ✅ **Clawdbot Tank Operator** - zarządzanie pamięcią, kontekstem, sesjami
- ✅ **Shared Resources** - wspólne logi widoczne na GitHub

---

## 📁 Struktura

```
tank-operator/
│
├── claude-code-tank-operator/      # 🐧 Claude Code
│   ├── CLAUDE.md                   # Główna konfiguracja
│   ├── FUNCTIONS.md                # Mapa funkcji
│   ├── DOCKER-REGISTRY.md          # Szablony kontenerów
│   ├── SECURITY-POLICIES.md        # Polityki bezpieczeństwa
│   └── settings.json               # Hooki i uprawnienia
│
├── clawdbot-tank-operator/         # 🤖 Clawdbot
│   ├── CLAWDBOT.md                 # Główna konfiguracja
│   └── memory/                     # Pamięć trwała
│       ├── users/                  # Per-user memory
│       ├── sessions/               # Archived sessions
│       └── global/                 # Shared knowledge
│
├── shared/                         # 🔗 Wspólne zasoby
│   ├── POLICIES.md                 # ← SINGLE SOURCE OF TRUTH
│   ├── CHANGELOG.md                # ← GŁÓWNY LOG (GitHub)
│   ├── README.md                   # Opis shared
│   │
│   ├── logs/                       # Historia operacji
│   │   ├── commands/
│   │   ├── docker-changes/
│   │   ├── errors/
│   │   └── daily/
│   │
│   ├── registry/                   # Rejestry
│   │   ├── DOCKER-REGISTRY.md      # Lista kontenerów
│   │   ├── MODEL-REGISTRY.md       # Lista modeli AI
│   │   └── INSTALL-HISTORY.md      # Historia instalacji
│   │
│   └── state/                      # Aktualny stan
│       ├── SYSTEM-STATE.md         # Stan systemu
│       └── ACTIVE-SESSIONS.md      # Sesje Clawdbot
│
└── README.md                       # Ten plik
```

---

## 🔗 Wspólne zasoby (shared/)

### Cel
- **POLICIES.md** - Single Source of Truth dla WSZYSTKICH polityk
- **Jeden CHANGELOG** dla Claude Code i Clawdbot
- **Wspólne registry** - kto co zainstalował
- **Widoczność z zewnątrz** - logi na GitHub

### POLICIES.md - spójność systemów
```
Oba systemy (CC + CB) MUSZĄ przestrzegać:
├── Te same absolutne zakazy
├── Ten sam format logów [SOURCE] [TAG] [STATUS]
├── Te same Docker standards
├── Te same AI/ML limits (VRAM 20GB max)
└── Te same procedury (backup, health check, rollback)
```

### Format logów
```
[YYYY-MM-DD HH:MM] [SOURCE] [TAG] [STATUS] opis | szczegóły
```

| Source | Znaczenie |
|--------|-----------|
| `CC` | Claude Code |
| `CB` | Clawdbot |
| `SYS` | System/Cron |

### Przykłady
```
[2024-01-15 14:32] [CC] [DCK] [OK] start:ollama | img=ollama:latest
[2024-01-15 14:35] [CB] [CTX] [OK] compress:user123 | 45000→12000 tokens
[2024-01-15 15:01] [SYS] [CLN] [OK] cleanup:weekly | freed=2.3GB
```

---

## 🐧 Claude Code Tank Operator

**Przeznaczenie:** Zarządzanie infrastrukturą Docker, GPU, modelami AI

**Kluczowe zasady:**
- Research-first (przed instalacją)
- Docker-first (kontenery > host)
- VRAM management (max 20GB dla modeli)
- Health checks po instalacji
- Backup przed zmianami

**Dokumentacja:** [`claude-code-tank-operator/CLAUDE.md`](claude-code-tank-operator/CLAUDE.md)

---

## 🤖 Clawdbot Tank Operator

**Przeznaczenie:** Zarządzanie pamięcią, kontekstem, sesjami bota

**Kluczowe zasady:**
- Context compression przy 80% tokenów
- Archive & fresh start przy 95%
- Persistent user memory
- Daily/weekly reports

**Dokumentacja:** [`clawdbot-tank-operator/CLAWDBOT.md`](clawdbot-tank-operator/CLAWDBOT.md)

---

## 🖥️ Hardware

| Komponent | Specyfikacja |
|-----------|--------------|
| **CPU** | AMD Ryzen 9 7900X (12C/24T) |
| **RAM** | 63.61 GB |
| **GPU** | NVIDIA RTX 3090 (24GB VRAM) |

| Dysk | Pojemność | Przeznaczenie |
|------|-----------|---------------|
| C: | 299 GB | System |
| D: | 934 GB | Dane, modele AI |
| G: | 299 GB | Backup |

---

## 🚀 Quick Start

### Claude Code
```bash
cd tank-operator/claude-code-tank-operator
claude  # automatycznie wczyta CLAUDE.md
```

### Clawdbot
```python
# W kodzie Clawdbot
SHARED_PATH = "../shared"
CONFIG_PATH = "CLAWDBOT.md"
```

---

## 📊 Komunikacja między systemami

```
┌─────────────────┐         ┌─────────────────┐
│  Claude Code    │         │    Clawdbot     │
│  Tank Operator  │         │  Tank Operator  │
└────────┬────────┘         └────────┬────────┘
         │                           │
         │    ┌─────────────┐        │
         └────►   shared/   ◄────────┘
              │             │
              │ CHANGELOG   │ ← Logi obu systemów
              │ registry/   │ ← Co jest zainstalowane
              │ state/      │ ← Aktualny stan
              └─────────────┘
                    │
                    ▼
              ┌─────────────┐
              │   GitHub    │ ← Widoczne z zewnątrz
              └─────────────┘
```

---

## 📋 Użycie shared/

### Logowanie (oba systemy)
```bash
# Claude Code
echo "[$(date +%Y-%m-%d\ %H:%M)] [CC] [DCK] [OK] action | details" >> shared/CHANGELOG.md

# Clawdbot (Python)
with open("../shared/CHANGELOG.md", "a") as f:
    f.write(f"[{datetime.now()}] [CB] [CTX] [OK] action | details\n")
```

### Sprawdzenie stanu
```bash
# Dostępne modele
cat shared/registry/MODEL-REGISTRY.md

# Aktywne sesje
cat shared/state/ACTIVE-SESSIONS.md

# Ostatnie zmiany
tail -20 shared/CHANGELOG.md
```

### Push na GitHub
```bash
cd shared
git add .
git commit -m "log: [SOURCE] description"
git push
```

---

## 📄 Licencja

MIT License

---

## 👤 Autor

[Numerika.ai](https://numerika.ai)

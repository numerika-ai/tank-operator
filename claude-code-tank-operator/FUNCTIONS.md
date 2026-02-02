# FUNCTIONS MAP - Linux Infrastructure Orchestrator

> Mapa wszystkich funkcji i procedur systemu z odnośnikami do CLAUDE.md

---

## 📋 SPIS TREŚCI

1. [Zasady fundamentalne](#-zasady-fundamentalne)
2. [Procedury instalacji](#-procedury-instalacji)
3. [Zarządzanie AI/ML](#-zarządzanie-aiml)
4. [System logów](#-system-logów)
5. [Bezpieczeństwo](#-bezpieczeństwo)
6. [Maintenance](#-maintenance)

---

## 🎯 ZASADY FUNDAMENTALNE

| # | Zasada | Opis | Kiedy stosować |
|---|--------|------|----------------|
| 0 | **RESEARCH-FIRST** | WebSearch przed każdą instalacją | Zawsze przed instalacją/konfiguracją |
| 1 | **DOCKER-FIRST** | Kontener > instalacja na hoście | Każda nowa usługa |
| 2 | **PRE-INSTALL CHECK** | df -h, docker ps, dokumentacja | Przed każdą instalacją |
| 3 | **NETWORK SECURITY** | Porty zamknięte, reverse proxy | Każda ekspozycja usługi |
| 4 | **LOCAL LOGGING** | Logi do /logs/ | Każda operacja |
| 5 | **GITHUB CHANGELOG** | Push logów na GitHub | Po każdej znaczącej zmianie |
| 6 | **HEALTH CHECK** | Weryfikacja po instalacji | Po każdej instalacji |
| 7 | **BACKUP BEFORE CHANGE** | Commit obrazu, backup volumes | Przed każdą aktualizacją |
| 8 | **ROLLBACK PROCEDURE** | Przywrócenie poprzedniego stanu | Gdy coś pójdzie nie tak |

---

## 🐳 PROCEDURY INSTALACJI

### Flowchart instalacji

```
┌─────────────────────────────────────────────────────────────────┐
│                     NOWA INSTALACJA                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  0. RESEARCH-FIRST                                              │
│     └─ WebSearch: wersja, bugi, CVE, best practices             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  1. PRE-CHECK                                                   │
│     ├─ df -h              → min 10% wolnego miejsca?            │
│     ├─ docker ps -a       → kontener istnieje?                  │
│     └─ docker images      → obraz pobrany?                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
               [ISTNIEJE]          [NIE ISTNIEJE]
                    │                   │
                    ▼                   ▼
              ┌─────────┐    ┌──────────────────────┐
              │  STOP   │    │  2. INSTALACJA       │
              │ (użyj   │    │     └─ docker run/   │
              │ istniejącego)│        compose up    │
              └─────────┘    └──────────────────────┘
                                        │
                                        ▼
                    ┌──────────────────────────────────┐
                    │  3. HEALTH CHECK                 │
                    │     ├─ docker ps                 │
                    │     ├─ docker logs --tail 20    │
                    │     └─ curl health endpoint     │
                    └──────────────────────────────────┘
                                        │
                              ┌─────────┴─────────┐
                              │                   │
                           [OK]              [FAIL]
                              │                   │
                              ▼                   ▼
                    ┌─────────────┐     ┌─────────────┐
                    │ 4. DOKUMENTUJ│     │ ROLLBACK    │
                    │ - DOCKER-REG │     │ - stop/rm   │
                    │ - NETWORK-MAP│     │ - restore   │
                    │ - CHANGELOG  │     │ - log [FAIL]│
                    └─────────────┘     └─────────────┘
                              │
                              ▼
                    ┌─────────────┐
                    │ 5. GIT PUSH │
                    │ logs/       │
                    └─────────────┘
```

### Komendy referencyjne

| Operacja | Komenda | Uwagi |
|----------|---------|-------|
| Sprawdź miejsce | `df -h` | Min 10% wolne |
| Lista kontenerów | `docker ps -a` | Wszystkie, nie tylko running |
| Logi kontenera | `docker logs --tail 50 <nazwa>` | Ostatnie 50 linii |
| Status GPU | `nvidia-smi` | Przed AI workloads |
| Otwarte porty | `ss -tulpn` | Sprawdź kolizje |

---

## 🤖 ZARZĄDZANIE AI/ML

### VRAM Management

```
RTX 3090 = 24 GB VRAM
├── System/CUDA overhead: 2-4 GB (rezerwacja)
├── Dostępne dla modeli: max 22 GB
└── Bezpieczny limit: 20 GB (zalecany)
```

### Model Size Reference

| Parametry | VRAM modelu | + overhead | Status |
|-----------|-------------|------------|--------|
| 7B | 6-8 GB | ~10 GB | OK |
| 13B | 10-14 GB | ~16 GB | OK |
| 30B | 18-20 GB | ~22 GB | LIMIT |
| 70B | >40 GB | - | 4-bit quant |

### Procedura ładowania modelu

```
1. nvidia-smi                    → Sprawdź wolną VRAM
2. Oblicz: VRAM_free > model + 4GB?
3. Jeśli TAK → załaduj model
4. Jeśli NIE → zwolnij inne modele lub użyj quantization
5. Zaloguj w MODEL-REGISTRY.md
```

### Wymagane wersjonowanie

| Komponent | Gdzie sprawdzić | Gdzie zapisać |
|-----------|-----------------|---------------|
| CUDA | `nvidia-smi` | DOCKER-REGISTRY.md |
| cuDNN | `cat /usr/local/cuda/include/cudnn_version.h` | DOCKER-REGISTRY.md |
| Driver | `nvidia-smi` | DOCKER-REGISTRY.md |
| PyTorch | `python -c "import torch; print(torch.__version__)"` | DOCKER-REGISTRY.md |

---

## 📝 SYSTEM LOGÓW

### Format wpisu

```
[YYYY-MM-DD HH:MM] [TAG] [STATUS] opis | szczegóły
```

### Tagi

| Tag | Użycie |
|-----|--------|
| `DCK` | Operacje Docker |
| `NET` | Sieć, porty, firewall |
| `SEC` | Bezpieczeństwo |
| `SYS` | System operacyjny |
| `AI` | Modele AI, CUDA |
| `BOT` | OpenCloud Bot |
| `ERR` | Błędy krytyczne |
| `FIX` | Naprawy, rollback |

### Statusy

| Status | Znaczenie |
|--------|-----------|
| `OK` | Sukces |
| `FAIL` | Niepowodzenie |
| `WARN` | Ostrzeżenie |
| `SKIP` | Pominięto |
| `ROLL` | Rollback |

### Struktura plików

```
logs/
├── CHANGELOG.md          ← Główny log (GitHub)
├── commands/
│   └── YYYY-MM-DD.log
├── docker-changes/
│   └── YYYY-MM-DD.log
├── errors/
│   └── ERROR-LOG.md
└── daily/
    └── YYYY-MM-DD.md
```

### Wyszukiwanie (grep)

```bash
grep "\[ERR\]" logs/CHANGELOG.md     # Wszystkie błędy
grep "\[AI\]" logs/CHANGELOG.md      # Operacje AI
grep "\[FAIL\]" logs/CHANGELOG.md    # Nieudane
grep "2024-01-15" logs/CHANGELOG.md  # Konkretny dzień
```

---

## 🔒 BEZPIECZEŃSTWO

### Absolutne zakazy

| Zakaz | Alternatywa |
|-------|-------------|
| `rm -rf /` | Usuń konkretne pliki |
| `chmod 777` | `chmod 755` lub mniej |
| Hardcoded passwords | Docker secrets, .env |
| `docker run` bez restart | `--restart unless-stopped` |
| Porty 0.0.0.0 | Reverse proxy (Traefik) |
| `curl \| bash` | Pobierz, sprawdź, wykonaj |
| `iptables -F` | Backup przed flush |

### Checklist przed otwarciem portu

- [ ] Czy reverse proxy nie wystarczy?
- [ ] Rate limiting skonfigurowany?
- [ ] Fail2ban rule dodany?
- [ ] Uzasadnienie w logu?

---

## 🔧 MAINTENANCE

### Auto-cleanup (weekly cron)

```
Co robi:
├── Usuwa zatrzymane kontenery (>7 dni)
├── Usuwa dangling images
├── Usuwa nieużywane networks
└── NIE usuwa named volumes (bezpieczeństwo danych)
```

### Backup przed aktualizacją

```bash
# 1. Commit kontenera
docker commit <container> <container>:backup-$(date +%Y%m%d)

# 2. Backup compose
cp docker-compose.yml docker-compose.yml.bak

# 3. Export volumes (bazy danych)
docker run --rm -v <volume>:/data -v $(pwd):/backup \
  alpine tar czf /backup/volume-backup.tar.gz /data
```

### Rollback

```bash
# 1. Stop i usuń uszkodzony kontener
docker stop <nazwa> && docker rm <nazwa>

# 2. Uruchom backup
docker run ... <nazwa>:backup-YYYYMMDD

# 3. Zaloguj
echo "[$(date)] [FIX] [ROLL] rollback:<nazwa>" >> logs/CHANGELOG.md
```

---

## 📁 MAPA PLIKÓW

```
tank-operator/
│
├── CLAUDE.md              # Główna konfiguracja Claude Code
├── FUNCTIONS.md           # Ten plik - mapa funkcji
├── README.md              # Opis projektu
│
├── docs/
│   ├── DOCKER-REGISTRY.md # Lista kontenerów + wersje CUDA
│   ├── MODEL-REGISTRY.md  # Lista modeli AI + VRAM
│   ├── NETWORK-MAP.md     # Mapa portów i sieci
│   ├── SECURITY-POLICIES.md
│   └── EMERGENCY-RUNBOOK.md
│
├── logs/
│   ├── CHANGELOG.md       # ← PUSHOWANY NA GITHUB
│   ├── commands/
│   ├── docker-changes/
│   ├── errors/
│   └── daily/
│
├── infrastructure/
│   ├── docker-compose/
│   ├── network-configs/
│   └── security-policies/
│
└── state/
    ├── SYSTEM-STATE.md
    ├── ACTIVE-ISSUES.md
    └── PENDING-TASKS.md
```

---

## 🔗 QUICK REFERENCE

| Potrzebuję... | Idź do... |
|---------------|-----------|
| Zainstalować usługę | [Procedury instalacji](#-procedury-instalacji) |
| Uruchomić model AI | [Zarządzanie AI/ML](#-zarządzanie-aiml) |
| Sprawdzić logi | [System logów](#-system-logów) |
| Otworzyć port | [Bezpieczeństwo](#-bezpieczeństwo) |
| Zrobić backup | [Maintenance](#-maintenance) |
| Rollback po błędzie | [Maintenance](#-maintenance) |

---

**Powiązane pliki:**
- `CLAUDE.md` - pełna konfiguracja
- `docs/DOCKER-REGISTRY.md` - rejestr kontenerów
- `docs/MODEL-REGISTRY.md` - rejestr modeli AI
- `logs/CHANGELOG.md` - historia zmian

# 🐧 LINUX INFRASTRUCTURE ORCHESTRATOR v1.0

> **CLAUDE CODE CONFIGURATION FOR SECURE LINUX ADMINISTRATION**
>
> Ten plik jest automatycznie wczytywany przez Claude Code.
> Definiuje zasady zarządzania infrastrukturą Linux z podejściem Docker-first.

---

## 🖥️ HARDWARE

| Komponent | Specyfikacja |
|-----------|--------------|
| **CPU** | AMD Ryzen 9 7900X 12-Core Processor |
| **Rdzenie/Wątki** | 12 / 24 |
| **RAM** | 63.61 GB |
| **GPU** | NVIDIA GeForce RTX 3090 |

### Dyski
| Dysk | Pojemność | Przeznaczenie |
|------|-----------|---------------|
| C: | 299 GB | System |
| D: | 934 GB | Dane, modele AI, volumes Docker |
| G: | 299 GB | Backup, temp |

> **ZASADA:** Przed każdą instalacją sprawdź `df -h` - wymagane min. 10% wolnego miejsca

---

## 🎯 MISJA

**Cel główny:** Zarządzanie infrastrukturą Linux jako platformą do obsługi **modeli AI** i **OpenCloud Bot** w wirtualizowanych maszynach Ubuntu.

Zarządzanie infrastrukturą Linux w sposób:
- **Bezpieczny** - security-by-default, zasada najmniejszych uprawnień
- **Dokumentowany** - każda zmiana jest logowana
- **Powtarzalny** - Docker-first, Infrastructure as Code
- **Audytowalny** - pełna historia operacji
- **AI-Ready** - zoptymalizowany pod uruchamianie modeli AI (GPU, VRAM, CUDA)

---

## 📜 FUNDAMENTALNE ZASADY

### 0. RESEARCH-FIRST (NAJWAŻNIEJSZA ZASADA)
```
PRZED każdą operacją instalacji/konfiguracji:
1. Przeszukaj internet (WebSearch) w poszukiwaniu:
   - Najnowszej wersji oprogramowania
   - Znanych bugów i CVE
   - Best practices dla danej wersji
   - Breaking changes w ostatnich aktualizacjach
2. Sprawdź changelog/release notes projektu
3. Zweryfikuj kompatybilność z Ubuntu/Docker
4. Dopiero po researchu → rozpocznij instalację
```

**Przykładowe zapytania:**
- `"<nazwa_oprogramowania> latest version 2024 changelog"`
- `"<nazwa> docker best practices"`
- `"<nazwa> known issues ubuntu"`
- `"<nazwa> CUDA compatibility RTX 3090"` (dla AI/ML)

### 1. DOCKER-FIRST
```
ZAWSZE sprawdź czy usługa może działać w kontenerze
ZAWSZE sprawdź czy kontener już istnieje przed instalacją
NIGDY nie instaluj bezpośrednio na hoście jeśli Docker jest opcją
```

### 2. PRZED KAŻDĄ INSTALACJĄ
```bash
# OBOWIĄZKOWA SEKWENCJA:
1. df -h                                 # Czy jest min. 10% wolnego miejsca?
2. docker ps -a | grep <nazwa>           # Czy kontener istnieje?
3. docker images | grep <obraz>          # Czy obraz jest pobrany?
4. cat docs/DOCKER-REGISTRY.md           # Sprawdź dokumentację
5. Jeśli nie istnieje → instaluj i DOKUMENTUJ
```

> **STOP jeśli:** wolne miejsce <10% na docelowym dysku - najpierw wyczyść!

### 3. BEZPIECZEŃSTWO SIECIOWE
```
- Domyślnie: wszystkie porty ZAMKNIĘTE
- Otwieranie portów wymaga UZASADNIENIA w logu
- Preferuj wewnętrzne sieci Docker (bridge/overlay)
- Eksponuj TYLKO przez reverse proxy (Traefik/Nginx)
```

### 4. LOGOWANIE (SHARED)
```
KAŻDA operacja systemowa → ../shared/logs/commands/
KAŻDA zmiana Docker → ../shared/logs/docker-changes/
KAŻDY błąd → ../shared/logs/errors/
Dzienne podsumowanie → ../shared/logs/daily/
```

> **UWAGA:** Używaj ../shared/ - wspólne logi z Clawdbotem!

### 5. GITHUB CHANGELOG (ZEWNĘTRZNA WIDOCZNOŚĆ)
```
PO KAŻDEJ znaczącej zmianie w systemie:
1. Zaktualizuj ../shared/CHANGELOG.md
2. git add ../shared/
3. git commit -m "log: [CC] <krótki opis>"
4. git push
```

> 📡 **CEL:** Jeśli coś pójdzie nie tak, historia zmian jest widoczna z zewnątrz (GitHub)

### 6. HEALTH CHECK (PO KAŻDEJ INSTALACJI)
```bash
# OBOWIĄZKOWA WERYFIKACJA:
1. docker ps | grep <nazwa>              # Czy kontener działa?
2. docker logs --tail 20 <nazwa>         # Czy są błędy w logach?
3. curl -s localhost:<port>/health       # Endpoint health (jeśli dostępny)
4. Jeśli FAIL → rollback natychmiast
```

### 7. BACKUP PRZED ZMIANĄ
```
PRZED każdą aktualizacją/modyfikacją:
1. docker commit <container> <container>:backup-$(date +%Y%m%d)
2. Zapisz docker-compose.yml.bak
3. Eksportuj volumes krytyczne (bazy danych!)
4. Dopiero po backup → wprowadź zmiany
```

### 8. ROLLBACK PROCEDURE
```bash
# Jeśli coś poszło nie tak:
1. docker stop <nazwa>
2. docker rm <nazwa>
3. docker run ... <nazwa>:backup-YYYYMMDD  # Przywróć backup
4. Zaloguj [FIX] [ROLL] w CHANGELOG.md
```

---

## 📝 SYSTEM LOGÓW (TOKEN-EFFICIENT)

### Format wpisu (jedna linia = jeden wpis)
```
[YYYY-MM-DD HH:MM] [TAG] [STATUS] opis | szczegóły
```

### Tagi (krótkie, przeszukiwalne)
| Tag | Znaczenie |
|-----|-----------|
| `DCK` | Docker (run/stop/rm/build) |
| `NET` | Sieć (porty/firewall/DNS) |
| `SEC` | Security (fail2ban/ufw/certs) |
| `SYS` | System (apt/service/reboot) |
| `AI` | AI/ML (modele/CUDA/VRAM) |
| `BOT` | OpenCloud Bot operacje |
| `ERR` | Błąd krytyczny |
| `FIX` | Naprawa/rollback |

### Statusy
| Status | Znaczenie |
|--------|-----------|
| `OK` | Sukces |
| `FAIL` | Niepowodzenie |
| `WARN` | Ostrzeżenie |
| `SKIP` | Pominięto |
| `ROLL` | Rollback |

### Przykłady wpisów
```
[2024-01-15 14:32] [DCK] [OK] start:ollama | img=ollama:latest port=11434
[2024-01-15 14:35] [AI] [OK] load:llama2 | vram=12GB time=45s
[2024-01-15 15:01] [NET] [FAIL] open:8080 | err=port_in_use pid=1234
[2024-01-15 15:02] [FIX] [OK] kill:1234 | freed_port=8080
[2024-01-15 15:10] [BOT] [OK] deploy:opencloud | vm=ubuntu-01 cpu=4 ram=8G
```

### Struktura plików logów
```
logs/
├── CHANGELOG.md          # ← GŁÓWNY LOG (pushowany na GitHub)
├── commands/
│   └── YYYY-MM-DD.log    # Dzienne logi poleceń
├── docker-changes/
│   └── YYYY-MM-DD.log    # Zmiany Docker
├── errors/
│   └── ERROR-LOG.md      # Błędy krytyczne
└── daily/
    └── YYYY-MM-DD.md     # Podsumowania dzienne
```

### CHANGELOG.md - szablon
```markdown
# CHANGELOG

## [YYYY-MM-DD]

### Zmiany
- `[TAG] [STATUS]` opis | szczegóły

### Błędy (jeśli wystąpiły)
- `[ERR]` opis | rozwiązanie

---
```

### Wyszukiwanie w logach (grep-friendly)
```bash
# Wszystkie błędy
grep "\[ERR\]" logs/CHANGELOG.md

# Operacje Docker z dzisiaj
grep "\[DCK\]" logs/CHANGELOG.md | grep "2024-01-15"

# Wszystkie operacje AI
grep "\[AI\]" logs/CHANGELOG.md

# Nieudane operacje
grep "\[FAIL\]" logs/CHANGELOG.md
```

---

## 🚫 ABSOLUTNE ZAKAZY

| Zakaz | Powód |
|-------|-------|
| `rm -rf /` lub warianty z `/` | Katastrofalne usunięcie |
| `chmod 777` | Dziura bezpieczeństwa |
| Hardcoded passwords w plikach | Security breach |
| `docker run` bez `--restart` policy | Brak odporności na restart |
| Porty 0.0.0.0 bez firewalla | Ekspozycja na świat |
| `curl \| bash` z nieznanych źródeł | Wykonanie nieznanego kodu |
| Modyfikacja `/etc/passwd` ręcznie | Użyj `useradd`/`usermod` |
| `iptables -F` bez backupu | Utrata konfiguracji FW |

---

## 🐳 DOCKER WORKFLOW

### Przed instalacją nowego kontenera:

```bash
# 1. SPRAWDŹ ISTNIEJĄCE
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 2. SPRAWDŹ DOKUMENTACJĘ
cat docs/DOCKER-REGISTRY.md | grep -i "<nazwa_usługi>"

# 3. JEŚLI NIE ISTNIEJE - ZAINSTALUJ Z DOKUMENTACJĄ
# Po instalacji OBOWIĄZKOWO zaktualizuj:
# - docs/DOCKER-REGISTRY.md
# - docs/NETWORK-MAP.md
# - logs/docker-changes/YYYY-MM-DD.md
```

### Standardowa konfiguracja kontenera:

```yaml
# WYMAGANE pola w każdym docker-compose:
services:
  nazwa:
    container_name: nazwa_kontenera      # ZAWSZE explicit
    restart: unless-stopped              # ZAWSZE polityka restart
    networks:
      - internal                         # ZAWSZE named network
    labels:
      - "managed-by=claude-orchestrator"
      - "installed-date=${DATE}"
      - "purpose=${OPIS}"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    # NIGDY nie używaj 'privileged: true' bez uzasadnienia
    # NIGDY nie mountuj /var/run/docker.sock bez potrzeby
```

---

## 🤖 AI/ML WORKFLOW

### Przeznaczenie systemu
```
- Hostowanie modeli AI (LLM, Vision, Audio)
- Obsługa OpenCloud Bot w VM Ubuntu
- Zarządzanie zasobami GPU (RTX 3090 - 24GB VRAM)
- Wirtualizacja maszyn dla izolacji workloadów
```

### Przed uruchomieniem modelu AI
```bash
# 1. SPRAWDŹ ZASOBY GPU
nvidia-smi                              # Status GPU
nvidia-smi --query-gpu=memory.free --format=csv  # Wolna VRAM

# 2. SPRAWDŹ WYMAGANIA MODELU (research-first!)
# WebSearch: "<model_name> VRAM requirements"
# WebSearch: "<model_name> RTX 3090 performance"

# 3. SPRAWDŹ KOMPATYBILNOŚĆ CUDA
nvidia-smi | grep "CUDA Version"
docker run --gpus all nvidia/cuda:12.0-base nvidia-smi
```

### Docker z GPU (wymagana konfiguracja)
```yaml
services:
  ai-model:
    image: <obraz>
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - CUDA_VISIBLE_DEVICES=0
    # Dla dużych modeli - użyj dysku D: (największa pojemność)
    volumes:
      - /mnt/d/ai-models:/models
```

### OpenCloud Bot - deployment checklist
```
- [ ] VM Ubuntu utworzona i skonfigurowana
- [ ] Sieć wewnętrzna między VM a hostem
- [ ] GPU passthrough (jeśli wymagane)
- [ ] Monitoring zasobów aktywny
- [ ] Logi przekierowane do /logs/
- [ ] Backup konfiguracji bota
```

### VRAM Management (RTX 3090 = 24GB)
```
ZASADA: NIGDY nie używaj 100% VRAM!
- System/CUDA overhead: ~2-4 GB (rezerwacja obowiązkowa)
- Dostępne dla modeli: max 22 GB
- Bezpieczny limit: 20 GB (zalecany)
```

### Limity zasobów
| Model size | VRAM modelu | + overhead | Zalecenie |
|------------|-------------|------------|-----------|
| 7B params | ~6-8 GB | ~10 GB | OK |
| 13B params | ~10-14 GB | ~16 GB | OK |
| 30B params | ~18-20 GB | ~22 GB | LIMIT (quantize!) |
| 70B params | >40 GB | N/A | 4-bit quant lub offload CPU |

> **PRZED załadowaniem modelu:** `nvidia-smi` → sprawdź czy VRAM free > model + 4GB

### Wersjonowanie CUDA/cuDNN
```
OBOWIĄZEK dokumentowania dla każdego kontenera AI:
- Wersja CUDA (np. 12.1)
- Wersja cuDNN (np. 8.9)
- Wersja PyTorch/TensorFlow
- Driver NVIDIA (np. 535.xx)

Sprawdź kompatybilność: nvidia-smi → CUDA Version
Zapisz w: docs/DOCKER-REGISTRY.md przy każdym kontenerze AI
```

### Model Registry (docs/MODEL-REGISTRY.md)
```markdown
# MODEL REGISTRY

| Model | Rozmiar | VRAM | Quantization | Kontener | Status |
|-------|---------|------|--------------|----------|--------|
| llama2-7b | 7B | 6GB | fp16 | ollama | active |
| mistral-7b | 7B | 8GB | fp16 | ollama | active |
| codellama-13b | 13B | 12GB | 4-bit | ollama | standby |

## Załadowane modele (runtime)
> Aktualizuj po każdym `ollama pull` lub load modelu

## Historia zmian
- [DATA] [AI] [OK] pull:model_name | vram=XGB
```

### Auto-cleanup (Cron Job)
```bash
# /etc/cron.weekly/docker-cleanup

#!/bin/bash
# Czyszczenie nieużywanych zasobów Docker

LOG="/logs/commands/cleanup-$(date +%Y%m%d).log"

echo "[$(date)] Starting cleanup" >> $LOG

# Usuń zatrzymane kontenery starsze niż 7 dni
docker container prune -f --filter "until=168h" >> $LOG 2>&1

# Usuń nieużywane obrazy (dangling)
docker image prune -f >> $LOG 2>&1

# Usuń nieużywane volumes (OSTROŻNIE - tylko unnamed)
# docker volume prune -f >> $LOG 2>&1  # WYŁĄCZONE - ryzyko utraty danych

# Usuń nieużywane sieci
docker network prune -f >> $LOG 2>&1

echo "[$(date)] Cleanup finished" >> $LOG
```

> **UWAGA:** Skrypt NIE usuwa named volumes - chroni dane!

---

## 📁 STRUKTURA PROJEKTU

```
/linux-orchestrator/
│
├── CLAUDE.md                    # ← JESTEŚ TUTAJ
│
├── docs/                        # 📚 DOKUMENTACJA
│   ├── DOCKER-REGISTRY.md       # Lista wszystkich kontenerów
│   ├── NETWORK-MAP.md           # Mapa sieci i portów
│   ├── SECURITY-POLICIES.md     # Polityki bezpieczeństwa
│   ├── BACKUP-PROCEDURES.md     # Procedury backup
│   └── EMERGENCY-RUNBOOK.md     # Procedury awaryjne
│
├── infrastructure/              # 🏗️ KONFIGURACJE
│   ├── docker-compose/          # Pliki compose per usługa
│   ├── network-configs/         # Konfiguracje sieciowe
│   └── security-policies/       # Reguły firewall, fail2ban
│
├── logs/                        # 📝 LOGI
│   ├── commands/                # Historia poleceń
│   ├── docker-changes/          # Zmiany w kontenerach
│   ├── errors/                  # Log błędów
│   └── daily/                   # Dzienne podsumowania
│
├── state/                       # 📊 BIEŻĄCY STAN
│   ├── SYSTEM-STATE.md          # Stan systemu
│   ├── ACTIVE-ISSUES.md         # Aktywne problemy
│   └── PENDING-TASKS.md         # Zadania do wykonania
│
└── .claude/                     # ⚙️ KONFIGURACJA CLAUDE CODE
    ├── settings.json            # Hooki i uprawnienia
    ├── skills/                  # Umiejętności domenowe
    ├── commands/                # Slash commands
    └── agents/                  # Definicje agentów
```

---

## 🔧 POLECENIA REFERENCYJNE

### System Info
```bash
# Status systemu
uname -a && uptime && free -h && df -h

# Procesy
htop || top -bn1 | head -20

# Sieć
ss -tulpn                        # Otwarte porty
ip addr                          # Interfejsy
```

### Docker
```bash
# Status
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker stats --no-stream

# Logi
docker logs --tail 100 -f <container>

# Cleanup (OSTROŻNIE)
docker system prune -f           # Usuwa unused
docker volume prune -f           # Usuwa volumes (DANE!)
```

### Security
```bash
# Firewall
sudo ufw status verbose
sudo iptables -L -n -v

# Fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Audyt
sudo aureport --summary          # Jeśli auditd
last -20                         # Logowania
```

---

## 📋 CHECKLIST PRZED OPERACJĄ

### Przed instalacją usługi:
- [ ] Czy istnieje oficjalny obraz Docker?
- [ ] Czy kontener już nie istnieje? (`docker ps -a | grep`)
- [ ] Czy porty nie kolidują? (`ss -tulpn | grep`)
- [ ] Czy jest miejsce na dysku? (`df -h`)
- [ ] Czy przygotowałem wpis do DOCKER-REGISTRY.md?

### Przed otwarciem portu:
- [ ] Czy to konieczne? (może reverse proxy?)
- [ ] Czy jest rate limiting?
- [ ] Czy jest fail2ban rule?
- [ ] Czy zapisałem uzasadnienie w logu?

### Przed usunięciem:
- [ ] Czy jest backup danych?
- [ ] Czy sprawdziłem zależności?
- [ ] Czy poinformowałem o skutkach?

---

## 🔗 WAŻNE LINKI

- **Dokumentacja Docker:** → `docs/DOCKER-REGISTRY.md`
- **Mapa sieci:** → `docs/NETWORK-MAP.md`
- **Procedury awaryjne:** → `docs/EMERGENCY-RUNBOOK.md`
- **Log błędów:** → `logs/errors/ERROR-LOG.md`

---

## 📊 METRYKI SUKCESU

| Metryka | Cel |
|---------|-----|
| Uptime usług | >99.5% |
| Czas reakcji na alert | <15 min |
| Dokumentacja aktualna | 100% |
| Kontenery z restart policy | 100% |
| Porty za reverse proxy | >90% |

---

**Wersja:** 1.0.0  
**Ostatnia aktualizacja:** {{DATE}}  
**Właściciel:** Numerika

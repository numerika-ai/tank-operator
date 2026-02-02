# 📜 SHARED POLICIES - Wspólne zasady dla wszystkich systemów

> **Ten plik jest SINGLE SOURCE OF TRUTH dla polityk bezpieczeństwa**
>
> Dotyczy: Claude Code, Clawdbot, i wszystkich przyszłych agentów

---

## 🎯 CEL

Zapewnienie **spójności** działań wszystkich systemów:
- Te same standardy bezpieczeństwa
- Te same procedury
- Ten sam format logów
- Wspólna baza wiedzy o infrastrukturze

---

## 🖥️ HARDWARE (wspólne)

| Komponent | Specyfikacja |
|-----------|--------------|
| **CPU** | AMD Ryzen 9 7900X (12C/24T) |
| **RAM** | 63.61 GB |
| **GPU** | NVIDIA RTX 3090 (24GB VRAM) |

| Dysk | Pojemność | Przeznaczenie |
|------|-----------|---------------|
| C: | 299 GB | System |
| D: | 934 GB | Dane, modele AI, Docker volumes |
| G: | 299 GB | Backup, temp |

---

## 📜 FUNDAMENTALNE ZASADY (obowiązują WSZYSTKICH)

### 0. RESEARCH-FIRST
```
PRZED każdą instalacją/konfiguracją:
1. WebSearch: najnowsza wersja, bugi, CVE
2. Sprawdź kompatybilność
3. Dopiero potem działaj
```

### 1. SHARED-FIRST
```
WSZYSTKIE logi → shared/CHANGELOG.md
WSZYSTKIE instalacje → shared/registry/
WSZYSTKIE stany → shared/state/

NIGDY nie twórz lokalnych logów - używaj shared!
```

### 2. DOCKER-FIRST
```
ZAWSZE kontener > instalacja na hoście
ZAWSZE sprawdź czy kontener istnieje przed instalacją
ZAWSZE używaj restart policy
```

### 3. PRZED KAŻDĄ INSTALACJĄ
```bash
1. df -h                    # Min 10% wolnego miejsca
2. docker ps -a | grep X    # Czy już istnieje?
3. shared/registry/         # Sprawdź dokumentację
4. Dopiero potem instaluj
```

### 4. SECURITY-BY-DEFAULT
```
- Porty: domyślnie ZAMKNIĘTE
- Dostęp: przez reverse proxy
- Secrets: NIGDY hardcoded
- Kontenery: non-root
```

### 5. AUDIT TRAIL
```
KAŻDA operacja musi być zalogowana
Format: [YYYY-MM-DD HH:MM] [SOURCE] [TAG] [STATUS] opis | szczegóły
Push do GitHub = widoczność z zewnątrz
```

---

## 🚫 ABSOLUTNE ZAKAZY (dla WSZYSTKICH systemów)

| Zakaz | Powód | Alternatywa |
|-------|-------|-------------|
| `rm -rf /` lub warianty | Katastrofalne usunięcie | Usuń konkretne pliki |
| `chmod 777` | Dziura bezpieczeństwa | `chmod 755` lub mniej |
| Hardcoded passwords | Security breach | Docker secrets, .env |
| `docker run` bez `--restart` | Brak odporności | `--restart unless-stopped` |
| Porty 0.0.0.0 bez FW | Ekspozycja | Reverse proxy |
| `curl \| bash` nieznane | Nieznany kod | Pobierz, sprawdź, wykonaj |
| `iptables -F` bez backup | Utrata FW | Backup przed flush |
| Lokalne logi (poza shared/) | Brak widoczności | Używaj shared/ |
| Nielogowane operacje | Brak audytu | Zawsze loguj |

---

## 📝 FORMAT LOGÓW (obowiązkowy)

### Struktura wpisu
```
[YYYY-MM-DD HH:MM] [SOURCE] [TAG] [STATUS] opis | szczegóły
```

### SOURCE (identyfikator systemu)
| Source | System |
|--------|--------|
| `CC` | Claude Code |
| `CB` | Clawdbot |
| `SYS` | System/Cron |

### TAG (typ operacji)
| Tag | Znaczenie | Używany przez |
|-----|-----------|---------------|
| `DCK` | Docker operations | CC, CB |
| `NET` | Network/firewall | CC |
| `SEC` | Security | CC, CB |
| `SYS` | System operations | CC, SYS |
| `AI` | AI/ML models | CC, CB |
| `CTX` | Context management | CB |
| `MEM` | Memory/persistence | CB |
| `TOK` | Token management | CB |
| `SES` | Session management | CB |
| `ERR` | Errors | CC, CB, SYS |
| `FIX` | Fixes/rollback | CC, CB |

### STATUS
| Status | Znaczenie |
|--------|-----------|
| `OK` | Sukces |
| `FAIL` | Niepowodzenie |
| `WARN` | Ostrzeżenie |
| `SKIP` | Pominięto |
| `ROLL` | Rollback |

---

## 🐳 DOCKER STANDARDS (obowiązkowe)

### Każdy kontener MUSI mieć:

```yaml
services:
  nazwa:
    container_name: explicit_name       # WYMAGANE
    restart: unless-stopped             # WYMAGANE
    networks:
      - internal                        # WYMAGANE (named network)
    labels:
      - "managed-by=tank-operator"      # WYMAGANE
      - "installed-by=${SOURCE}"        # CC lub CB
      - "installed-date=${DATE}"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    # ZABRONIONE bez uzasadnienia:
    # - privileged: true
    # - /var/run/docker.sock mount
```

### Sieci Docker (predefiniowane)

| Sieć | Zakres IP | Przeznaczenie |
|------|-----------|---------------|
| traefik-public | 172.20.0.0/16 | Usługi publiczne |
| internal | 172.21.0.0/16 | Komunikacja wewnętrzna |
| monitoring | 172.22.0.0/16 | Stack monitoringu |
| database | 172.23.0.0/16 | Izolacja baz danych |
| clawdbot | 172.25.0.0/16 | Sieć Clawdbot |

---

## 🤖 AI/ML STANDARDS (obowiązkowe)

### VRAM Management (RTX 3090 = 24GB)

```
ZASADA: NIGDY nie używaj 100% VRAM!

- System/CUDA overhead: 2-4 GB (rezerwacja obowiązkowa)
- Dostępne dla modeli: max 22 GB
- Bezpieczny limit: 20 GB (zalecany)
```

### Przed załadowaniem modelu

```bash
# OBOWIĄZKOWE dla CC i CB:
1. nvidia-smi                    # Sprawdź wolną VRAM
2. Oblicz: VRAM_free > model + 4GB?
3. Sprawdź shared/registry/MODEL-REGISTRY.md
4. Jeśli brak miejsca → zwolnij inne modele
5. Zaloguj operację
```

### Model size limits

| Parametry | VRAM | Status |
|-----------|------|--------|
| 7B | 6-8 GB | OK |
| 13B | 10-14 GB | OK |
| 30B | 18-20 GB | LIMIT |
| 70B | >40 GB | 4-bit quant wymagany |

---

## 🔄 PROCEDURY (obowiązkowe)

### Health Check (po każdej instalacji)

```bash
# Wykonuje: CC lub CB (kto instalował)
1. docker ps | grep <nazwa>
2. docker logs --tail 20 <nazwa>
3. curl health endpoint (jeśli dostępny)
4. Jeśli FAIL → rollback
5. Zaloguj wynik
```

### Backup przed zmianą

```bash
# WYMAGANE przed każdą modyfikacją:
1. docker commit <container> <container>:backup-$(date +%Y%m%d)
2. cp docker-compose.yml docker-compose.yml.bak
3. Export volumes (jeśli krytyczne)
4. Dopiero potem zmieniaj
```

### Rollback

```bash
# Jeśli coś poszło nie tak:
1. docker stop <nazwa>
2. docker rm <nazwa>
3. docker run ... <nazwa>:backup-YYYYMMDD
4. Zaloguj [SOURCE] [FIX] [ROLL]
```

---

## 📊 SHARED RESOURCES (struktura)

```
shared/
├── POLICIES.md           # ← TEN PLIK (source of truth)
├── CHANGELOG.md          # Główny log (GitHub visible)
│
├── logs/                 # Szczegółowe logi
│   ├── commands/
│   ├── docker-changes/
│   ├── errors/
│   └── daily/
│
├── registry/             # Co jest zainstalowane
│   ├── DOCKER-REGISTRY.md
│   ├── MODEL-REGISTRY.md
│   └── INSTALL-HISTORY.md
│
└── state/                # Aktualny stan
    ├── SYSTEM-STATE.md
    └── ACTIVE-SESSIONS.md
```

---

## ✅ CHECKLIST ZGODNOŚCI

### Przed każdą operacją sprawdź:

- [ ] Czy przeczytałem POLICIES.md?
- [ ] Czy operacja jest zgodna z zakazami?
- [ ] Czy loguję do shared/?
- [ ] Czy używam poprawnego SOURCE w logach?
- [ ] Czy sprawdziłem registry przed instalacją?

### Po każdej operacji:

- [ ] Zaktualizowałem CHANGELOG.md
- [ ] Zaktualizowałem odpowiedni registry
- [ ] Wykonałem health check (jeśli instalacja)
- [ ] Pushowałem zmiany na GitHub

---

## 🔗 KOMUNIKACJA MIĘDZY SYSTEMAMI

```
┌─────────────────┐                    ┌─────────────────┐
│   Claude Code   │                    │    Clawdbot     │
│                 │                    │                 │
│ Czyta:          │                    │ Czyta:          │
│ - POLICIES.md   │                    │ - POLICIES.md   │
│ - MODEL-REG     │                    │ - MODEL-REG     │
│ - DOCKER-REG    │                    │ - DOCKER-REG    │
│                 │                    │                 │
│ Pisze:          │                    │ Pisze:          │
│ - [CC] logi     │                    │ - [CB] logi     │
│ - DOCKER-REG    │                    │ - SESSIONS      │
│ - MODEL-REG     │                    │ - MODEL-REG     │
└────────┬────────┘                    └────────┬────────┘
         │                                      │
         │         ┌──────────────┐             │
         └────────►│   shared/    │◄────────────┘
                   │              │
                   │ POLICIES.md  │ ← Single source of truth
                   │ CHANGELOG.md │ ← Wspólny log
                   │ registry/    │ ← Wspólna baza
                   │ state/       │ ← Wspólny stan
                   └──────────────┘
```

---

## 📋 WERSJONOWANIE

| Wersja | Data | Zmiany |
|--------|------|--------|
| 1.0.0 | 2024-XX-XX | Initial shared policies |

---

**Właściciel:** Numerika
**Dotyczy:** Claude Code, Clawdbot, wszystkie przyszłe agenty

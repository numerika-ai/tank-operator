# 🐧 LINUX INFRASTRUCTURE ORCHESTRATOR v1.0

> **CLAUDE CODE CONFIGURATION FOR SECURE LINUX ADMINISTRATION**
> 
> Ten plik jest automatycznie wczytywany przez Claude Code.
> Definiuje zasady zarządzania infrastrukturą Linux z podejściem Docker-first.

---

## 🎯 MISJA

Zarządzanie infrastrukturą Linux w sposób:
- **Bezpieczny** - security-by-default, zasada najmniejszych uprawnień
- **Dokumentowany** - każda zmiana jest logowana
- **Powtarzalny** - Docker-first, Infrastructure as Code
- **Audytowalny** - pełna historia operacji

---

## 📜 FUNDAMENTALNE ZASADY

### 1. DOCKER-FIRST
```
ZAWSZE sprawdź czy usługa może działać w kontenerze
ZAWSZE sprawdź czy kontener już istnieje przed instalacją
NIGDY nie instaluj bezpośrednio na hoście jeśli Docker jest opcją
```

### 2. PRZED KAŻDĄ INSTALACJĄ
```bash
# OBOWIĄZKOWA SEKWENCJA:
1. docker ps -a | grep <nazwa>           # Czy kontener istnieje?
2. docker images | grep <obraz>          # Czy obraz jest pobrany?
3. cat docs/DOCKER-REGISTRY.md           # Sprawdź dokumentację
4. Jeśli nie istnieje → instaluj i DOKUMENTUJ
```

### 3. BEZPIECZEŃSTWO SIECIOWE
```
- Domyślnie: wszystkie porty ZAMKNIĘTE
- Otwieranie portów wymaga UZASADNIENIA w logu
- Preferuj wewnętrzne sieci Docker (bridge/overlay)
- Eksponuj TYLKO przez reverse proxy (Traefik/Nginx)
```

### 4. LOGOWANIE
```
KAŻDA operacja systemowa → /logs/commands/
KAŻDA zmiana Docker → /logs/docker-changes/
KAŻDY błąd → /logs/errors/
Dzienne podsumowanie → /logs/daily/
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

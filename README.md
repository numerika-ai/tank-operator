# 🐧 Linux Infrastructure Orchestrator

> **Konfiguracja Claude Code do bezpiecznego zarządzania infrastrukturą Linux**
> 
> Docker-first • Security-by-default • Fully documented

---

## 🎯 Co to jest?

System konfiguracyjny dla [Claude Code](https://claude.ai/code) zapewniający:

- ✅ **Bezpieczne zarządzanie Dockerem** - sprawdzanie przed instalacją, dokumentacja
- ✅ **Standardy bezpieczeństwa sieciowego** - firewall, fail2ban, SSL
- ✅ **Automatyczne logowanie** - każda operacja jest zapisywana
- ✅ **Procedury awaryjne** - gotowe runbooki na wypadek problemów
- ✅ **Pełna dokumentacja** - rejestr kontenerów, mapa sieci

---

## 📁 Struktura

```
linux-orchestrator/
│
├── CLAUDE.md                    # 🎭 Główna konfiguracja Claude Code
│
├── docs/                        # 📚 Dokumentacja
│   ├── DOCKER-REGISTRY.md       # Lista wszystkich kontenerów
│   ├── NETWORK-MAP.md           # Mapa sieci i portów
│   ├── SECURITY-POLICIES.md     # Polityki bezpieczeństwa
│   ├── BACKUP-PROCEDURES.md     # Procedury backup
│   └── EMERGENCY-RUNBOOK.md     # Procedury awaryjne
│
├── infrastructure/              # 🏗️ Konfiguracje
│   ├── docker-compose/          # Pliki compose per usługa
│   ├── network-configs/         # Konfiguracje sieciowe
│   └── security-policies/       # Reguły firewall, fail2ban
│
├── logs/                        # 📝 Logi
│   ├── commands/                # Historia poleceń
│   ├── docker-changes/          # Zmiany w kontenerach
│   ├── errors/                  # Log błędów
│   └── daily/                   # Dzienne podsumowania
│
├── state/                       # 📊 Bieżący stan
│   ├── SYSTEM-STATE.md          # Stan systemu
│   ├── ACTIVE-ISSUES.md         # Aktywne problemy
│   └── PENDING-TASKS.md         # Zadania do wykonania
│
└── .claude/                     # ⚙️ Konfiguracja Claude Code
    ├── settings.json            # Hooki i uprawnienia
    ├── skills/                  # Umiejętności domenowe
    │   ├── docker-installation/
    │   └── network-security/
    ├── commands/                # Slash commands
    └── agents/                  # Definicje agentów
```

---

## 🚀 Instalacja

### 1. Sklonuj repozytorium

```bash
git clone https://github.com/TWOJ_USER/linux-orchestrator.git ~/linux-orchestrator
cd ~/linux-orchestrator
```

### 2. Dostosuj do swojego systemu

```bash
# Edytuj CLAUDE.md - ustaw swoje domeny, IP itp.
nano CLAUDE.md

# Edytuj docs/DOCKER-REGISTRY.md - dodaj istniejące kontenery
nano docs/DOCKER-REGISTRY.md
```

### 3. Uruchom Claude Code w tym katalogu

```bash
cd ~/linux-orchestrator
claude
```

Claude automatycznie wczyta konfigurację z `CLAUDE.md`.

---

## 📋 Jak to działa?

### Przed instalacją kontenera Claude:

1. ✅ Sprawdza czy kontener już istnieje (`docker ps -a | grep`)
2. ✅ Sprawdza dokumentację (`DOCKER-REGISTRY.md`)
3. ✅ Weryfikuje dostępność portów
4. ✅ Instaluje z pełną dokumentacją

### Po instalacji:

1. 📝 Aktualizuje `DOCKER-REGISTRY.md`
2. 📝 Aktualizuje `NETWORK-MAP.md` (jeśli nowe porty)
3. 📝 Loguje zmianę do `logs/docker-changes/`

### Hooki bezpieczeństwa:

- ⚠️ Ostrzeżenie przy operacjach `rm`
- ⚠️ Ostrzeżenie przy modyfikacji firewall
- 🚫 Blokada niebezpiecznych poleceń (`rm -rf /`, `chmod 777`)
- 📝 Automatyczne logowanie poleceń Docker

---

## 🔒 Zasady bezpieczeństwa

| Zasada | Opis |
|--------|------|
| **Docker-first** | Wszystko w kontenerach, nie na hoście |
| **No root containers** | Kontenery nie uruchamiają się jako root |
| **Named networks** | Izolacja sieciowa, nie `host` mode |
| **Reverse proxy** | Porty przez Traefik, nie bezpośrednio |
| **Secrets management** | Hasła w Docker Secrets, nie w env |
| **Logging** | Każda operacja jest logowana |

---

## 📖 Dokumentacja

| Plik | Opis |
|------|------|
| [DOCKER-REGISTRY.md](docs/DOCKER-REGISTRY.md) | Lista wszystkich kontenerów z konfiguracją |
| [NETWORK-MAP.md](docs/NETWORK-MAP.md) | Mapa portów i sieci |
| [SECURITY-POLICIES.md](docs/SECURITY-POLICIES.md) | Polityki bezpieczeństwa |
| [EMERGENCY-RUNBOOK.md](docs/EMERGENCY-RUNBOOK.md) | Procedury na wypadek awarii |

---

## 🛠️ Skills Claude Code

### docker-installation
Automatyczna procedura instalacji kontenerów z dokumentacją.

### network-security
Procedury bezpieczeństwa sieciowego - firewall, porty, SSL.

---

## ⚡ Przykłady użycia

```
You: Zainstaluj Grafana do monitoringu

Claude: Sprawdzam czy Grafana już istnieje...
        docker ps -a | grep grafana → brak
        DOCKER-REGISTRY.md → status: NOT INSTALLED
        
        Instaluję Grafana...
        [tworzy docker-compose.yml]
        [uruchamia kontener]
        [aktualizuje dokumentację]
        
        ✅ Grafana zainstalowana
        - URL: https://grafana.twoja-domena.pl
        - Dokumentacja zaktualizowana
```

```
You: Otwórz port 8080 dla API

Claude: ⚠️ Sprawdzam bezpieczeństwo...
        
        CHECKLIST:
        - Czy można przez Traefik? → TAK, rekomenduję
        - Port 8080 → wolny
        
        Rekomenduję użycie reverse proxy zamiast 
        bezpośredniego otwarcia portu. Czy kontynuować?
```

---

## 📄 Licencja

MIT License - używaj jak chcesz.

---

## 👤 Autor

Konfiguracja stworzona dla [Numerika.ai](https://numerika.ai)

---

*Zainspirowane [OpenClaw Orchestra](https://github.com/example/openclaw-orchestra)*

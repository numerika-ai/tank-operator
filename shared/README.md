# SHARED - Wspólne zasoby

> Folder współdzielony między `claude-code-tank-operator` i `clawdbot-tank-operator`

---

## Cel

Centralne miejsce dla:
- **Logów** - wspólna historia zmian widoczna dla obu systemów
- **Registry** - lista zainstalowanych usług i modeli
- **State** - aktualny stan infrastruktury

---

## Struktura

```
shared/
├── README.md                 # Ten plik
├── CHANGELOG.md              # Główny log (pushowany na GitHub)
│
├── logs/
│   ├── commands/             # Historia poleceń
│   │   └── YYYY-MM-DD.log
│   ├── docker-changes/       # Zmiany Docker
│   │   └── YYYY-MM-DD.log
│   ├── errors/               # Błędy krytyczne
│   │   └── ERROR-LOG.md
│   └── daily/                # Podsumowania dzienne
│       └── YYYY-MM-DD.md
│
├── registry/
│   ├── DOCKER-REGISTRY.md    # Lista kontenerów
│   ├── MODEL-REGISTRY.md     # Lista modeli AI
│   └── INSTALL-HISTORY.md    # Historia instalacji
│
└── state/
    ├── SYSTEM-STATE.md       # Aktualny stan systemu
    └── ACTIVE-SESSIONS.md    # Aktywne sesje botów
```

---

## Format logów

```
[YYYY-MM-DD HH:MM] [SOURCE] [TAG] [STATUS] opis | szczegóły
```

### SOURCE (nowe pole!)
| Source | Znaczenie |
|--------|-----------|
| `CC` | Claude Code |
| `CB` | Clawdbot |
| `SYS` | System/Cron |

### Przykłady
```
[2024-01-15 14:32] [CC] [DCK] [OK] start:ollama | img=ollama:latest
[2024-01-15 14:35] [CB] [CTX] [OK] save:session_123 | tokens=4500
[2024-01-15 15:01] [SYS] [CLN] [OK] cleanup:weekly | freed=2.3GB
```

---

## Użycie

### Z Claude Code
```bash
# Logowanie
echo "[$(date +%Y-%m-%d\ %H:%M)] [CC] [TAG] [STATUS] opis" >> shared/CHANGELOG.md

# Sprawdzenie stanu
cat shared/registry/DOCKER-REGISTRY.md
```

### Z Clawdbot
```python
# Logowanie
with open("shared/CHANGELOG.md", "a") as f:
    f.write(f"[{datetime.now()}] [CB] [CTX] [OK] action | details\n")

# Odczyt stanu
with open("shared/registry/MODEL-REGISTRY.md") as f:
    models = f.read()
```

---

## Synchronizacja

```
ZASADA: Każdy zapis do shared/ musi być commitowany i pushowany

1. Zapis do pliku
2. git add shared/
3. git commit -m "log: [SOURCE] opis"
4. git push
```

> To zapewnia widoczność zmian z zewnątrz (GitHub)

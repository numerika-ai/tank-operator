# 🤖 CLAWDBOT TANK OPERATOR v1.0

> **Konfiguracja zarządzania pamięcią, kontekstem i raportowaniem dla Clawdbot**
>
> Wspólne zasoby z Claude Code w: `../shared/`

---

## 🖥️ ŚRODOWISKO

| Komponent | Specyfikacja |
|-----------|--------------|
| **Host** | Linux Infrastructure Orchestrator |
| **CPU** | AMD Ryzen 9 7900X (12C/24T) |
| **RAM** | 63.61 GB |
| **GPU** | NVIDIA RTX 3090 (24GB VRAM) |
| **Shared Logs** | `../shared/CHANGELOG.md` |

---

## 🎯 MISJA

**Cel główny:** Zarządzanie Clawdbotem jako asystentem AI z:
- **Pamięcią kontekstową** - zachowanie kontekstu między sesjami
- **Efektywnym tokenami** - optymalizacja zużycia context window
- **Raportowaniem** - logi widoczne na GitHub
- **Integracją** - współpraca z Claude Code przez shared folder

---

## 📜 FUNDAMENTALNE ZASADY

### 0. SHARED-FIRST
```
WSZYSTKIE logi → ../shared/CHANGELOG.md
WSZYSTKIE instalacje → ../shared/registry/
WSZYSTKIE stany → ../shared/state/

NIGDY nie twórz lokalnych logów - używaj shared!
```

### 1. CONTEXT MANAGEMENT
```
PRZED każdą odpowiedzią:
1. Sprawdź aktualny rozmiar kontekstu (tokens)
2. Jeśli >80% limitu → summarize old context
3. Jeśli >95% limitu → archive & start fresh
4. Zaloguj operacje kontekstowe w shared/CHANGELOG.md
```

### 2. TOKEN EFFICIENCY
```
- Używaj krótkich, zwięzłych odpowiedzi
- Nie powtarzaj informacji z kontekstu
- Kompresuj stare wiadomości do summary
- Monitoruj token usage per session
```

### 3. MEMORY PERSISTENCE
```
PRZED zakończeniem sesji:
1. Zapisz kluczowe fakty do persistent memory
2. Archiwizuj pełny kontekst (jeśli ważny)
3. Zaloguj [CB] [MEM] [OK] w CHANGELOG.md
```

### 4. LOGOWANIE (SHARED)
```
Format: [YYYY-MM-DD HH:MM] [CB] [TAG] [STATUS] opis | szczegóły

Tagi specyficzne dla Clawdbot:
- CTX = Context operations
- MEM = Memory/persistence
- TOK = Token management
- SES = Session management
- RPT = Reporting
```

---

## 📝 SYSTEM LOGÓW

### Lokalizacja
```
../shared/CHANGELOG.md          ← GŁÓWNY LOG (GitHub)
../shared/logs/commands/        ← Komendy
../shared/state/ACTIVE-SESSIONS.md ← Sesje Clawdbot
```

### Tagi Clawdbot

| Tag | Znaczenie | Przykład |
|-----|-----------|----------|
| `CTX` | Operacje kontekstowe | compress, summarize, clear |
| `MEM` | Pamięć trwała | save, load, archive |
| `TOK` | Zarządzanie tokenami | count, optimize, alert |
| `SES` | Zarządzanie sesjami | start, end, timeout |
| `RPT` | Raportowanie | daily, weekly, alert |
| `ERR` | Błędy | overflow, timeout, fail |

### Przykłady wpisów
```
[2024-01-15 14:32] [CB] [SES] [OK] start:user123 | tokens=0
[2024-01-15 14:45] [CB] [CTX] [OK] compress:user123 | 45000→12000 tokens
[2024-01-15 15:01] [CB] [TOK] [WARN] alert:user123 | 95% context used
[2024-01-15 15:02] [CB] [MEM] [OK] archive:user123 | file=session_123.json
[2024-01-15 15:03] [CB] [SES] [OK] end:user123 | total_tokens=52000
```

---

## 🧠 CONTEXT MANAGEMENT

### Limity

| Model | Context Window | Safe Limit (80%) | Critical (95%) |
|-------|----------------|------------------|----------------|
| Claude 3 | 200,000 | 160,000 | 190,000 |
| GPT-4 | 128,000 | 102,400 | 121,600 |
| Llama 2 | 4,096 | 3,277 | 3,891 |

### Procedury

#### Kompresja kontekstu (>80%)
```python
def compress_context(session):
    """
    1. Zachowaj: system prompt, ostatnie 5 wiadomości
    2. Podsumuj: starsze wiadomości w 1 paragraf
    3. Usuń: redundantne informacje
    4. Zaloguj: [CB] [CTX] [OK] compress
    """
    old_tokens = count_tokens(session.context)

    # Kompresja
    summary = summarize(session.context[:-5])
    session.context = [session.system_prompt, summary] + session.context[-5:]

    new_tokens = count_tokens(session.context)

    # Log
    log(f"[CB] [CTX] [OK] compress:{session.id} | {old_tokens}→{new_tokens} tokens")
```

#### Archiwizacja sesji (>95% lub timeout)
```python
def archive_session(session):
    """
    1. Zapisz pełny kontekst do pliku
    2. Wyodrębnij kluczowe fakty do memory
    3. Wyczyść kontekst
    4. Zaloguj: [CB] [MEM] [OK] archive
    """
    # Zapisz do pliku
    filename = f"sessions/{session.id}_{datetime.now()}.json"
    save_json(filename, session.context)

    # Wyodrębnij fakty
    facts = extract_key_facts(session.context)
    session.memory.update(facts)

    # Wyczyść
    session.context = [session.system_prompt]

    # Log
    log(f"[CB] [MEM] [OK] archive:{session.id} | file={filename}")
```

---

## 💾 MEMORY PERSISTENCE

### Struktura pamięci

```
clawdbot-tank-operator/
├── memory/
│   ├── users/                    # Per-user memory
│   │   └── {user_id}.json
│   ├── sessions/                 # Archived sessions
│   │   └── {session_id}_{date}.json
│   └── global/                   # Shared knowledge
│       └── facts.json
```

### Format user memory
```json
{
  "user_id": "user123",
  "created": "2024-01-01",
  "last_seen": "2024-01-15",
  "facts": [
    {"fact": "Prefers Polish language", "confidence": 0.95},
    {"fact": "Works with Docker", "confidence": 0.90}
  ],
  "preferences": {
    "language": "pl",
    "verbosity": "concise"
  },
  "session_count": 42,
  "total_tokens": 1250000
}
```

### Procedura zapisywania
```
PRZED zakończeniem sesji:
1. Wyodrębnij nowe fakty z konwersacji
2. Zaktualizuj user memory (merge, dedupe)
3. Zapisz session archive (jeśli istotna)
4. Zaloguj do shared/CHANGELOG.md
```

---

## 📊 RAPORTOWANIE

### Daily Report (automatyczny)
```
Lokalizacja: ../shared/logs/daily/YYYY-MM-DD.md

Zawartość:
- Total sessions
- Total tokens used
- Peak concurrent users
- Errors/warnings
- Top users by tokens
```

### Szablon daily report
```markdown
# Daily Report - YYYY-MM-DD

## Clawdbot Statistics

| Metryka | Wartość |
|---------|---------|
| Sessions | X |
| Total tokens | X |
| Avg tokens/session | X |
| Peak concurrent | X |
| Errors | X |

## Top Users
1. user_a - 50,000 tokens
2. user_b - 35,000 tokens
3. user_c - 20,000 tokens

## Incidents
- [HH:MM] [ERR] description

## Notes
- ...
```

### Weekly Report
```
KAŻDY poniedziałek:
1. Agreguj daily reports
2. Oblicz trendy (week-over-week)
3. Identyfikuj anomalie
4. Push do GitHub
```

---

## 🔧 INTEGRACJA Z CLAUDE CODE

### Shared Resources

| Zasób | Lokalizacja | Użycie |
|-------|-------------|--------|
| Logi | `../shared/CHANGELOG.md` | Append |
| Docker Registry | `../shared/registry/DOCKER-REGISTRY.md` | Read/Write |
| Model Registry | `../shared/registry/MODEL-REGISTRY.md` | Read/Write |
| System State | `../shared/state/SYSTEM-STATE.md` | Read |
| Sessions | `../shared/state/ACTIVE-SESSIONS.md` | Write |

### Komunikacja

```
Clawdbot → Claude Code:
- Aktualizuj ACTIVE-SESSIONS.md (aktywne sesje)
- Loguj do shared/CHANGELOG.md z tagiem [CB]
- Requestuj modele przez MODEL-REGISTRY.md

Claude Code → Clawdbot:
- Aktualizuje DOCKER-REGISTRY.md (dostępne kontenery)
- Aktualizuje MODEL-REGISTRY.md (załadowane modele)
- Aktualizuje SYSTEM-STATE.md (zasoby GPU/RAM)
```

### Procedura requestu modelu
```
1. Clawdbot sprawdza MODEL-REGISTRY.md
2. Jeśli model niedostępny:
   a. Dodaj wpis do kolejki w MODEL-REGISTRY.md
   b. Zaloguj [CB] [AI] [WARN] request:model_name
3. Claude Code wykrywa request i ładuje model
4. Claude Code aktualizuje MODEL-REGISTRY.md
5. Clawdbot może używać modelu
```

---

## 🚫 ZAKAZY

| Zakaz | Powód |
|-------|-------|
| Lokalne logi (poza shared/) | Brak widoczności |
| Ignorowanie limitów tokenów | Crash/overflow |
| Brak archiwizacji przed clear | Utrata danych |
| Hardcoded credentials | Security |
| Nielogowane operacje | Brak audytu |

---

## 📋 CHECKLIST

### Start sesji
- [ ] Zaloguj [CB] [SES] [OK] start
- [ ] Załaduj user memory (jeśli istnieje)
- [ ] Sprawdź dostępne modele w MODEL-REGISTRY.md
- [ ] Zainicjuj token counter

### Podczas sesji
- [ ] Monitoruj token usage
- [ ] Kompresuj przy 80%
- [ ] Archiwizuj przy 95%
- [ ] Loguj wszystkie operacje kontekstowe

### Koniec sesji
- [ ] Zapisz user memory
- [ ] Archiwizuj sesję (jeśli istotna)
- [ ] Zaloguj [CB] [SES] [OK] end
- [ ] Aktualizuj ACTIVE-SESSIONS.md

---

## 🔗 POWIĄZANE PLIKI

- **Shared CHANGELOG:** `../shared/CHANGELOG.md`
- **Docker Registry:** `../shared/registry/DOCKER-REGISTRY.md`
- **Model Registry:** `../shared/registry/MODEL-REGISTRY.md`
- **Active Sessions:** `../shared/state/ACTIVE-SESSIONS.md`
- **Claude Code Config:** `../claude-code-tank-operator/CLAUDE.md`

---

**Wersja:** 1.0.0
**Ostatnia aktualizacja:** {{DATE}}
**Właściciel:** Numerika

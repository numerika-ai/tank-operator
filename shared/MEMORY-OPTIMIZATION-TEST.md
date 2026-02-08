# Test Optymalizacji Pamięci — Wiki & Tank

## Data: 2026-02-08
## Autor: Wiki (Wiktoria Sterling)

---

## 1. Co zoptymalizowaliśmy

| Plik | Przed | Po | Zmiana |
|------|------:|---:|--------|
| AGENTS.md | 7869B | 1512B | -81% |
| SOUL.md | 1673B | 1673B | bez zmian |
| USER.md | 298B | 298B | bez zmian |
| TOOLS.md | 860B | 860B | bez zmian |
| IDENTITY.md | 337B | 337B | bez zmian |
| HEARTBEAT.md | 168B | 168B | bez zmian |
| **Total static** | **11205B** | **4848B** | **-57%** |

Wyekstrahowane pliki (ładowane on-demand, nie na start):
- `docs/agent/GROUP-CHAT-RULES.md` (682B)
- `docs/agent/HEARTBEAT-RULES.md` (730B)

---

## 2. Plan testów

### Test A: Baseline — pomiar kontekstu na start sesji

**Cel:** Zmierzyć ile tokenów zajmuje context na starcie nowej sesji.

**Metoda:**
1. Uruchom `/status` na świeżej sesji Wiki
2. Zanotuj: total tokens, context tokens, model
3. Powtórz na sesji Tank
4. Porównaj z wartościami sprzed optymalizacji (jeśli dostępne)

**Oczekiwany wynik:** Context na start < 5KB / ~1500 tokenów

**Jak zmierzyć:**
```
session_status → Usage section → input tokens na pierwszym turnie
```

### Test B: Lean loading — czy docs/ nie ładują się automatycznie

**Cel:** Potwierdzić że `docs/agent/*.md` NIE są ładowane na start, tylko on-demand.

**Metoda:**
1. Rozpocznij nową sesję
2. Zapytaj "Co wiesz o zasadach group chat?" — bez czytania pliku
3. Jeśli agent nie zna szczegółów → PASS (nie ładuje automatycznie)
4. Zapytaj "Przeczytaj docs/agent/GROUP-CHAT-RULES.md" → agent powinien załadować i znać

**Oczekiwany wynik:** Agent nie zna szczegółów bez explicit read, zna po read

### Test C: Bot-to-bot — czy optymalizacja nie zepsuła komunikacji

**Cel:** Potwierdzić że BOT2BOT protokół nadal działa po zmianach.

**Metoda:**
1. Wiki wysyła: `<@Tank> BOT2BOT: PING TEST-OPT`
2. Tank odpowiada: `BOT2BOT: ACK TEST-OPT`
3. Wiki (po 20s): `<@Tank> BOT2BOT: CMD TEST-OPT echo: memory optimized`
4. Tank: `BOT2BOT: DONE TEST-OPT memory optimized`

**Oczekiwany wynik:** Full roundtrip < 60s, brak missed messages

### Test D: Heartbeat — czy pusty HEARTBEAT.md = szybki OK

**Cel:** Potwierdzić że heartbeat turn nie marnuje tokenów.

**Metoda:**
1. Poczekaj na następny heartbeat (lub wymuś przez heartbeat prompt)
2. Zmierz: czas odpowiedzi, tokeny zużyte
3. Oczekiwany wynik: HEARTBEAT_OK w < 2s, < 100 tokenów

### Test E: Memory continuity — czy daily notes działają

**Cel:** Potwierdzić że agent czyta memory/YYYY-MM-DD.md na start.

**Metoda:**
1. Zapisz unikalne hasło w `memory/2026-02-08.md` (np. "testowe-hasło-kiwi-42")
2. Rozpocznij nową sesję
3. Zapytaj "jakie jest dzisiejsze testowe hasło?"
4. Agent powinien odpowiedzieć "kiwi-42" (z daily notes)

**Oczekiwany wynik:** Agent zna hasło z daily notes

---

## 3. Metryki sukcesu

| Metryka | Target | Jak mierzyć |
|---------|--------|-------------|
| Static context size | < 5KB | `wc -c` na plikach workspace |
| Start tokens | < 2000 | `session_status` po pierwszym turnie |
| Heartbeat cost | < 100 tokens | `session_status` po heartbeat |
| Bot-to-bot roundtrip | < 60s | Timestamp diff PING → DONE |
| Lean loading | docs/ nie loaded on start | Test B method |
| Memory continuity | Daily notes readable | Test E method |

---

## 4. Kto co robi

| Test | Executor | Reviewer |
|------|----------|----------|
| A: Baseline | Wiki + Tank (każdy u siebie) | Bartosz |
| B: Lean loading | Wiki | Tank |
| C: Bot-to-bot | Wiki (initiator) | Tank (responder) |
| D: Heartbeat | Wiki | Bartosz |
| E: Memory continuity | Wiki | Bartosz |

---

## 5. Wyniki (do uzupełnienia po testach)

### Test A: Baseline
- Wiki: _pending_
- Tank: _pending_

### Test B: Lean loading
- Wynik: _pending_

### Test C: Bot-to-bot
- Wynik: _pending_
- Roundtrip time: _pending_

### Test D: Heartbeat
- Wynik: _pending_
- Tokens: _pending_

### Test E: Memory continuity
- Wynik: _pending_

---

## 6. Następne kroki (po testach)

1. Jeśli wszystko PASS → zamknąć T-20260208-03 jako verified
2. Jeśli Test A pokazuje > 2000 tokenów → dalsze cięcia (SOUL.md, TOOLS.md)
3. Jeśli Test C fails → debug bot-to-bot timing
4. Rozważyć: heartbeat interval 1h → 6h (mniej idle inference)
5. Tank: zastosować te same optymalizacje na swojej instancji

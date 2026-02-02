# ACTIVE SESSIONS

> Aktywne sesje Clawdbot i ich konteksty

---

## Sesje Clawdbot

| Session ID | User | Tokens | Context | Started | Last Activity |
|------------|------|--------|---------|---------|---------------|
| - | - | - | - | - | - |

---

## Limity

| Parametr | Wartość | Uwagi |
|----------|---------|-------|
| Max tokens/session | 100,000 | Configurable |
| Max concurrent sessions | 10 | RAM dependent |
| Context window | 200,000 | Model dependent |
| Session timeout | 30 min | Idle timeout |

---

## Memory Management

### Strategia
```
1. Nowa sesja → alokuj context buffer
2. Przekroczenie 80% tokens → summarize old context
3. Przekroczenie 95% tokens → archive & start fresh
4. Sesja idle >30min → persist to disk & free RAM
```

### Persisted Sessions

| Session ID | User | Tokens | Persisted At | File |
|------------|------|--------|--------------|------|
| - | - | - | - | - |

---

## Statystyki

| Metryka | Dzisiaj | Tydzień | Miesiąc |
|---------|---------|---------|---------|
| Total sessions | - | - | - |
| Total tokens | - | - | - |
| Avg tokens/session | - | - | - |
| Peak concurrent | - | - | - |

---

## Ostatnia aktualizacja

- **Data:** -
- **Przez:** Clawdbot

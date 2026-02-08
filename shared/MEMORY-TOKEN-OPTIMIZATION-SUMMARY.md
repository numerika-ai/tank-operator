# Podsumowanie: OpenClaw Memory & Token Optimization

## Data: 2026-02-08
## Autorzy: Wiki + Tank (review)
## Źródło: numerika-ai/openclaw-memory-token-optimization

---

## Kontekst

Analiza dwóch dokumentów optymalizacyjnych:
1. `openclaw-bible-optymalizacja-v2.md` — fleet 4 agentów na GPU/Ollama
2. `openclaw-memory-token-optimization.md` — architektura pamięci, Knowledge Graph, Token Router

Nasz setup: Wiki (Claude Opus, cloud API) + Tank (GPT-5.2, cloud API + RTX 3090 idle)

---

## 3 warstwy z dokumentu

### Warstwa 1: Structured Memory Engine (Knowledge Graph)
- Encje + relacje nad plikami MD (SQLite)
- Hybrid search: vector (50%) + BM25 (20%) + graph walk (30%)
- Tiered memory: hot/warm/cold/permanent

### Warstwa 2: Context Orchestrator
- Adaptacyjne progi rotacji per typ zadania
- Rotacja sesji zamiast kompakcji
- Token Budget Allocation (strefy budżetowe)

### Warstwa 3: Token Router
- Klasyfikacja zapytań (trivial→mały model, complex→duży)
- Dynamic Skill Loading (2-5 skilli zamiast 30)
- Soft escalation (mały model → duży przy niepewności)

---

## Co wdrożyliśmy już (T-20260208-03)

| Optymalizacja | Status | Efekt |
|---|---|---|
| Prompt layering (static first) | ✅ DONE | Uporządkowana kolejność plików |
| AGENTS.md lean | ✅ DONE | 7.8KB → 1.5KB (-81%) |
| Docs on-demand | ✅ DONE | Group/heartbeat rules wyekstrahowane |
| Total static context | ✅ DONE | 11.2KB → 4.8KB (-57%) |

---

## Co wdrażamy następne (uzgodnione Wiki + Tank)

### Priorytet 1: Dynamic Skill Loading
- **Co:** Nie ładować wszystkich SKILL.md na start, tylko relevantne
- **Jak:** Twarda reguła w AGENTS.md: "Load skills on-demand, not at boot"
- **Efekt:** ~10-15K tokenów mniej per tura (przy wielu skillach)
- **Złożoność:** Niska (reguła behawioralna, nie zmiana kodu)

### Priorytet 2: Rotacja / Handoff
- **Co:** Przy zamykaniu sesji tworzyć HANDOFF.md z kontekstem
- **Jak:** `shared/handoff/latest.md` — co robiliśmy, co następne, blockery
- **Efekt:** Lepsza kontynuacja pracy niż kompakcja
- **Złożoność:** Niska (plik MD, konwencja)

### Priorytet 3: Tiered Memory (hot/warm/cold)
- **Co:** Rozdzielić pamięć na warstwy dostępu
- **Jak:**
  - Hot: `shared/state/taskboard.*` + current task
  - Warm: `memory/YYYY-MM-DD.md` (recent daily notes)
  - Cold: `MEMORY.md` (curated, main session only)
- **Efekt:** Mniej niepotrzebnego kontekstu
- **Złożoność:** Niska (konwencja + reguły w AGENTS.md)

---

## Co odkładamy (i dlaczego)

| Propozycja | Powód odłożenia |
|---|---|
| Knowledge Graph (SQLite) | Overengineering na 2 agentów. Wrócimy gdy fleet > 4 |
| Token Router (multi-model) | Nie mamy małych modeli lokalnie (cloud API) |
| Multi-agent shared graph | 2 agentów, nie 4 na jednym GPU |
| Fine-tuning ekstrakcji encji | Brak danych, brak potrzeby |
| GPU monitoring/tiering | Tank nie hostuje modeli (jeszcze) |
| Adaptive rotation thresholds | OpenClaw compaction działa OK na cloud API |
| Token Budget Allocation | Zarządzane przez provider (Anthropic/OpenAI) |

---

## Co rozważymy w przyszłości

| Propozycja | Kiedy | Trigger |
|---|---|---|
| Knowledge Graph | Gdy fleet > 4 agentów | Dodanie nowych agentów |
| Token Router | Gdy Tank zacznie hostować modele na RTX 3090 | Ollama/vLLM setup |
| GPU monitoring | Gdy lokalne inference | Modele na GPU |
| Adaptive rotation | Gdy kompakcja zacznie tracić kontekst | Degradacja jakości |
| Watchdog systemowy | Gdy agenty działają 24/7 | Production deployment |

---

## Metryki sukcesu

| Metryka | Przed | Cel | Jak mierzyć |
|---|---|---|---|
| Static context | 11.2KB | 4.8KB | `wc -c` plików workspace |
| Skills w prompt | Wszystkie | 2-5 relevantnych | Obserwacja |
| Kontynuacja po sesji | Compaction | HANDOFF.md + taskboard | Jakość pierwszej odpowiedzi |
| Memory trafność | ~60% | > 85% | Manual eval top-5 wyników |

---

## Consensus Wiki + Tank

Obaj zgadzamy się na:
1. Nie overengineerować — jesteśmy 2 agentów na cloud API, nie fleet na GPU
2. Konwencje > kod — reguły behawioralne dają 80% efektu za 20% wysiłku
3. Iterować — wdrożyć małe zmiany, zmierzyć, potem decydować o kolejnych
4. Knowledge Graph = przyszłość, nie teraz
5. Dynamic Skill Loading = najniższy koszt, najwyższy ROI

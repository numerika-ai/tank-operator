# Projekt: openclaw-memory-optimizer (Skill)

## Cel
Kompletny skill OpenClaw do optymalizacji pamięci i tokenów. Modułowa architektura — każdy moduł niezależnie testowalny.

---

## Architektura Skilla

```
openclaw-memory-optimizer/
├── SKILL.md                          # Główny entry point
├── references/
│   ├── architecture.md               # Przegląd architektury
│   └── testing-guide.md              # Jak testować każdy moduł
├── scripts/
│   ├── module-1-context-audit.sh     # Moduł 1: audit
│   ├── module-2-lean-loader.sh       # Moduł 2: lean loading
│   ├── module-3-skill-router.py      # Moduł 3: skill routing
│   ├── module-4-handoff.sh           # Moduł 4: handoff
│   └── module-5-memory-tier.py       # Moduł 5: tiered memory
└── assets/
    ├── templates/
    │   ├── HANDOFF.template.md       # Template handoff
    │   ├── AGENTS-LEAN.template.md   # Template lean AGENTS.md
    │   └── TASK-STATE.template.md    # Template task state
    └── examples/
        ├── before-after.md           # Przykłady optymalizacji
        └── metrics.md                # Jak mierzyć efekty
```

---

## Zasady bezpieczeństwa (z review Tanka)

1. **Każdy moduł: `--dry-run` (domyślne) + `--apply`** — bez jawnego `--apply` nic nie modyfikuje plików
2. **Interfejsy wejścia jasno zdefiniowane** — moduł 3 wymaga skills.json, moduł 4 wymaga last_messages.json
3. **Lean Loader scope: TYLKO workspace files** — nie grzebie w repo/taskboard/shared/

## 5 Modułów (niezależnych)

### Moduł 1: Context Audit (`module-1-context-audit`)
**Co robi:** Skanuje workspace i raportuje rozmiar każdego pliku ładowanego na start.
**Input:** Ścieżka workspace
**Output:** Raport z rozmiarami, % kontekstu, rekomendacje cięć
**Test:** `./module-1-context-audit.sh /path/to/workspace` → raport MD
**Zależności:** Brak (standalone)

### Moduł 2: Lean Loader (`module-2-lean-loader`)
**Co robi:** Automatycznie rozbija duże pliki workspace na lean + docs/
**Input:** Plik do optymalizacji (np. AGENTS.md)
**Output:** Lean wersja + wyekstrahowane pliki w docs/
**Test:** `./module-2-lean-loader.sh AGENTS.md` → AGENTS.md slim + docs/agent/*.md
**Zależności:** Brak (standalone)

### Moduł 3: Skill Router (`module-3-skill-router`)
**Co robi:** Klasyfikuje zapytanie i zwraca listę relevantnych skilli (zamiast ładować wszystkie)
**Input:** Tekst zapytania + lista zainstalowanych skilli (name + description)
**Output:** Top 3-5 relevantnych skilli
**Algorytm:** Keyword matching + TF-IDF na description (bez LLM)
**Test:** `python3 module-3-skill-router.py "jak zrobić git push" skills.json` → `[github, coding-agent]`
**Zależności:** Python 3 (stdlib only)

### Moduł 4: Handoff Generator (`module-4-handoff`)
**Co robi:** Generuje HANDOFF.md z aktualnego stanu sesji
**Input:** Ostatnie N wiadomości + aktywne taski
**Output:** `shared/handoff/latest.md` z sekcjami: Context, Done, Next, Blockers
**Test:** `./module-4-handoff.sh` → plik handoff
**Zależności:** Brak (standalone)

### Moduł 5: Memory Tier Manager (`module-5-memory-tier`)
**Co robi:** Klasyfikuje wpisy pamięci na hot/warm/cold i raportuje co ładować
**Input:** Katalog memory/ + MEMORY.md
**Output:** Raport tier assignment + rekomendacja co ładować na start
**Algorytm:** importance × recency scoring (bez LLM)
**Test:** `python3 module-5-memory-tier.py /path/to/memory/` → raport
**Zależności:** Python 3 (stdlib only)

---

## Plan wdrożenia (fazy)

### Faza 1: Fundament (Moduł 1 + 2)
- Stwórz scripts: context-audit + lean-loader
- Stwórz templates: AGENTS-LEAN, HANDOFF
- Przetestuj na workspace Wiki i Tank
- **Deliverable:** Działający audit + auto-refactor

### Faza 2: Routing (Moduł 3)
- Stwórz skill-router z keyword matching
- Zbierz listę skilli z OpenClaw config
- Przetestuj na 10 przykładowych zapytaniach
- **Deliverable:** Działający router bez LLM

### Faza 3: Handoff (Moduł 4)
- Stwórz generator handoff
- Zdefiniuj format HANDOFF.md
- Przetestuj: zamknij sesję → otwórz nową → sprawdź kontynuację
- **Deliverable:** Automatyczny handoff przy rotacji

### Faza 4: Memory Tiers (Moduł 5)
- Stwórz tier manager z importance × recency
- Zdefiniuj progi hot/warm/cold
- Przetestuj na realnych plikach memory/
- **Deliverable:** Inteligentne ładowanie pamięci

### Faza 5: Integracja + SKILL.md
- Połącz moduły w spójny skill
- Napisz SKILL.md z instrukcjami
- Package jako .skill
- **Deliverable:** Gotowy skill do instalacji

---

## Podział pracy

| Moduł | Owner | Reviewer |
|---|---|---|
| 1: Context Audit | Wiki | Tank |
| 2: Lean Loader | Wiki | Tank |
| 3: Skill Router | Tank (Python na VM) | Wiki |
| 4: Handoff | Wiki | Tank |
| 5: Memory Tier | Tank (Python na VM) | Wiki |
| SKILL.md + packaging | Wiki | Tank + Bartosz |

---

## Metryki sukcesu per moduł

| Moduł | Metryka | Target |
|---|---|---|
| 1: Audit | Generuje raport w < 5s | ✓ raport MD z rekomendacjami |
| 2: Lean | Redukcja pliku > 50% | AGENTS.md 7.8KB → < 2KB |
| 3: Router | Accuracy > 80% na 10 testów | Top-3 zawiera właściwy skill |
| 4: Handoff | Kontynuacja bez utraty kontekstu | Nowa sesja zna stan poprzedniej |
| 5: Tiers | Redukcja memory loaded on start > 40% | Ładuje tylko hot tier |

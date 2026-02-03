# Tank Operator — Orchestrator Concept (Workflow + Virtualization)

> **Cel**: zbudować skalowalny, bezpieczny system „orchestrator + workers” do realizacji zadań w wielu projektach (na start: **Crypto** i **Numerika Marketing/Courses**), z audytem i łatwym odtworzeniem (recovery).

## 0) Kontekst (co chcemy osiągnąć)

- **Bartosz** chce docelowo mieć kilka niezależnych agentów/modeli (4–5+) uruchomionych w izolacji.
- Jeden agent (Orchestrator) ma zarządzać backlogiem i delegować pracę do workerów.
- System ma mieć:
  - **kanban / UI** do przeglądu pracy,
  - **API** do zarządzania zadaniami i artefaktami,
  - możliwość dołączania **dokumentów/załączników** do zadań,
  - mechanizm **blocked / approval** (gdy potrzebna decyzja człowieka),
  - pełny **audit trail** (kto/co/kiedy).

## 1) Najważniejsze zasady architektury

### 1.1 Orchestrator + Work Queue + Workers
- **Orchestrator** (jedna instancja) jest „mózgiem organizacyjnym”:
  - tworzy zadania, priorytetyzuje, rozwiązuje zależności,
  - dispatchuje zadania do workerów,
  - zbiera wyniki i zamyka zadania,
  - eskaluje decyzje do Bartosza.

- **Workers** (N instancji) są „wykonawcami”:
  - biorą zadania z kolejki,
  - wykonują w ramach minimalnych uprawnień,
  - raportują wynik z powrotem.

**Klucz**: workerzy **nie komunikują się bezpośrednio między sobą** „na dziko”. Komunikacja idzie przez orchestrator/API/kolejkę.

### 1.2 Separacja: „state w DB” + „audit i artefakty w repo”
- **DB** trzyma „żywy stan”: zadania, statusy, zależności, metryki, kolejki.
- Repo (`shared/`) trzyma:
  - raporty MD,
  - dokumentację projektów,
  - pliki/załączniki,
  - log audytu (wspólny `shared/CHANGELOG.md`).

To daje jednocześnie: skalowalność (DB) + rekonstrukcję/wersjonowanie (git).

## 2) Dwa projekty (różne wymagania)

### 2.1 Projekt: Crypto (scraping → kod → testy)
**Charakter**: data/engineering. GUI nie jest wymagane.

Typy workerów (VM):
- `worker-crypto-data` — scraping/orderbook ingest
- `worker-crypto-dev` — kodowanie, testy
- `worker-crypto-backtest` — backtesting, symulacje

**Uwaga bezpieczeństwa (klucze giełd / API):**
- klucze nie powinny lądować u workerów.
- rekomendacja: osobna VM/usługa **Exchange Proxy**:
  - przechowuje sekrety,
  - wystawia ograniczone endpointy (least privilege),
  - loguje każde użycie,
  - ma rate limits + kill switch.

Na start: **paper trading/sandbox**.

### 2.2 Projekt: Numerika Marketing / Kursy
**Charakter**: research, treści, grafika, praca z web.

Tu przydaje się warstwa GUI dla workerów:
- `worker-mkt-research` — źródła i research
- `worker-mkt-copy` — copywriting/outlines
- `worker-mkt-design` — grafika (GUI)
- `worker-mkt-browser` — normalna przeglądarka (headed) w GUI

GUI w VM: desktop (np. XFCE) + RDP/VNC (preferencyjnie przez Tailscale).

**Uwaga**: automatyzacje muszą respektować ToS serwisów. „Udawanie człowieka” w sensie obejścia anty-botów to osobny temat i wymaga ostrożności.

## 3) Izolacja i bezpieczeństwo (recommended baseline)

### 3.1 Model wdrożenia
- **Każdy worker i orchestrator** w osobnej VM.
- Brak sudo dla procesów agentów.
- Minimalne uprawnienia + brak mountów do hosta.

### 3.2 Dostęp: LAN vs Tailscale vs „internet”
- **LAN**: dostęp tylko lokalnie.
- **Tailscale**: bezpieczny zdalny dostęp bez wystawiania portów.

**Rekomendacja**:
- LAN jako domyślne środowisko.
- Tailscale jako jedyny zdalny dostęp (MFA + ACL).
- **Nie wystawiać** RDP/VNC/Proxmox panel na publiczny internet.

### 3.3 Cloudflare (opcjonalnie)
Możliwe jest użycie Cloudflare (np. Tunnel) dla wybranych usług UI/API, ale:
- zwiększa złożoność,
- przenosi część zaufania na third-party,
- wymaga bardzo ostrego scope i polityk.

Na start: Tailscale + ACL jest prostsze i bezpieczniejsze.

## 4) Approval / Blocked / Human-in-the-loop

W systemie muszą istnieć zdarzenia typu:
- `proposal` (worker proponuje zmianę / instalację / akcję ryzykowną)
- `approval_required` (orchestrator prosi Bartosza)
- `approved` / `rejected`

Przykłady akcji wymagających approval:
- instalacje pakietów,
- uruchomienie tradingu na realnych kluczach,
- zmiana reguł firewalla,
- dostęp do kont mailowych.

## 5) Dane, dokumenty, artefakty

Załączniki do zadań:
- pliki w `shared/projects/<projectId>/docs/`
- linki jako metadane w DB (URL, opis, źródło)
- raporty generowane do `shared/projects/<projectId>/reports/`

## 6) UI / Kanban / API (warianty)

### UI
- **Canvas** (w ekosystemie OpenClaw) — szybka integracja, mniej „zewnętrznej” infrastruktury.
- **Web app na 127.0.0.1** — pełna kontrola, łatwe rozszerzenia.

### API
Lokalny REST (127.0.0.1), np.:
- `GET /projects`
- `GET /projects/:id/tasks`
- `POST /projects/:id/tasks`
- `PATCH /projects/:id/tasks/:taskId`
- `POST /projects/:id/tasks/:taskId/attachments`

## 7) Otwarte pytania (do decyzji)

### Architektura
1) **Orchestrator**: jeden wspólny dla obu projektów, czy po jednym per projekt?
2) DB: start SQLite czy od razu Postgres?
3) Kolejka: „DB queue” czy osobny broker (np. Redis/RabbitMQ) w kolejnej iteracji?

### Bezpieczeństwo
4) Jakie minimalne ACL w Tailscale dla:
   - laptop → proxmox UI
   - laptop → VM marketing (RDP)
   - orchestrator → workers API
5) Czy Cloudflare ma być w ogóle w scope v1 (czy dopiero po audycie)?

### Operacje
6) Jak robimy backup/restore (git + tar + checksums vs restic do NAS)?
7) Jak rozdzielamy środowiska: dev/stage/prod?

### Crypto
8) Czy startujemy w paper trading na długo, czy przewidujemy szybkie wejście na real keys?
9) Jakie limity ryzyka są nienegocjowalne (max drawdown, max position, kill switch)?

### Numerika
10) Jakie narzędzia GUI są „must have” (Canva/Figma/CapCut/etc.)?

## 8) Rekomendacja v1 (szybko, a dobrze)

- 1 orchestrator VM (wspólny),
- workers VM per rola/projekt,
- DB: SQLite na start,
- UI: web app lokalnie (127.0.0.1) lub Canvas,
- zdalny dostęp: Tailscale + ACL,
- brak ekspozycji portów na internet,
- approval workflow od pierwszego dnia.

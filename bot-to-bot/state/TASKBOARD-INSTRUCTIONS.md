# TASK BOARD — instrukcja (Wiki ↔ Tank ↔ Bartosz)

Ten dokument opisuje **protokół współpracy** między botami (Wiki/Tank) oraz człowiekiem (Bartosz) w ramach jednego kanału Discord.

## Cel
- **Repo (pliki)** = źródło prawdy i audyt.
- **Discord** = UI i szybki podgląd.
- Boty nie odpowiadają na każdą wiadomość — reagują **tylko na jawne wywołania** (mention-only) i/lub zdarzenia w kolejce.

## Kanał i identyfikatory
- Serwer: Numerika.ai
- Kanał: `#ogólny` (ID: `1469910700427182215`)
- Tank bot ID: `1469925937582833716`
- Wiki bot ID: `1469924952709795851`

## Tryb Discord (anty-hałas)
- `requireMention=true` (mention-only): bot reaguje tylko na prawdziwe `@mention`.
- Dodatkowo włączony jest **cooldown/collect**: odpowiedzi mogą być zebrane i wysłane po chwili ciszy (żeby uniknąć pętli bot↔bot).

### Prawdziwy mention
- Poprawny mention ma postać: `<@ID>` (np. `<@1469925937582833716>`)
- W praktyce: wpisz `@Ta…` i **kliknij bota z listy**.

## Pliki TASK BOARD (repo)
Źródło prawdy dla botów + audyt zmian:

- `shared/state/taskboard.tasks.json`
  - Snapshot aktualnego stanu wszystkich zadań (do renderowania, restartów, podglądu).
- `shared/state/taskboard.events.jsonl`
  - **Kolejka zdarzeń** + dziennik audytowy (append-only).
- `shared/state/taskboard.md`
  - Widok "dla Bartosza" (czytelny, może być generowany z JSON).

### Dlaczego pollujemy events.jsonl (a nie cały tasks.json)
- Czytamy tylko dopiski (tańsze i prostsze).
- Naturalny audyt "kto/co zrobił".
- Mniej konfliktów i ryzyka nadpisania stanu.

## Statusy zadań
Dozwolone statusy:
- `NEW` / `PLAN` / `REVIEW` / `AGREED` / `DOING` / `DONE` / `BLOCKED`

Definicja kluczowa:
- `AGREED` = obie strony (Wiki i Tank) potwierdziły plan (pole `agreedBy` zawiera `wiki` i `tank`).

## Handshake (uzgadnianie wersji)
Wspólny, powtarzalny schemat:

1) **PLAN** (zwykle Wiki)
   - `[T-...][PLAN v1] …`
   - ping do drugiej strony o review

2) **REVIEW** (drugi bot)
   - `[T-...][REVIEW] OK / zmiany / ryzyka`

3) **AGREED** (Wiki publikuje final)
   - `[T-...][AGREED v2] final plan …`

Dopiero po `AGREED` przechodzimy do `DOING`.

## Event log (events.jsonl) — format i typy
Każda linia w `taskboard.events.jsonl` to **jeden JSON** (JSONL).

### Minimalny schemat
```json
{"id":"E-...","ts":"2026-02-08T18:00:00Z","taskId":"T-20260208-01","actor":"wiki|tank|bartosz","type":"create|plan|review|agree|status|comment","message":"...","data":{}}
```

Rekomendowane pola:
- `id`: unikalne ID eventu (np. `E-<timestamp>-<rand>`)
- `ts`: ISO time (UTC)
- `taskId`: ID taska
- `actor`: `wiki|tank|bartosz`
- `actorId`: opcjonalnie ID użytkownika/bota (np. Discord user id)
- `type`: typ zdarzenia
- `message`: krótki opis
- `data`: opcjonalny payload (np. `statusFrom/statusTo`, `planVersion`, `links`)

Pola "warto dodać" (żeby uniknąć pętli, dubli i problemów z audytem):
- `replyTo`: ID eventu, na który odpowiadasz (dla request/response)
- `channelId`: ID kanału Discord, w którym padła prośba (tu: `1469910700427182215`)
- `source`: np. `discord` | `repo` | `manual`
- `dedupeKey`: string do deduplikacji (np. `taskId:type:planVersion`)
- `rev`: numer rewizji snapshotu tasków, który był aktualny w momencie eventu
- `severity`: `info|warn|error` (opcjonalnie)

### Typy zdarzeń (minimum)
- `create` — utworzenie taska
- `plan` — publikacja planu
- `review` — review do planu
- `agree` — potwierdzenie (dopisz do `agreedBy`)
- `status` — zmiana statusu
- `comment` — notatka

### Typy zdarzeń (RPC bot↔bot — rekomendowane)
**Request (prośby o akcję):**
- `request.plan`
- `request.review`
- `request.execute`
- `request.status`
- `request.clarify`

**Response (odpowiedzi):**
- `response.plan`
- `response.review`
- `response.execute`
- `response.clarify`

Zasada: event `response.*` powinien mieć `replyTo` wskazujące na event `request.*`.

## Polling (Wiki)
Wiki powinna działać jak procesor kolejki:

1) Co **60s** sprawdza `taskboard.events.jsonl` od ostatniego offsetu.
2) Bierze nowe eventy.
3) Reaguje tylko na te typy, które wymagają akcji (zwykle `request.*`).
4) Dopisuje swoje odpowiedzi jako nowe eventy (append-only) (`response.*` z `replyTo`).

> Uwaga: jeśli uznacie, że polling jest zbędny, alternatywa to "push": Tank po dopisaniu eventu wysyła na Discordzie krótki ping `@Wiki EVENT: ...`.

## Krótki stream na Discordzie (podgląd dla Bartosza)
Żeby Bartosz miał podgląd „co się dzieje", ale bez ściany tekstu:

- Każde dopisanie eventu do `taskboard.events.jsonl` powinno skutkować **jedną linijką** na Discordzie (w #ogólny albo w wątku TASK BOARD):
  - format: `TB + <type> <taskId> (<actor>)` + 3–8 słów opisu
  - przykład: `TB + request.review T-20260208-01 (wiki): sprawdź plan v2`

Zasady anty-spam:
- Tylko dla eventów `request.*`, `response.*`, `status`, `agree` (pomijamy drobne `comment`).
- Jeśli wpadnie kilka eventów naraz: wysłać **jedną** linijkę zbiorczą (tu pomaga cooldown/collect na Discordzie).

## Rekomendowany podział ról
- **Wiki**: koordynacja, aktualizacja taskboard (events + tasks snapshot + MD view)
- **Tank**: wykonanie techniczne + raporty `DONE/BLOCKED` z dowodami/logami
- **Bartosz**: priorytety i decyzje biznesowe

## Quickstart (pierwszy task)
1) Bartosz lub Wiki tworzy task: `T-YYYYMMDD-01`.
2) Wiki dopisuje event `create` i `plan`.
3) Tank dopisuje event `review`.
4) Wiki dopisuje `agree` + status `AGREED`.
5) Owner zmienia na `DOING` i wykonuje.
6) Po zakończeniu: event `status` → `DONE`.

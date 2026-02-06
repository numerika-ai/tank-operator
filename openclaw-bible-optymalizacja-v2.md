# OpenClaw Bible — Optymalizacja Fleetu Agentów v2.0

## Stan na: 7 lutego 2026

---

## 1. Architektura Promptu — Maksymalizacja Cache Hit Rate

### 1.1 Problem

Każdy agent ładuje przy starcie sesji: SOUL.md + PROTOCOL.md + USER.md + security rules + TASK_STATE.md + HANDOFF.md. Przy czterech agentach (Orchestrator, Developer, Researcher, Admin) to czterokrotne przetwarzanie w dużej mierze identycznego contentu. Ollama od wersji 0.5+ wspiera natywny prompt caching — cachedowane prefiksy przyspieszają first-token latency o 40-60%, ale tylko jeśli statyczny content jest **zawsze na początku** system promptu.

### 1.2 Zasada: Static First, Dynamic Last

Struktura system promptu **każdego agenta** musi wyglądać tak:

```
┌─────────────────────────────────────────────┐
│  WARSTWA 1: SOUL.md (identyczna per agent)  │  ← CACHE HIT (stabilna)
│  Core principles, values, security rules    │
├─────────────────────────────────────────────┤
│  WARSTWA 2: PROTOCOL.md (identyczna)        │  ← CACHE HIT (stabilna)
│  Memory rules, handoff, rotacja, rate limits│
├─────────────────────────────────────────────┤
│  WARSTWA 3: ROLE.md (per agent, stabilna)   │  ← CACHE HIT (zmienia się rzadko)
│  Rola agenta, dozwolone narzędzia, sandbox  │
├─────────────────────────────────────────────┤
│  WARSTWA 4: USER.md (stabilna)              │  ← CACHE HIT (zmienia się rzadko)
│  Kontekst użytkownika, cele, metryki        │
├─────────────────────────────────────────────┤
│  WARSTWA 5: TASK_STATE.md (dynamiczna)      │  ← BEZ CACHE (zmienia się co sesję)
│  Aktualny stan zadania, faza, plan          │
├─────────────────────────────────────────────┤
│  WARSTWA 6: HANDOFF.md (dynamiczna)         │  ← BEZ CACHE (zmienia się co sesję)
│  Kontekst z poprzedniej sesji               │
├─────────────────────────────────────────────┤
│  WARSTWA 7: memory/YYYY-MM-DD.md            │  ← BEZ CACHE (daily notes)
│  Notatki z dnia, jeśli istnieją             │
└─────────────────────────────────────────────┘
```

### 1.3 Dodaj do SOUL.md każdego agenta

```markdown
## PROMPT STRUCTURE RULE

System prompt MUSI być zorganizowany w następującej kolejności:
1. SOUL.md (wartości, zasady — NIGDY nie modyfikuj w trakcie sesji)
2. PROTOCOL.md (procedury — NIGDY nie modyfikuj w trakcie sesji)
3. ROLE.md (definicja roli — modyfikuj tylko przy restrukturyzacji)
4. USER.md (kontekst użytkownika — modyfikuj rzadko)
5. TASK_STATE.md (stan zadania — dynamiczny, aktualizuj często)
6. HANDOFF.md (przekazanie — dynamiczny, generowany automatycznie)
7. Daily notes (opcjonalne — ładuj on-demand przez memory_search())

ZASADA: Warstwy 1-4 to "frozen prefix". Nie modyfikuj ich w trakcie sesji.
Warstwy 5-7 to "hot suffix". Aktualizuj je aktywnie.
Ta struktura maksymalizuje cache hit rate w Ollama/LLM inference.
```

### 1.4 Konfiguracja Ollama dla cache

```json5
// Dodaj do konfiguracji Ollama (lub parametrów modelu)
{
  "num_ctx": 131072,        // Pełne okno kontekstowe GPT-120B
  "num_keep": -1,           // Zachowaj cały system prompt w KV cache
  "cache_type": "q8_0",     // Skwantyzowany cache (oszczędza VRAM)
  "num_predict": 4096       // Max tokens na odpowiedź
}
```

---

## 2. Event-Driven Health Check (zamiennik Heartbeat)

### 2.1 Problem z heartbeat

Domyślny heartbeat OpenClaw odpytuje model co X minut — nawet gdy agent jest idle. Przy czterech agentach na jednym GPU to ciągłe obciążenie inference bez żadnej wartości. Guide ScaleUP sugeruje przeniesienie heartbeatu na Ollama — to krok w dobrą stronę, ale niewystarczający.

### 2.2 Rozwiązanie: Event-Driven Status Reporting

Zamiast periodycznego heartbeatu, agent raportuje status **tylko gdy coś się zmienia**.

#### Triggery raportowania:

| Trigger | Kanał | Priorytet |
|---|---|---|
| Zmiana stanu (idle → working → blocked → error) | Slack #alerts | NORMAL |
| Ukończenie taska | Slack #{agent-channel} + Todoist update | NORMAL |
| Błąd krytyczny | Slack #alerts + Telegram (do Ciebie) | HIGH |
| Przekroczenie progu kontekstu (70%+) | Slack #alerts | HIGH |
| Explicit ping od Orchestratora | Odpowiedź na kanale źródłowym | IMMEDIATE |
| Latency > 30s (degradacja) | Slack #alerts | HIGH |
| Brak aktywności > 4h (watchdog) | Slack #alerts | LOW |

#### Konfiguracja OpenClaw — wyłączenie heartbeat + watchdog

```json5
// ~/.openclaw-{agent}/openclaw.json
{
  "heartbeat": {
    "every": "0",           // WYŁĄCZONY — zero idle inference
    "model": "none"
  },
  
  // Zastępujemy watchdogiem na poziomie systemu (nie LLM)
  // Patrz sekcja 2.3
}
```

### 2.3 Systemowy Watchdog (bez inference)

Zamiast LLM-owego heartbeatu, użyj prostego skryptu bash/Python sprawdzającego czy daemon żyje:

```bash
#!/bin/bash
# /opt/openclaw/watchdog.sh
# Uruchamiany przez systemd timer co 30 minut

AGENTS=("orchestrator:3001" "developer:3002" "researcher:3003" "admin:3004")

for agent_port in "${AGENTS[@]}"; do
    agent="${agent_port%%:*}"
    port="${agent_port##*:}"
    
    # Sprawdź czy daemon odpowiada (HTTP health endpoint, nie LLM inference)
    if ! curl -sf "http://localhost:${port}/health" > /dev/null 2>&1; then
        # Agent nie odpowiada — wyślij alert
        curl -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
            -d "chat_id=${TG_CHAT_ID}" \
            -d "text=⚠️ Agent ${agent} (port ${port}) nie odpowiada!"
        
        # Opcjonalnie: restart daemona
        systemctl restart "openclaw-${agent}"
    fi
done
```

```ini
# /etc/systemd/system/openclaw-watchdog.timer
[Unit]
Description=OpenClaw Fleet Watchdog

[Timer]
OnCalendar=*:0/30
Persistent=true

[Install]
WantedBy=timers.target
```

### 2.4 Dodaj do PROTOCOL.md

```markdown
## STATUS REPORTING PROTOCOL

### Zasada: Event-driven, nie periodyczny

Agent NIE wysyła heartbeatów. Agent raportuje status TYLKO gdy:

1. **State change**: idle → working → blocked → error
   → Wyślij na Slack #{twój-kanał}: "[STATE] {nowy_stan}: {krótki opis}"

2. **Task complete**: ukończenie zadania lub jednostki pracy
   → Wyślij na Slack #{twój-kanał}: "[DONE] {task_id}: {wynik}"
   → Zaktualizuj Todoist

3. **Error**: błąd blokujący lub nieoczekiwany
   → Wyślij na Slack #alerts: "[ERROR] {opis}"
   → Jeśli krytyczny → eskaluj do Orchestratora

4. **Threshold warning**: kontekst > 70% LUB latency > 30s
   → Wyślij na Slack #alerts: "[THRESHOLD] context={X}% latency={Y}s"

5. **Ping response**: Orchestrator pyta o status
   → Odpowiedz natychmiast z: stan, % kontekstu, bieżące zadanie

ZABRONIONE: Periodyczne "I'm alive" messages. Zero idle inference.
```

---

## 3. Rate Limits Per Agent — Guardrails Przeciw Runaway Automation

### 3.1 Problem

Autonomiczne agenty z cron jobami, webhookami i Lobster pipeline'ami mogą wpaść w loop requestów. Jeden źle skonfigurowany pipeline (np. Researcher skanujący BUR z błędnym warunkiem stopu) może zablokować GPU na godziny.

### 3.2 Dodaj do PROTOCOL.md

```markdown
## RATE LIMITS

### Per Agent Limits

| Agent | Max requests/min | Max concurrent tools | Web search/batch | Cooldown |
|---|---|---|---|---|
| Orchestrator | 15 | 3 | 5 + 2min break | 5s between calls |
| Developer | 12 | 5 (exec heavy) | 3 + 2min break | 3s between calls |
| Researcher | 10 | 2 | 5 + 2min break | 10s between searches |
| Admin | 8 | 2 | 3 + 3min break | 5s between calls |

### Hard Stops

- Jeśli HTTP 429 (rate limit) → STOP, wait 5 minut, retry ONCE, jeśli nadal 429 → log + notify Orchestrator
- Jeśli response timeout > 30s → log jako threshold warning (patrz sekcja 4)
- Jeśli 3 consecutive errors → STOP, log, notify Orchestrator, wait for human
- Jeśli GPU utilization > 95% przez > 5 min → Admin i Researcher wstrzymują requesty, priorytet dla Orchestratora i Developera

### Batch Rules

- ZAWSZE grupuj podobną pracę w jeden request (np. "sprawdź 10 leadów" = 1 request, NIE 10 requestów)
- Web search: max 5 queries per batch, potem 2-minutowy cooldown
- File operations: max 20 plików per batch
- Todoist: max 10 operacji per batch

### Priority Queue (przy GPU contention)

1. 🔴 Orchestrator — zawsze pierwszy
2. 🟠 Developer — drugi priorytet
3. 🟡 Researcher — trzeci
4. 🟢 Admin — najniższy, czeka jeśli kolejka > 2

### Compute Budget (zastępuje monetary budget)

Zamiast "$5/day" — metryki compute:
- Max inference time per agent: 45 min/h (15 min idle minimum)
- Max total fleet inference: 150 min/h (10 min reserved headroom)
- Monitoring: Orchestrator odpytuje system-monitor co task completion
```

---

## 4. Latency jako Trigger Rotacji

### 4.1 Problem

Dotychczasowe progi rotacji opierają się wyłącznie na % wykorzystania kontekstu (35% warning, 50% rotate, 75% emergency). Dane z analizy logów pokazują, że degradacja latency nie jest liniowa — rośnie wykładniczo po pewnym punkcie (z 2-12s do 119s). Może się zdarzyć, że agent jest na 45% kontekstu, ale latency już wskazuje na degradację (np. przez złożony reasoning chain).

### 4.2 Zaktualizowane progi — Dual Trigger System

```markdown
## ROTATION TRIGGERS (zaktualizowane)

Rotacja następuje gdy KTÓRYKOLWIEK z warunków jest spełniony:

### Trigger A: Context Usage (istniejący)

| Próg | Akcja | Typ zadania |
|---|---|---|
| 35% | ⚡ WARNING — zapisz checkpoint | Coding |
| 40% | ⚡ WARNING — zapisz checkpoint | Debugging |
| 50% | ⚠️ ROTATE — natychmiast zapisz pełny stan | Coding |
| 60% | ⚠️ ROTATE — natychmiast zapisz pełny stan | Planning/Docs |
| 75% | 🚨 EMERGENCY — jedna odpowiedź i koniec | Wszystkie |

### Trigger B: Latency Degradation (NOWY)

| Warunek | Akcja |
|---|---|
| Response time > 20s (baseline < 10s) | ⚡ WARNING — zaloguj, monitoruj trend |
| Response time > 30s przez 2 kolejne odpowiedzi | ⚠️ ROTATE — inicjuj handoff |
| Response time > 60s | 🚨 EMERGENCY — natychmiast zapisz i zamknij |
| Response time > 30s AND context > 40% | ⚠️ ROTATE — podwójny sygnał, natychmiast |

### Trigger C: Quality Degradation (NOWY — heurystyczny)

| Warunek | Akcja |
|---|---|
| Agent powtarza tę samą akcję 3x bez postępu | ⚠️ ROTATE — prawdopodobna halucynacja loopowa |
| Agent produkuje output niezgodny z TASK_STATE | ⚡ WARNING — zweryfikuj stan |
| Agent "zapomina" wcześniejsze decyzje z tej sesji | 🚨 EMERGENCY — kontekst zdegradowany |
```

### 4.3 Implementacja w Session Manager (Python)

Dodaj do istniejącego `SessionManager`:

```python
# Nowe pola w SessionConfig
@dataclass
class SessionConfig:
    # ... istniejące pola ...
    
    # Latency triggers (NOWE)
    latency_warning_threshold: float = 20.0      # sekundy
    latency_rotate_threshold: float = 30.0        # sekundy
    latency_emergency_threshold: float = 60.0     # sekundy
    latency_rotate_consecutive: int = 2           # ile kolejnych > threshold
    latency_baseline: float = 10.0                # oczekiwany normalny czas
    
    # Quality triggers (NOWE)
    max_repeated_actions: int = 3                 # loop detection
    
# Nowe pola w SessionState
@dataclass
class SessionState:
    # ... istniejące pola ...
    
    # Latency tracking (NOWE)
    response_times: list = field(default_factory=list)
    consecutive_slow_responses: int = 0
    
    @property
    def avg_latency(self) -> float:
        if not self.response_times:
            return 0.0
        return sum(self.response_times[-10:]) / len(self.response_times[-10:])
    
    @property
    def last_latency(self) -> float:
        return self.response_times[-1] if self.response_times else 0.0


# Nowa metoda w SessionManager
def check_latency_threshold(self, response_time: float) -> Optional[str]:
    """Sprawdź czy latency wskazuje na degradację."""
    self.state.response_times.append(response_time)
    
    # Emergency: pojedyncza odpowiedź > 60s
    if response_time > self.config.latency_emergency_threshold:
        self.logger.warning(f"🚨 LATENCY EMERGENCY: {response_time:.1f}s")
        return "emergency"
    
    # Rotate: consecutive slow responses
    if response_time > self.config.latency_rotate_threshold:
        self.state.consecutive_slow_responses += 1
        if self.state.consecutive_slow_responses >= self.config.latency_rotate_consecutive:
            self.logger.warning(
                f"⚠️ LATENCY ROTATE: {self.state.consecutive_slow_responses}x "
                f">{self.config.latency_rotate_threshold}s"
            )
            return "rotate"
    else:
        self.state.consecutive_slow_responses = 0  # reset counter
    
    # Dual trigger: latency + context
    usage = self.get_usage_ratio()
    if response_time > self.config.latency_rotate_threshold and usage > 0.4:
        self.logger.warning(
            f"⚠️ DUAL TRIGGER: latency={response_time:.1f}s + context={usage:.0%}"
        )
        return "rotate"
    
    # Warning
    if response_time > self.config.latency_warning_threshold:
        self.logger.info(f"⚡ LATENCY WARNING: {response_time:.1f}s")
        return "warning"
    
    return None
```

### 4.4 Integracja z główną pętlą

```python
# W metodzie run_session(), po wywołaniu API:

import time

# --- 2. Wywołaj API z pomiarem czasu ---
start_time = time.monotonic()
response = self._call_api()
elapsed = time.monotonic() - start_time

if response is None:
    return "error"

# --- 2b. Sprawdź latency threshold (NOWE) ---
latency_threshold = self.check_latency_threshold(elapsed)

if latency_threshold == "emergency":
    # Nadpisuje inne thresholdy — natychmiastowy zapis i zamknięcie
    return self._rotate_session("latency_emergency")

if latency_threshold == "rotate" and not self.state.rotation_triggered:
    self.messages.append(self.inject_signal("rotate"))
    self.state.rotation_triggered = True

# --- 3. Przetwórz odpowiedź (istniejący kod) ---
self._process_response(response)
```

---

## 5. Session Initialization — Lean Context Loading

### 5.1 Zasada (zintegrowana z istniejącym Boot Sequence)

Twój Mandatory Boot Sequence jest już lepszy niż propozycja ScaleUP, ale warto dodać explicit "DO NOT LOAD" list, żeby agent nie ładował niepotrzebnego kontekstu:

### 5.2 Dodaj do PROTOCOL.md (sekcja Boot Sequence)

```markdown
## BOOT SEQUENCE (zaktualizowany)

### Na początku KAŻDEJ sesji, ZANIM zrobisz cokolwiek:

KROK 1 — ZAŁADUJ (w tej kolejności):
  1. SOUL.md (jeśli nie jest w system prompt — powinien być)
  2. PROTOCOL.md (jeśli nie jest w system prompt — powinien być)
  3. ROLE.md (twoja rola — powinien być w system prompt)
  4. TASK_STATE.md (cat .agent/TASK_STATE.md)
  5. HANDOFF.md (cat .agent/HANDOFF.md — jeśli istnieje)
  6. memory/YYYY-MM-DD.md (jeśli istnieje — dzisiejsze notatki)

KROK 2 — NIE ŁADUJ automatycznie:
  ❌ MEMORY.md (pełna historia — ładuj on-demand przez memory_search())
  ❌ Poprzednie session logi (SESSION_LOG.jsonl — tylko do analizy)
  ❌ Pliki kodu/projektów (ładuj dopiero gdy potrzebne do bieżącego taska)
  ❌ Historię konwersacji z poprzednich sesji
  ❌ Dokumentację narzędzi (ładuj on-demand)

KROK 3 — POTWIERDŹ rozumienie:
  "Rozumiem stan:
   Mission: {z TASK_STATE}
   Phase: {z TASK_STATE}
   Last action: {z TASK_STATE}
   Next step: {z HANDOFF lub TASK_STATE}
   Kontynuuję."

KROK 4 — DOPIERO TERAZ przystąp do pracy.

### On-Demand Loading Rule

Gdy potrzebujesz informacji z przeszłości:
  → Użyj memory_search("{keyword}") — zwraca TYLKO relevantny snippet
  → Użyj memory_get("{specific_id}") — pobiera konkretny wpis
  → NIE ładuj całego pliku MEMORY.md
  → NIE ładuj wszystkich daily notes naraz

Ta zasada utrzymuje kontekst startowy na ~8-12KB zamiast 50KB+.
```

---

## 6. Model Tiering dla Lokalnego GPU

### 6.1 Problem

Czterech agentów na jednym RTX 3090 (24GB VRAM) z GPT-120B to potencjalny bottleneck. Nie wszyscy agenci potrzebują pełnej mocy modelu.

### 6.2 Strategia: Dwa Profile Modelu

```
┌─────────────────────────────────────────────────────┐
│  PROFIL A: GPT-120B Full (FP16 lub Q8)              │
│  → Orchestrator (reasoning, delegacja, strategia)   │
│  → Developer (coding, architecture, debugging)      │
│  Parametry: num_ctx=131072, temperature=0.3          │
├─────────────────────────────────────────────────────┤
│  PROFIL B: GPT-120B Quantized (Q4_K_M / AWQ 4-bit) │
│  → Researcher (search, analysis — mniej krytyczny)  │
│  → Admin (rutynowe taski, kalendarz, maile)         │
│  → Watchdog responses                               │
│  Parametry: num_ctx=65536, temperature=0.5           │
│  VRAM: ~40-50% mniej niż Profil A                   │
└─────────────────────────────────────────────────────┘
```

### 6.3 Konfiguracja Ollama — dwa modele

```bash
# Profil A: pełny model
ollama create gpt120b-full -f Modelfile.full

# Profil B: skwantyzowany
ollama create gpt120b-lite -f Modelfile.lite
```

```
# Modelfile.full
FROM gpt-120b
PARAMETER num_ctx 131072
PARAMETER temperature 0.3
PARAMETER num_keep -1

# Modelfile.lite  
FROM gpt-120b-q4km
PARAMETER num_ctx 65536
PARAMETER temperature 0.5
PARAMETER num_keep -1
```

### 6.4 Mapowanie w OpenClaw config per agent

```json5
// ~/.openclaw-orchestrator/openclaw.json
{
  "model": "ollama/gpt120b-full"
}

// ~/.openclaw-developer/openclaw.json
{
  "model": "ollama/gpt120b-full"
}

// ~/.openclaw-researcher/openclaw.json
{
  "model": "ollama/gpt120b-lite"
}

// ~/.openclaw-admin/openclaw.json
{
  "model": "ollama/gpt120b-lite"
}
```

### 6.5 Fallback: Orchestrator na Claude Opus (opcjonalnie)

Jeśli jakość reasoning Orchestratora na lokalnym modelu jest niewystarczająca dla złożonych decyzji architekturalnych:

```json5
// ~/.openclaw-orchestrator/openclaw.json
{
  "model": "anthropic/claude-opus-4-5",        // Primary: cloud API
  "models": {
    "ollama/gpt120b-full": { "alias": "local" } // Fallback: lokalny
  }
}
```

Koszt: ~$15/1M tokenów dla Opus, ale Orchestrator wysyła relatywnie mało requestów (deleguje, nie wykonuje). Szacowany koszt: $5-15/miesiąc.

---

## 7. Compute Monitoring — Metryki GPU zamiast Dolarów

### 7.1 Metryki do śledzenia

| Metryka | Narzędzie | Alert threshold |
|---|---|---|
| GPU Utilization % | `nvidia-smi` / system-monitor | > 95% przez > 5 min |
| VRAM Usage | `nvidia-smi` | > 22GB / 24GB |
| Inference tokens/sec | Ollama logs | < 5 tok/s (degradacja) |
| Queue wait time | Ollama metrics | > 10s (contention) |
| First-token latency | Session Manager | > 5s (cache miss / overload) |
| Response time (E2E) | Session Manager | > 30s (patrz sekcja 4) |

### 7.2 Monitoring Script (cron co 5 minut)

```bash
#!/bin/bash
# /opt/openclaw/gpu-monitor.sh

GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
VRAM_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
VRAM_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
VRAM_PCT=$((VRAM_USED * 100 / VRAM_TOTAL))
TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)

# Log
echo "$(date -Iseconds) GPU:${GPU_UTIL}% VRAM:${VRAM_USED}/${VRAM_TOTAL}MB (${VRAM_PCT}%) TEMP:${TEMP}°C" \
    >> /var/log/openclaw/gpu-metrics.log

# Alerty
if [ "$GPU_UTIL" -gt 95 ]; then
    # Sprawdź czy trwa to > 5 minut (porównaj z poprzednim logiem)
    PREV_HIGH=$(tail -5 /var/log/openclaw/gpu-metrics.log | grep -c "GPU:9[5-9]\|GPU:100")
    if [ "$PREV_HIGH" -ge 5 ]; then
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
            -d "chat_id=${TG_CHAT_ID}" \
            -d "text=🔴 GPU overload: ${GPU_UTIL}% przez >5min. VRAM: ${VRAM_PCT}%. Temp: ${TEMP}°C"
    fi
fi

if [ "$VRAM_PCT" -gt 92 ]; then
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d "chat_id=${TG_CHAT_ID}" \
        -d "text=⚠️ VRAM critical: ${VRAM_USED}/${VRAM_TOTAL}MB (${VRAM_PCT}%)"
fi

if [ "$TEMP" -gt 85 ]; then
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d "chat_id=${TG_CHAT_ID}" \
        -d "text=🌡️ GPU temp: ${TEMP}°C — rozważ throttling"
fi
```

### 7.3 Priority Queue przy contention

Gdy GPU jest przeciążone, Orchestrator wymusza priorytety:

```markdown
## GPU CONTENTION PROTOCOL

Gdy GPU utilization > 90% przez > 2 minuty:

1. Admin → PAUSE (wstrzymaj wszystkie requesty, czekaj na sygnał)
2. Researcher → PAUSE (chyba że ma task CRITICAL)
3. Developer → kontynuuje normalnie
4. Orchestrator → kontynuuje normalnie

Wznowienie: gdy GPU < 80% przez > 1 minutę
Orchestrator wysyła na Slack: "[RESUME] GPU contention resolved"

Agent w PAUSE:
- NIE wysyła requestów do Ollama
- Zapisuje stan do TASK_STATE.md
- Czeka na "[RESUME]" na Slack #alerts
- Jeśli PAUSE > 30 minut → zapisz pełny stan, zamknij sesję gracefully
```

---

## 8. Pełna Checklist Wdrożenia

### Faza 1: Restrukturyzacja Promptów (Dzień 1)

- [ ] Przeorganizuj system prompt każdego agenta wg kolejności z sekcji 1.2
- [ ] Wyodrębnij ROLE.md per agent (oddziel od SOUL.md)
- [ ] Dodaj PROMPT STRUCTURE RULE do SOUL.md
- [ ] Dodaj SESSION INITIALIZATION update do PROTOCOL.md (sekcja 5.2)
- [ ] Skonfiguruj Ollama cache parameters (sekcja 1.4)
- [ ] Zweryfikuj: `session_status` powinien pokazać context ~8-12KB na starcie

### Faza 2: Event-Driven Health (Dzień 2)

- [ ] Wyłącz heartbeat we wszystkich agentach (`"every": "0"`)
- [ ] Dodaj STATUS REPORTING PROTOCOL do PROTOCOL.md (sekcja 2.4)
- [ ] Wdróż watchdog.sh jako systemd timer (sekcja 2.3)
- [ ] Wdróż gpu-monitor.sh jako cron co 5 minut (sekcja 7.2)
- [ ] Przetestuj: wyłącz jednego agenta, sprawdź czy alert przychodzi na Telegram

### Faza 3: Rate Limits i Guardrails (Dzień 3)

- [ ] Dodaj RATE LIMITS do PROTOCOL.md (sekcja 3.2)
- [ ] Dodaj GPU CONTENTION PROTOCOL do PROTOCOL.md (sekcja 7.3)
- [ ] Przetestuj: ustaw niskie limity, uruchom pipeline, zweryfikuj że agent się zatrzymuje

### Faza 4: Latency Monitoring (Dzień 4)

- [ ] Dodaj latency tracking do Session Manager (sekcja 4.3 i 4.4)
- [ ] Zaktualizuj progi rotacji w PROTOCOL.md (sekcja 4.2)
- [ ] Dodaj latency do logów sesji (SESSION_LOG.jsonl)
- [ ] Przetestuj: sztucznie opóźnij response, zweryfikuj rotację

### Faza 5: Model Tiering (Dzień 5-7)

- [ ] Stwórz dwa profile Ollama: gpt120b-full i gpt120b-lite (sekcja 6.3)
- [ ] Zmapuj profile do agentów (sekcja 6.4)
- [ ] Przetestuj jakość Researcher i Admin na gpt120b-lite
- [ ] Opcjonalnie: przetestuj Orchestrator na Claude Opus vs lokalny
- [ ] Zmierz: VRAM usage z dwoma profilami vs jednym

---

## 9. Porównanie: Przed i Po Optymalizacji

| Metryka | PRZED | PO |
|---|---|---|
| Context na starcie sesji | 50KB+ | 8-12KB |
| Idle GPU inference (heartbeat) | Ciągłe, 4 agenty | Zero (event-driven) |
| Trigger rotacji | Tylko % kontekstu | % kontekstu + latency + quality |
| Rate limiting | Brak | Per agent, z priorytetami |
| GPU monitoring | Brak / manualny | Automatyczny z alertami Telegram |
| Model per agent | Jeden dla wszystkich | Tiered: full (Orch+Dev) / lite (Res+Admin) |
| Prompt cache hit rate | Losowy (brak struktury) | ~80-90% (frozen prefix) |
| Concurrent agent capacity | 1-2 (GPU bottleneck) | 3-4 (z tieringiem + queue) |
| Średni first-token latency | 3-8s | 1-4s (z cache) |
| Recovery po crash | Manual / losowy | Automatyczny Boot Sequence + TASK_STATE |

---

## 10. Źródła i Referencje

- **ScaleUP Media — OpenClaw Token Optimization Guide** (Matt Ganzak, luty 2026): Session init, model routing, prompt caching
- **Nasza architektura Bible**: Layered Memory System, Handoff Protocol, Session Manager, Boot Sequence
- **Analiza logów OpenClaw** (źródło community): Degradacja latency 2-12s → 119s przy rozbudowanym kontekście
- **Ollama docs**: Prompt caching od v0.5+, KV cache configuration, multi-model serving
- **OpenClaw FAQ**: Multi-agent routing "token heavy" — potwierdzenie słuszności architektury niezależnych instancji

---

*Dokument wygenerowany 7 lutego 2026. Wersja 2.0 — integracja istniejącej architektury Bible z optymalizacjami ScaleUP + autorskie rozszerzenia.*

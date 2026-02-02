# 🐳 DOCKER-REGISTRY.md - Rejestr Kontenerów

> **OBOWIĄZKOWA DOKUMENTACJA KAŻDEGO KONTENERA**
> 
> Przed instalacją nowego kontenera SPRAWDŹ czy już nie istnieje.
> Po instalacji ZAWSZE dodaj wpis tutaj.

---

## 📊 Podsumowanie

| Kategoria | Ilość | Status |
|-----------|-------|--------|
| **Core Infrastructure** | 0 | 🟢 |
| **Monitoring** | 0 | 🟢 |
| **Security** | 0 | 🟢 |
| **Applications** | 0 | 🟢 |
| **Databases** | 0 | 🟢 |

**Ostatnia aktualizacja:** {{TIMESTAMP}}  
**Zaktualizował:** {{AGENT}}

---

## 🏗️ CORE INFRASTRUCTURE

### 📦 Traefik (Reverse Proxy)
```yaml
container_name: traefik
image: traefik:v3.0
status: 🟢 RUNNING | 🟡 STOPPED | 🔴 ERROR | ⚫ NOT INSTALLED
installed: {{DATE}}
purpose: Reverse proxy, SSL termination, load balancing

ports:
  - "80:80"      # HTTP (redirect to HTTPS)
  - "443:443"    # HTTPS
  - "8080:8080"  # Dashboard (internal only!)

volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
  - ./traefik/config:/etc/traefik
  - ./traefik/certs:/certs

networks:
  - traefik-public
  - internal

dependencies: []

notes: |
  Dashboard dostępny tylko przez VPN/localhost
  Certyfikaty Let's Encrypt automatyczne
  
maintenance:
  last_update: {{DATE}}
  next_review: {{DATE + 30 dni}}
```

---

### 📦 Portainer (Docker Management)
```yaml
container_name: portainer
image: portainer/portainer-ce:latest
status: ⚫ NOT INSTALLED
installed: -
purpose: Web UI do zarządzania Docker

ports:
  - "9443:9443"  # HTTPS UI (przez Traefik)

volumes:
  - /var/run/docker.sock:/var/run/docker.sock
  - portainer_data:/data

networks:
  - traefik-public

dependencies:
  - traefik

notes: |
  Dostęp tylko przez Traefik z auth
  Backup danych co 24h
```

---

## 📈 MONITORING

### 📦 Prometheus
```yaml
container_name: prometheus
image: prom/prometheus:latest
status: ⚫ NOT INSTALLED
installed: -
purpose: Zbieranie metryk, alerting

ports:
  - "9090:9090"  # Internal only!

volumes:
  - ./prometheus/config:/etc/prometheus
  - prometheus_data:/prometheus

networks:
  - monitoring
  - internal

dependencies: []

scrape_targets:
  - node_exporter:9100
  - cadvisor:8080
  - traefik:8080

notes: |
  Retention: 15 dni
  Alertmanager skonfigurowany dla Discord/Email
```

---

### 📦 Grafana
```yaml
container_name: grafana
image: grafana/grafana:latest
status: ⚫ NOT INSTALLED
installed: -
purpose: Wizualizacja metryk, dashboardy

ports:
  - "3000:3000"  # Przez Traefik

volumes:
  - grafana_data:/var/lib/grafana
  - ./grafana/provisioning:/etc/grafana/provisioning

networks:
  - monitoring
  - traefik-public

dependencies:
  - prometheus
  - traefik

dashboards:
  - Node Exporter Full
  - Docker Container Metrics
  - Traefik Dashboard

notes: |
  OAuth przez Authentik/Keycloak
  Backup dashboardów w Git
```

---

### 📦 Node Exporter
```yaml
container_name: node-exporter
image: prom/node-exporter:latest
status: ⚫ NOT INSTALLED
installed: -
purpose: Metryki systemu hosta

ports:
  - "9100:9100"  # Internal only!

volumes:
  - /proc:/host/proc:ro
  - /sys:/host/sys:ro
  - /:/rootfs:ro

networks:
  - monitoring

command:
  - '--path.procfs=/host/proc'
  - '--path.sysfs=/host/sys'
  - '--path.rootfs=/rootfs'

notes: |
  NIE eksponuj na zewnątrz!
  Tylko dla Prometheus
```

---

### 📦 cAdvisor
```yaml
container_name: cadvisor
image: gcr.io/cadvisor/cadvisor:latest
status: ⚫ NOT INSTALLED
installed: -
purpose: Metryki kontenerów Docker

ports:
  - "8081:8080"  # Internal only!

volumes:
  - /:/rootfs:ro
  - /var/run:/var/run:ro
  - /sys:/sys:ro
  - /var/lib/docker/:/var/lib/docker:ro

networks:
  - monitoring

notes: |
  Wysokie zużycie RAM - monitoruj
  NIE eksponuj na zewnątrz!
```

---

## 🔒 SECURITY

### 📦 Fail2ban (Host-level)
```yaml
# UWAGA: Fail2ban lepiej na hoście, nie w kontenerze!
type: HOST SERVICE
status: ⚫ NOT INSTALLED
purpose: Blokowanie brute-force attacks

config_path: /etc/fail2ban/

jails_enabled:
  - sshd
  - traefik-auth
  - nginx-http-auth

notes: |
  Preferuj instalację na hoście!
  Kontener ma ograniczony dostęp do iptables
```

---

### 📦 CrowdSec
```yaml
container_name: crowdsec
image: crowdsecurity/crowdsec:latest
status: ⚫ NOT INSTALLED
installed: -
purpose: Collaborative security, behavior analysis

ports:
  - "8080:8080"  # API (internal)
  - "6060:6060"  # Metrics

volumes:
  - ./crowdsec/config:/etc/crowdsec
  - ./crowdsec/data:/var/lib/crowdsec/data
  - /var/log:/var/log:ro

networks:
  - security
  - internal

bouncers:
  - traefik-bouncer
  - firewall-bouncer

notes: |
  Wymaga rejestracji na crowdsec.net
  Integracja z Traefik przez bouncer
```

---

### 📦 Authentik (Identity Provider)
```yaml
container_name: authentik
image: ghcr.io/goauthentik/server:latest
status: ⚫ NOT INSTALLED
installed: -
purpose: SSO, OAuth2, LDAP, authentication

ports:
  - "9000:9000"   # HTTP
  - "9443:9443"   # HTTPS

volumes:
  - ./authentik/media:/media
  - ./authentik/templates:/templates

networks:
  - traefik-public
  - internal

dependencies:
  - postgresql
  - redis
  - traefik

protected_apps:
  - grafana
  - portainer
  - admin-panels

notes: |
  Wymaga PostgreSQL i Redis
  Konfiguracja SMTP dla recovery
```

---

## 💾 DATABASES

### 📦 PostgreSQL
```yaml
container_name: postgres
image: postgres:16-alpine
status: ⚫ NOT INSTALLED
installed: -
purpose: Primary relational database

ports:
  - "5432:5432"  # Internal only!

volumes:
  - postgres_data:/var/lib/postgresql/data
  - ./postgres/init:/docker-entrypoint-initdb.d

networks:
  - database

environment:
  # SECRETS W .env LUB DOCKER SECRETS!
  POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password

databases:
  - authentik
  - grafana
  - app_production

backup:
  schedule: "0 2 * * *"  # Daily 2 AM
  retention: 7 days
  location: /backups/postgres/

notes: |
  NIGDY nie eksponuj na 0.0.0.0!
  Backup przed każdą migracją
```

---

### 📦 Redis
```yaml
container_name: redis
image: redis:7-alpine
status: ⚫ NOT INSTALLED
installed: -
purpose: Cache, session storage, message broker

ports:
  - "6379:6379"  # Internal only!

volumes:
  - redis_data:/data

networks:
  - database

command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}

used_by:
  - authentik
  - app_cache

notes: |
  Włącz persistence (appendonly)
  Ustaw hasło!
```

---

## 🌐 APPLICATIONS

### 📦 [TEMPLATE] Application Name
```yaml
container_name: app-name
image: vendor/app:version
status: ⚫ NOT INSTALLED
installed: -
purpose: Opis co robi aplikacja

ports:
  - "XXXX:XXXX"  # Opis portu

volumes:
  - ./app/config:/config
  - app_data:/data

networks:
  - traefik-public  # Jeśli publiczna
  - internal        # Zawsze

dependencies:
  - lista
  - zależności

environment:
  # Lista wymaganych zmiennych
  - VAR_NAME=description

health_check:
  endpoint: /health
  interval: 30s

backup:
  required: true/false
  paths:
    - /data
  schedule: "cron expression"

notes: |
  Dodatkowe uwagi
  Specjalne konfiguracje
  
maintenance:
  last_update: {{DATE}}
  next_review: {{DATE}}
```

---

## 🔄 SIECI DOCKER

| Nazwa | Typ | Subnet | Przeznaczenie |
|-------|-----|--------|---------------|
| `traefik-public` | bridge | 172.20.0.0/16 | Usługi publiczne przez Traefik |
| `internal` | bridge | 172.21.0.0/16 | Komunikacja wewnętrzna |
| `monitoring` | bridge | 172.22.0.0/16 | Stack monitoringu |
| `database` | bridge | 172.23.0.0/16 | Bazy danych (izolowane) |
| `security` | bridge | 172.24.0.0/16 | Usługi security |

### Tworzenie sieci:
```bash
docker network create --driver bridge --subnet 172.20.0.0/16 traefik-public
docker network create --driver bridge --subnet 172.21.0.0/16 internal
docker network create --driver bridge --subnet 172.22.0.0/16 monitoring
docker network create --driver bridge --subnet 172.23.0.0/16 database
docker network create --driver bridge --subnet 172.24.0.0/16 security
```

---

## 📋 PROCEDURA DODAWANIA NOWEGO KONTENERA

1. **Sprawdź czy nie istnieje:**
   ```bash
   docker ps -a | grep -i "<nazwa>"
   grep -i "<nazwa>" docs/DOCKER-REGISTRY.md
   ```

2. **Sprawdź dostępność portów:**
   ```bash
   ss -tulpn | grep ":<port>"
   ```

3. **Przygotuj docker-compose.yml** w `infrastructure/docker-compose/<nazwa>/`

4. **Uruchom kontener:**
   ```bash
   docker-compose up -d
   docker logs -f <nazwa>
   ```

5. **ZAKTUALIZUJ DOKUMENTACJĘ:**
   - Dodaj wpis do tego pliku
   - Zaktualizuj `NETWORK-MAP.md` jeśli nowe porty
   - Dodaj wpis do `logs/docker-changes/YYYY-MM-DD.md`

6. **Zweryfikuj:**
   ```bash
   docker ps | grep <nazwa>
   curl -I http://localhost:<port>/health
   ```

---

**Format nazewnictwa kontenerów:** `<kategoria>-<nazwa>` np. `db-postgres`, `mon-grafana`, `app-myapp`

---

*Ostatnia rewizja struktury: {{DATE}}*

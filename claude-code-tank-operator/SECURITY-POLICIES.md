# 🔒 SECURITY-POLICIES.md - Polityki Bezpieczeństwa

> **OBOWIĄZKOWE STANDARDY BEZPIECZEŃSTWA**
> 
> Każda operacja MUSI być zgodna z tymi politykami.
> Wyjątki wymagają dokumentacji w logu z uzasadnieniem.

---

## 🎯 ZASADY NADRZĘDNE

### 1. Zasada Najmniejszych Uprawnień (Principle of Least Privilege)
- Każdy kontener/proces ma TYLKO wymagane uprawnienia
- Domyślnie: brak dostępu, dodawaj tylko to co niezbędne
- Regularny audyt uprawnień (co 30 dni)

### 2. Defense in Depth
- Wielowarstwowe zabezpieczenia
- Firewall → Fail2ban → Reverse Proxy → Aplikacja → Auth
- Każda warstwa zakłada, że poprzednia może zawieść

### 3. Zero Trust
- Nie ufaj niczemu domyślnie
- Weryfikuj każde połączenie
- Szyfruj wszystko co możliwe

---

## 🔐 ZARZĄDZANIE SEKRETAMI

### ⛔ NIGDY:
```
- Hasła w docker-compose.yml
- Hasła w zmiennych środowiskowych w kodzie
- Klucze API w logach
- Secrets w Git (nawet prywatnym!)
```

### ✅ ZAWSZE:

#### Metoda 1: Docker Secrets (preferowana)
```yaml
services:
  db:
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

#### Metoda 2: .env z odpowiednimi uprawnieniami
```bash
# Tworzenie pliku .env
touch .env
chmod 600 .env
chown root:root .env

# Zawartość
DB_PASSWORD=super_secret_password

# .gitignore MUSI zawierać:
.env
.env.*
*.secret
secrets/
```

#### Metoda 3: Vault (dla większych deploymentów)
```yaml
services:
  app:
    environment:
      VAULT_ADDR: http://vault:8200
      VAULT_TOKEN_FILE: /run/secrets/vault_token
```

### Rotacja sekretów:
| Typ | Częstotliwość | Procedura |
|-----|---------------|-----------|
| Database passwords | 90 dni | `docs/procedures/rotate-db-passwords.md` |
| API keys | 180 dni | Regeneruj w panelu dostawcy |
| SSL certificates | Auto (Let's Encrypt) | Traefik automatycznie |
| SSH keys | 365 dni | `ssh-keygen`, update authorized_keys |

---

## 🐳 DOCKER SECURITY

### Container Hardening Checklist:

```yaml
# ✅ WYMAGANE dla każdego kontenera
services:
  secure-container:
    # 1. Nie uruchamiaj jako root
    user: "1000:1000"
    
    # 2. Read-only filesystem gdzie możliwe
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    
    # 3. Ogranicz capabilities
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # tylko jeśli potrzebne
    
    # 4. Security options
    security_opt:
      - no-new-privileges:true
      - seccomp:unconfined  # tylko jeśli konieczne!
    
    # 5. Resource limits
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          memory: 256M
    
    # 6. Network isolation
    networks:
      - internal  # NIGDY bezpośrednio na host network!
    
    # 7. Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### ⛔ ZABRONIONE praktyki Docker:

| Praktyka | Powód | Alternatywa |
|----------|-------|-------------|
| `privileged: true` | Pełny dostęp do hosta | Użyj specyficznych cap_add |
| `network_mode: host` | Omija izolację sieciową | Użyj port mapping |
| Mount `/var/run/docker.sock` | Dostęp do Docker daemon | Użyj Docker Socket Proxy |
| `user: root` (default) | Eskalacja uprawnień | Ustaw explicit user |
| `--pid=host` | Dostęp do procesów hosta | Unikaj |

### Docker Socket Proxy (jeśli trzeba):
```yaml
services:
  socket-proxy:
    image: tecnativa/docker-socket-proxy
    environment:
      CONTAINERS: 1
      NETWORKS: 1
      SERVICES: 1
      # Wszystko inne = 0
      IMAGES: 0
      INFO: 0
      POST: 0
      BUILD: 0
      COMMIT: 0
      CONFIGS: 0
      DISTRIBUTION: 0
      EXEC: 0
      GRPC: 0
      NODES: 0
      PLUGINS: 0
      SECRETS: 0
      SESSION: 0
      SWARM: 0
      SYSTEM: 0
      TASKS: 0
      VOLUMES: 0
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - internal
```

---

## 🔥 FIREWALL CONFIGURATION

### UFW (Ubuntu/Debian):
```bash
# Podstawowa konfiguracja
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny routed

# SSH - ZAWSZE jako pierwsze!
sudo ufw allow 22/tcp comment 'SSH'

# HTTP/HTTPS - przez Traefik
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Rate limiting dla SSH
sudo ufw limit 22/tcp comment 'SSH rate limit'

# Aktywacja
sudo ufw enable
```

### iptables (dla bardziej granularnej kontroli):
```bash
# Zapisz aktualne reguły przed zmianami!
sudo iptables-save > /backup/iptables-$(date +%Y%m%d).rules

# Podstawowe reguły
# INPUT chain
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -j DROP

# Ochrona przed typowymi atakami
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP  # NULL packets
sudo iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP  # SYN flood
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP  # XMAS packets
```

---

## 🛡️ FAIL2BAN CONFIGURATION

### Podstawowa konfiguracja:
```ini
# /etc/fail2ban/jail.local

[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
banaction = ufw
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h

[traefik-auth]
enabled = true
port = http,https
filter = traefik-auth
logpath = /var/log/traefik/access.log
maxretry = 5
bantime = 1h
```

### Custom filter dla Traefik:
```ini
# /etc/fail2ban/filter.d/traefik-auth.conf
[Definition]
failregex = ^.* - - \[.*\] ".*" 401 .* ".*" ".*" .* "<HOST>".*$
            ^.* - - \[.*\] ".*" 403 .* ".*" ".*" .* "<HOST>".*$
ignoreregex =
```

---

## 🔑 SSH HARDENING

### /etc/ssh/sshd_config:
```bash
# Podstawowe bezpieczeństwo
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Ograniczenia
MaxAuthTries 3
MaxSessions 2
LoginGraceTime 20

# Wyłącz niepotrzebne
X11Forwarding no
PermitEmptyPasswords no
IgnoreRhosts yes
HostbasedAuthentication no

# Timeouts
ClientAliveInterval 300
ClientAliveCountMax 2

# Tylko konkretni użytkownicy
AllowUsers admin deploy

# Logging
SyslogFacility AUTH
LogLevel VERBOSE
```

### SSH Key Management:
```bash
# Generowanie klucza (na lokalnej maszynie)
ssh-keygen -t ed25519 -C "admin@server" -f ~/.ssh/server_key

# Kopiowanie na serwer
ssh-copy-id -i ~/.ssh/server_key.pub admin@server

# Testowanie przed wyłączeniem password auth!
ssh -i ~/.ssh/server_key admin@server
```

---

## 📋 SECURITY CHECKLIST

### Codzienny przegląd:
- [ ] Sprawdź fail2ban status: `sudo fail2ban-client status`
- [ ] Przejrzyj auth.log: `sudo tail -100 /var/log/auth.log | grep -i failed`
- [ ] Sprawdź uruchomione kontenery: `docker ps`
- [ ] Sprawdź użycie zasobów: `docker stats --no-stream`

### Tygodniowy przegląd:
- [ ] Aktualizacje systemu: `sudo apt update && apt list --upgradable`
- [ ] Aktualizacje obrazów Docker: `docker images --format "{{.Repository}}:{{.Tag}}" | xargs -I {} docker pull {}`
- [ ] Przegląd logów: `journalctl --since "1 week ago" --priority=err`
- [ ] Sprawdź wygasające certyfikaty
- [ ] Backup konfiguracji

### Miesięczny audyt:
- [ ] Przegląd otwartych portów: `ss -tulpn`
- [ ] Audyt użytkowników: `cat /etc/passwd | grep -v nologin`
- [ ] Przegląd uprawnień kontenerów
- [ ] Test procedur disaster recovery
- [ ] Rotacja logów

---

## 🚨 INCIDENT RESPONSE

### Poziomy alertów:

| Poziom | Opis | Akcja |
|--------|------|-------|
| 🟢 LOW | Podejrzana aktywność | Log + monitor |
| 🟡 MEDIUM | Potwierdzona próba ataku | Blokada IP + analiza |
| 🔴 HIGH | Udany atak / breach | Izolacja + eskalacja |
| ⚫ CRITICAL | Kompromitacja systemu | Nuclear option + forensics |

### Procedura dla poziomu HIGH+:
```bash
# 1. Dokumentuj
date >> /var/log/incident-$(date +%Y%m%d).log
echo "Incident detected: [OPIS]" >> /var/log/incident-$(date +%Y%m%d).log

# 2. Izoluj (jeśli to możliwe)
docker stop [affected_container]

# 3. Zbierz dowody
docker logs [container] > /evidence/container-logs-$(date +%Y%m%d).log
cp /var/log/auth.log /evidence/
cp /var/log/syslog /evidence/

# 4. Blokuj źródło
sudo ufw deny from [IP_ADDRESS]

# 5. Eskaluj
# Powiadom właściciela systemu
```

---

## 📚 REFERENCJE

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Benchmarks](https://www.cisecurity.org/benchmark/docker)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Linux Hardening Guide](https://www.cisecurity.org/benchmark/ubuntu_linux)

---

*Ostatnia rewizja: {{DATE}}*
*Zatwierdził: {{OWNER}}*

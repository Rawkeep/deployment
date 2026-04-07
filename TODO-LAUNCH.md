# Launch Checklist — Mythos, FliFlow, Circle Keeper

> Stand: 7. April 2026
> Alles andere ist fertig. Nur diese Schritte fehlen noch.

---

## Was du brauchst

| Was | Warum | Wo besorgen |
|-----|-------|-------------|
| **1 Domain** | Subdomains fuer 3 Apps | z.B. bei Namecheap, Cloudflare, IONOS |
| **1 VPS** (nur bei Coolify/Docker) | Server fuer die Apps | Hetzner CX22 (4,35 EUR/Mo) empfohlen |
| **Railway-Account** (Alternative) | Falls kein eigener Server | https://railway.app (GitHub Login) |
| **API-Keys** (optional) | AI-Features in Mythos | Anthropic, OpenAI — erst wenn du sie brauchst |

---

## Schritt-fuer-Schritt

### 1. Domain besorgen + DNS einrichten
Kauf oder nutze eine Domain die du schon hast. Dann 3 A-Records anlegen:

```
mythos.DEINEDOMAIN.de      → VPS-IP
flipflow.DEINEDOMAIN.de    → VPS-IP
keeper.DEINEDOMAIN.de      → VPS-IP
```

Bei Railway stattdessen: CNAME auf die Railway-URL (wird dir angezeigt).

---

### 2a. SCHNELLSTER WEG: Railway (kein Server noetig)

```bash
# 1. Gehe zu https://railway.app und logge dich mit GitHub ein

# 2. Fuer jede App: "New Project" → "Deploy from GitHub repo"
#    - Rawkeep/Mythos
#    - Rawkeep/FlipFlow-AI-Creator
#    - Rawkeep/circle-keeper

# 3. Environment Variables setzen (pro App):
```

**Mythos:**
```
NODE_ENV=production
PORT=3001
JWT_SECRET=<wird automatisch generiert mit: openssl rand -hex 64>
APP_URL=https://mythos.DEINEDOMAIN.de
BACKEND_URL=https://mythos.DEINEDOMAIN.de
AI_DAILY_LIMIT=100
ANTHROPIC_API_KEY=<optional>
OPENAI_API_KEY=<optional>
```

**FliFlow:**
```
NODE_ENV=production
PORT=3001
JWT_SECRET=<openssl rand -hex 64>
APP_URL=https://flipflow.DEINEDOMAIN.de
EBAY_APP_ID=<optional>
EBAY_CERT_ID=<optional>
ETSY_API_KEY=<optional>
```

**Circle Keeper:**
```
NODE_ENV=production
PORT=3000
APP_URL=https://keeper.DEINEDOMAIN.de
```

```bash
# 4. Custom Domain zuweisen (Settings → Domains)
# 5. DNS CNAME setzen wie Railway dir anzeigt
# 6. Fertig — SSL kommt automatisch
```

**Kosten:** ~$5-15/Monat pro App (je nach Traffic)

---

### 2b. EIGENER SERVER: Coolify (Web-Dashboard)

```bash
# 1. VPS bestellen: Hetzner CX22 (2 CPU, 4GB RAM, 4,35 EUR/Mo)
#    Ubuntu 24.04, SSH-Key hinzufuegen

# 2. SSH verbinden und Coolify installieren:
ssh root@DEINE-VPS-IP
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# 3. Browser oeffnen:
#    http://DEINE-VPS-IP:8000
#    → Admin-Account erstellen (SOFORT, sonst kann jeder!)

# 4. Apps hinzufuegen:
#    New Resource → Public Repository → GitHub URL eingeben
#    Pro App: Port + Env Vars setzen (siehe oben)

# 5. Domain zuweisen: Settings → Domains → deine Subdomain
#    DNS A-Record muss auf VPS-IP zeigen

# 6. Deploy klicken — SSL kommt automatisch
```

**Kosten:** nur VPS = 4,35 EUR/Monat fuer ALLE 3 Apps

---

### 2c. VOLLE KONTROLLE: Docker Compose

```bash
# 1. VPS bestellen (wie oben)

# 2. Cloud-Init nutzen ODER manuell:
ssh root@DEINE-VPS-IP
curl -fsSL https://get.docker.com | sh
git clone https://github.com/Rawkeep/Mythos /opt/apps/Mythos
git clone https://github.com/Rawkeep/FlipFlow-AI-Creator /opt/apps/Flipflow
git clone https://github.com/Rawkeep/circle-keeper /opt/apps/CK
git clone https://github.com/Rawkeep/deployment /opt/apps/deployment

# 3. Setup-Script starten:
cd /opt/apps/deployment
./setup.sh
# → Fragt nach Domains, Email
# → Generiert JWT-Secrets automatisch
# → Baut und startet alles

# 4. API-Keys nachtragen (optional):
nano envs/.env.mythos
docker compose restart mythos
```

**Kosten:** nur VPS = 4,35 EUR/Monat fuer ALLE 3 Apps

---

## Was NICHT mehr fehlt (alles schon erledigt)

- [x] Dockerfiles fuer alle 3 Apps
- [x] railway.json fuer alle 3 Apps
- [x] docker-compose.yml mit Nginx + SSL
- [x] setup.sh (interaktives Setup)
- [x] coolify-setup.sh (Coolify Installation)
- [x] cloud-init.yml (VPS Auto-Provisioning)
- [x] Deploy-Buttons in allen READMEs
- [x] Health-Check Endpoints (/api/health)
- [x] Security (Helmet, CORS, Rate Limiting, JWT)
- [x] useUniversalAI.js Hook in allen 3 Apps
- [x] Alles auf GitHub gepushed

---

## Nuetzliche Befehle nach dem Deploy

```bash
# Logs anschauen
docker compose logs -f mythos

# App neustarten
docker compose restart flipflow

# Alles stoppen
docker compose down

# Update deployen (neue Version von GitHub)
cd /opt/apps/Mythos && git pull
cd /opt/apps/deployment && docker compose up -d --build mythos

# Backup erstellen
docker compose exec mythos cp /app/data/mythos.db /app/data/backup-$(date +%F).db

# Disk-Usage pruefen
docker system df
```

---

## Support

Fragen? Issues auf GitHub aufmachen:
- https://github.com/Rawkeep/deployment/issues

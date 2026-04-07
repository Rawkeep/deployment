# Deployment Guide — Mythos, FlipFlow, Circle Keeper

3 Apps deployen. Waehle eine der 3 Optionen.

---

## Option A: Railway (Schnellster Weg)

3 Klicks pro App, kein Server noetig.

### Apps deployen

1. **Mythos** — [Deploy on Railway](https://railway.app/new/github/Rawkeep/Mythos)
2. **FlipFlow** — [Deploy on Railway](https://railway.app/new/github/Rawkeep/FlipFlow-AI-Creator)
3. **Circle Keeper** — [Deploy on Railway](https://railway.app/new/github/Rawkeep/circle-keeper)

### Umgebungsvariablen setzen

Nach dem Deploy unter **Variables** eintragen:

| Variable | Mythos | FlipFlow | Circle Keeper |
|----------|--------|----------|---------------|
| `NODE_ENV` | `production` | `production` | `production` |
| `PORT` | `3001` | `3001` | `3000` |
| `JWT_SECRET` | `<generiert>` | `<generiert>` | — |

JWT Secret generieren: `openssl rand -hex 32`

### Kosten

~$5-15/Monat pro App, abhaengig von Nutzung. Free Tier fuer Tests verfuegbar.

---

## Option B: Coolify (Self-Hosted PaaS)

Eigener Server mit Web-Dashboard. Wie Railway/Vercel, aber auf deinem VPS.

### VPS-Anforderungen

| Anforderung | Minimum |
|-------------|---------|
| CPU | 2 vCPU |
| RAM | 4 GB |
| Disk | 30 GB SSD |
| OS | Ubuntu 24.04 LTS |
| Anbieter | Hetzner CX22, Netcup, DigitalOcean |

### Installation

```bash
# Auf dem VPS als root:
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

Oder das mitgelieferte Setup-Skript verwenden:

```bash
scp coolify-setup.sh root@DEINE-IP:/root/
ssh root@DEINE-IP
chmod +x coolify-setup.sh
./coolify-setup.sh
```

### Apps hinzufuegen

1. Browser oeffnen: `http://DEINE-IP:8000`
2. Admin-Account erstellen
3. **New Resource > Public Repository** fuer jede App:

| App | Repository | Port |
|-----|-----------|------|
| Mythos | `https://github.com/Rawkeep/Mythos` | 3001 |
| FlipFlow | `https://github.com/Rawkeep/FlipFlow-AI-Creator` | 3001 |
| Circle Keeper | `https://github.com/Rawkeep/circle-keeper` | 3000 |

4. Umgebungsvariablen setzen (siehe Tabelle unten)
5. Domain zuweisen unter **Settings > Domains**
6. **Deploy** klicken — SSL wird automatisch erstellt

### Kosten

Nur VPS: ca. 5 EUR/Monat (Hetzner CX22).

---

## Option C: Docker Compose (Manuell)

Volle Kontrolle ueber alles. Fuer Leute die Docker kennen.

### Voraussetzungen

```bash
# Docker installieren
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Neu einloggen
```

### Deployment

```bash
# Repos klonen
cd /opt
git clone https://github.com/Rawkeep/Mythos
git clone https://github.com/Rawkeep/FlipFlow-AI-Creator Flipflow
git clone https://github.com/Rawkeep/circle-keeper CK
git clone https://github.com/Rawkeep/deployment

# Setup ausfuehren
cd deployment
chmod +x setup.sh
./setup.sh
```

Das Skript fragt interaktiv nach:
- Domains fuer jede App
- E-Mail fuer SSL-Zertifikate
- Generiert automatisch JWT Secrets

### Manuell starten

```bash
cd /opt/deployment
docker compose up -d
docker compose ps        # Status pruefen
docker compose logs -f   # Logs anschauen
```

### Kosten

Nur VPS: ca. 5-10 EUR/Monat.

---

## Umgebungsvariablen

### Mythos

| Variable | Pflicht | Beschreibung |
|----------|---------|-------------|
| `NODE_ENV` | Ja | `production` |
| `PORT` | Ja | `3001` |
| `JWT_SECRET` | Ja | `openssl rand -hex 32` |
| `ANTHROPIC_API_KEY` | Nein | Fuer KI-Funktionen |
| `OPENAI_API_KEY` | Nein | Fuer KI-Funktionen |

### FlipFlow

| Variable | Pflicht | Beschreibung |
|----------|---------|-------------|
| `NODE_ENV` | Ja | `production` |
| `PORT` | Ja | `3001` |
| `JWT_SECRET` | Ja | `openssl rand -hex 32` |
| `EBAY_APP_ID` | Nein | eBay API Zugang |
| `EBAY_CERT_ID` | Nein | eBay API Zugang |
| `ETSY_API_KEY` | Nein | Etsy API Zugang |

### Circle Keeper

| Variable | Pflicht | Beschreibung |
|----------|---------|-------------|
| `NODE_ENV` | Ja | `production` |
| `PORT` | Ja | `3000` |

---

## DNS-Einrichtung

Erstelle A-Records bei deinem Domain-Anbieter:

| Typ | Name | Wert |
|-----|------|------|
| A | `mythos.deinedomain.de` | `DEINE-SERVER-IP` |
| A | `flipflow.deinedomain.de` | `DEINE-SERVER-IP` |
| A | `circlekeeper.deinedomain.de` | `DEINE-SERVER-IP` |

Alle 3 zeigen auf die gleiche IP. DNS-Propagation dauert meist unter 30 Minuten.

Bei **Railway** wird die Domain unter **Settings > Domains** als Custom Domain eingetragen. Railway gibt dir einen CNAME-Wert den du stattdessen als CNAME-Record setzt.

---

## Backup & Monitoring

### Container-Status

```bash
docker compose ps
docker stats
```

### Logs

```bash
docker compose logs -f                # Alle Apps
docker compose logs -f mythos         # Nur Mythos
docker compose logs -f --tail=50      # Letzte 50 Zeilen
```

### Neustart

```bash
docker compose restart mythos
docker compose restart flipflow
docker compose restart circlekeeper
```

### Datenbank-Backup (SQLite)

```bash
BACKUP_DIR="./data/backups/$(date +%Y-%m-%d)"
mkdir -p "$BACKUP_DIR"

docker compose exec mythos cp /app/data/mythos.db /tmp/backup.db
docker compose cp mythos:/tmp/backup.db "$BACKUP_DIR/mythos.db"

docker compose exec flipflow cp /app/data/raiders.db /tmp/backup.db
docker compose cp flipflow:/tmp/backup.db "$BACKUP_DIR/flipflow.db"

echo "Backup gespeichert in $BACKUP_DIR"
```

### Automatisches Backup (Cronjob)

```bash
# Taeglich um 3 Uhr nachts
crontab -e
# Zeile hinzufuegen:
0 3 * * * cd /opt/deployment && ./backup.sh >> /var/log/backup.log 2>&1
```

---

## Fehlerbehebung

| Problem | Loesung |
|---------|---------|
| Container startet nicht | `docker compose logs appname` pruefen |
| SSL-Zertifikat fehlt | DNS pruefen, 2 Min warten, `docker compose restart letsencrypt` |
| 502 Bad Gateway | App-Container pruefen: `docker compose ps` |
| Port belegt | `sudo lsof -i :80` und Prozess stoppen |
| Speicher voll | `docker system prune -a` |
| Coolify zeigt Fehler | `docker logs coolify` pruefen |

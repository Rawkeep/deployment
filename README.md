# VPS Deployment – Mythos, FliFlow, Circle Keeper

3 Apps auf einem Server mit automatischem SSL und Reverse Proxy.

## Voraussetzungen

### Server (VPS)
- **OS:** Ubuntu 22.04+ oder Debian 12+
- **RAM:** Mindestens 2 GB (4 GB empfohlen)
- **Disk:** 20 GB SSD
- **Kosten:** ca. 5-10 EUR/Monat (Hetzner CX22 oder aehnlich)

### Software
- Docker + Docker Compose v2
- Git

### Docker installieren (falls noetig)
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Neu einloggen damit Gruppenrechte aktiv werden
```

## DNS-Einrichtung

Erstelle 3 A-Records bei deinem Domain-Anbieter, alle auf die gleiche Server-IP:

| Typ | Name | Wert |
|-----|------|------|
| A | mythos.deinedomain.de | 123.45.67.89 |
| A | flipflow.deinedomain.de | 123.45.67.89 |
| A | circlekeeper.deinedomain.de | 123.45.67.89 |

DNS-Propagation kann bis zu 24 Stunden dauern (meist aber unter 30 Min).

## Schritt-fuer-Schritt Deployment

### 1. Repos klonen
```bash
cd /opt  # oder ein anderer Ordner
git clone <mythos-repo-url> Mythos
git clone <flipflow-repo-url> Flipflow
git clone <circlekeeper-repo-url> CK
git clone <deployment-repo-url> deployment
```

### 2. Ordnerstruktur pruefen
```
/opt/
  Mythos/
  Flipflow/
  CK/
  deployment/
    docker-compose.yml
    setup.sh
    envs/
    nginx/
```

### 3. Setup-Skript ausfuehren
```bash
cd deployment
chmod +x setup.sh
./setup.sh
```

Das Skript fragt interaktiv nach:
- Domains fuer jede App
- E-Mail-Adresse fuer SSL-Zertifikate
- Generiert automatisch sichere JWT Secrets

### 4. API-Schluessel eintragen
```bash
nano envs/.env.mythos     # ANTHROPIC_API_KEY, OPENAI_API_KEY
nano envs/.env.flipflow    # EBAY_APP_ID, EBAY_CERT_ID, ETSY_API_KEY
docker compose restart
```

### 5. Pruefen
```bash
docker compose ps          # Alle Container laufen?
docker compose logs -f     # Logs anschauen
curl -I https://mythos.deinedomain.de  # SSL aktiv?
```

## Monitoring

### Container-Status
```bash
docker compose ps
```

### Logs anschauen
```bash
docker compose logs -f                 # Alle
docker compose logs -f mythos          # Nur Mythos
docker compose logs -f --tail=50       # Letzte 50 Zeilen
```

### Ressourcenverbrauch
```bash
docker stats
```

### Neustart einzelner Apps
```bash
docker compose restart mythos
docker compose restart flipflow
docker compose restart circlekeeper
```

## Backup

### SQLite-Datenbanken sichern
```bash
# Backup-Skript
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

## Updates

### App aktualisieren
```bash
cd /opt/Mythos && git pull
cd /opt/deployment && docker compose up -d --build mythos
```

### Alle Apps aktualisieren
```bash
cd /opt/Mythos && git pull
cd /opt/Flipflow && git pull
cd /opt/CK && git pull
cd /opt/deployment && docker compose up -d --build
```

## Fehlerbehebung

| Problem | Loesung |
|---------|---------|
| Container startet nicht | `docker compose logs appname` pruefen |
| SSL-Zertifikat fehlt | DNS pruefen, 2 Min warten, `docker compose restart letsencrypt` |
| 502 Bad Gateway | App-Container pruefen: `docker compose ps` |
| Port belegt | `sudo lsof -i :80` und blockierenden Prozess stoppen |
| Speicher voll | `docker system prune -a` (entfernt ungenutzte Images) |

## Kosten-Schaetzung

| Posten | Monatlich |
|--------|-----------|
| VPS (Hetzner CX22, 2 vCPU, 4GB) | ca. 6 EUR |
| Domain (.de) | ca. 1 EUR |
| **Gesamt** | **ca. 7 EUR** |

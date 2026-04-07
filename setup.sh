#!/usr/bin/env bash
set -euo pipefail

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  VPS Deployment Setup – Mythos, FliFlow, Circle Keeper                  ║
# ║  Dieses Skript konfiguriert alle Umgebungsvariablen, generiert          ║
# ║  Secrets und startet die Container.                                      ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Farben fuer Terminal-Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Keine Farbe

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         VPS Deployment Setup – 3 Apps, 1 Server             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Pruefung: Docker installiert? ──────────────────────────────────────────
echo -e "${YELLOW}[1/6] Pruefe Voraussetzungen...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}FEHLER: Docker ist nicht installiert.${NC}"
    echo "  Installation: https://docs.docker.com/engine/install/ubuntu/"
    echo "  curl -fsSL https://get.docker.com | sh"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo -e "${RED}FEHLER: Docker Compose (v2) ist nicht installiert.${NC}"
    echo "  Normalerweise mit Docker mitgeliefert."
    exit 1
fi

echo -e "${GREEN}  Docker: $(docker --version)${NC}"
echo -e "${GREEN}  Compose: $(docker compose version --short)${NC}"

# ── Pruefung: Quellcode-Verzeichnisse vorhanden? ──────────────────────────
MISSING=0
for dir in "../Mythos" "../Flipflow" "../CK"; do
    if [ ! -d "$dir" ]; then
        echo -e "${RED}FEHLER: Verzeichnis $dir nicht gefunden.${NC}"
        echo "  Bitte stelle sicher, dass alle Repos neben dem deployment-Ordner liegen."
        MISSING=1
    fi
done
if [ "$MISSING" -eq 1 ]; then
    exit 1
fi
echo -e "${GREEN}  Alle Quellcode-Verzeichnisse gefunden.${NC}"

# ── Domain-Konfiguration ──────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[2/6] Domain-Konfiguration${NC}"
echo "  Gib die Domains fuer jede App ein (oder druecke Enter fuer Standard):"
echo ""

read -p "  Mythos Domain     [mythos.example.com]: " DOMAIN_MYTHOS
DOMAIN_MYTHOS="${DOMAIN_MYTHOS:-mythos.example.com}"

read -p "  FliFlow Domain    [flipflow.example.com]: " DOMAIN_FLIPFLOW
DOMAIN_FLIPFLOW="${DOMAIN_FLIPFLOW:-flipflow.example.com}"

read -p "  CircleKeeper Domain [circlekeeper.example.com]: " DOMAIN_CK
DOMAIN_CK="${DOMAIN_CK:-circlekeeper.example.com}"

echo ""
read -p "  E-Mail fuer Let's Encrypt SSL [admin@example.com]: " LETSENCRYPT_EMAIL
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-admin@example.com}"

echo ""
echo -e "${GREEN}  Domains konfiguriert:${NC}"
echo "    Mythos:       https://$DOMAIN_MYTHOS"
echo "    FliFlow:      https://$DOMAIN_FLIPFLOW"
echo "    CircleKeeper: https://$DOMAIN_CK"
echo "    SSL-Email:    $LETSENCRYPT_EMAIL"

# ── JWT Secrets generieren ─────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[3/6] Generiere JWT Secrets...${NC}"

JWT_MYTHOS=$(openssl rand -hex 64)
JWT_FLIPFLOW=$(openssl rand -hex 64)

echo -e "${GREEN}  2 sichere JWT Secrets generiert (je 128 Zeichen).${NC}"

# ── Umgebungsvariablen aktualisieren ───────────────────────────────────────
echo ""
echo -e "${YELLOW}[4/6] Aktualisiere Konfigurationsdateien...${NC}"

# .env.mythos
sed -i.bak "s|APP_URL=.*|APP_URL=https://$DOMAIN_MYTHOS|" envs/.env.mythos
sed -i.bak "s|BACKEND_URL=.*|BACKEND_URL=https://$DOMAIN_MYTHOS|" envs/.env.mythos
sed -i.bak "s|JWT_SECRET=.*|JWT_SECRET=$JWT_MYTHOS|" envs/.env.mythos

# .env.flipflow
sed -i.bak "s|APP_URL=.*|APP_URL=https://$DOMAIN_FLIPFLOW|" envs/.env.flipflow
sed -i.bak "s|JWT_SECRET=.*|JWT_SECRET=$JWT_FLIPFLOW|" envs/.env.flipflow

# .env.circlekeeper
sed -i.bak "s|APP_URL=.*|APP_URL=https://$DOMAIN_CK|" envs/.env.circlekeeper

# docker-compose.yml – Domains und E-Mail ersetzen
sed -i.bak "s|mythos.example.com|$DOMAIN_MYTHOS|g" docker-compose.yml
sed -i.bak "s|flipflow.example.com|$DOMAIN_FLIPFLOW|g" docker-compose.yml
sed -i.bak "s|circlekeeper.example.com|$DOMAIN_CK|g" docker-compose.yml
sed -i.bak "s|admin@example.com|$LETSENCRYPT_EMAIL|g" docker-compose.yml

# Backup-Dateien aufraeumen
rm -f envs/.env.*.bak docker-compose.yml.bak

echo -e "${GREEN}  Alle Konfigurationen aktualisiert.${NC}"

# ── Datenverzeichnisse erstellen ───────────────────────────────────────────
echo ""
echo -e "${YELLOW}[5/6] Erstelle Datenverzeichnisse...${NC}"

mkdir -p data/mythos data/flipflow data/backups

echo -e "${GREEN}  Verzeichnisse erstellt: data/mythos, data/flipflow, data/backups${NC}"

# ── Container starten ─────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[6/6] Starte Docker Container...${NC}"
echo "  Dies kann beim ersten Mal einige Minuten dauern (Build-Prozess)."
echo ""

docker compose up -d --build

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    DEPLOYMENT ERFOLGREICH                     ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Status anzeigen
echo -e "${BLUE}Container-Status:${NC}"
docker compose ps
echo ""

echo -e "${BLUE}Zugriff:${NC}"
echo "  Mythos:       https://$DOMAIN_MYTHOS"
echo "  FliFlow:      https://$DOMAIN_FLIPFLOW"
echo "  CircleKeeper: https://$DOMAIN_CK"
echo ""

echo -e "${YELLOW}Hinweis:${NC}"
echo "  - SSL-Zertifikate werden automatisch erstellt (kann 1-2 Min dauern)"
echo "  - DNS muss auf die Server-IP zeigen (A-Record)"
echo "  - API-Schluessel in envs/.env.* eintragen und 'docker compose restart' ausfuehren"
echo ""

echo -e "${BLUE}Nuetzliche Befehle:${NC}"
echo "  docker compose logs -f              # Alle Logs"
echo "  docker compose logs -f mythos       # Nur Mythos Logs"
echo "  docker compose restart flipflow     # FliFlow neustarten"
echo "  docker compose down                 # Alles stoppen"
echo "  docker compose up -d --build        # Neu bauen und starten"

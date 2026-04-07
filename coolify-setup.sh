#!/usr/bin/env bash
set -euo pipefail

# Farben fuer Konsolenausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Coolify Setup – Self-Hosted PaaS fuer 3 Apps            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Pruefen ob als root ausgefuehrt
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Bitte als root ausfuehren: sudo ./coolify-setup.sh${NC}"
    exit 1
fi

# Schritt 1: Coolify installieren
echo -e "${YELLOW}[1/4] Installiere Coolify...${NC}"
echo "  Dies dauert 2-3 Minuten."
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# Schritt 2: Warten bis Coolify bereit ist
echo -e "${YELLOW}[2/4] Warte auf Coolify-Start...${NC}"
sleep 10
until curl -s http://localhost:8000/api/health > /dev/null 2>&1; do
    echo "  Warte auf Coolify..."
    sleep 5
done
echo -e "${GREEN}  Coolify laeuft auf Port 8000${NC}"

# Schritt 3: Firewall konfigurieren
echo -e "${YELLOW}[3/4] Konfiguriere Firewall...${NC}"
ufw allow 22/tcp 2>/dev/null || true
ufw allow 80/tcp 2>/dev/null || true
ufw allow 443/tcp 2>/dev/null || true
ufw allow 8000/tcp 2>/dev/null || true  # Coolify Dashboard
ufw --force enable 2>/dev/null || true
echo -e "${GREEN}  Firewall konfiguriert (22, 80, 443, 8000)${NC}"

# Schritt 4: Anleitung ausgeben
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              COOLIFY INSTALLATION ERFOLGREICH                 ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Naechste Schritte:${NC}"
echo ""
echo "  1. Oeffne im Browser:"
echo -e "     ${GREEN}http://${SERVER_IP}:8000${NC}"
echo ""
echo "  2. Erstelle Admin-Account (SOFORT machen!)"
echo ""
echo "  3. Fuege 3 Apps hinzu (New Resource > Public Repository):"
echo ""
echo "     App 1: https://github.com/Rawkeep/Mythos"
echo "       → Port: 3001"
echo "       → Health Check: /api/health"
echo "       → Env: NODE_ENV=production, JWT_SECRET=$(openssl rand -hex 32)"
echo ""
echo "     App 2: https://github.com/Rawkeep/FlipFlow-AI-Creator"
echo "       → Port: 3001"
echo "       → Health Check: /api/health"
echo "       → Env: NODE_ENV=production, JWT_SECRET=$(openssl rand -hex 32)"
echo ""
echo "     App 3: https://github.com/Rawkeep/circle-keeper"
echo "       → Port: 3000"
echo "       → Health Check: /api/health"
echo "       → Env: NODE_ENV=production"
echo ""
echo "  4. Domains zuweisen (Settings > Domains)"
echo "     DNS A-Record → ${SERVER_IP}"
echo ""
echo "  5. Deploy klicken — fertig!"
echo ""
echo -e "${YELLOW}Tipp: Coolify erstellt SSL-Zertifikate automatisch.${NC}"

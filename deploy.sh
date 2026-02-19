#!/bin/bash
# =============================================================================
# ActivEducation - Script de deploiement VPS Hostinger (avec Traefik)
# =============================================================================
# Architecture:
#   activeduhub.com       -> App Etudiante  (Flutter Web)
#   admin.activeduhub.com -> Admin Dashboard (Flutter Web)
#   api.activeduhub.com   -> Backend FastAPI
#
# Traefik gere automatiquement le SSL (Let's Encrypt) - pas de Certbot.
#
# Usage: sudo bash deploy.sh
#
# Prerequis AVANT de lancer ce script:
#   1. DNS: 4 enregistrements A pointant vers l'IP de ce serveur
#        activeduhub.com, www.activeduhub.com,
#        admin.activeduhub.com, api.activeduhub.com
#   2. traefik/traefik.yml: remplacer REMPLACER_PAR_VOTRE_EMAIL
#   3. backend/.env.production: remplir SUPABASE_KEY, SERVICE_ROLE_KEY, SECRET_KEY
#   4. Builds Flutter generes localement et uploades:
#        activ_education_app/build/web/
#        admin_dashboard/build/web/
# =============================================================================

set -euo pipefail

# ─── CONFIGURATION ────────────────────────────────────────────────────────────
DOMAIN="activeduhub.com"
ADMIN_DOMAIN="admin.activeduhub.com"
API_DOMAIN="api.activeduhub.com"
WWW_DOMAIN="www.activeduhub.com"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ──────────────────────────────────────────────────────────────────────────────

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}⚠${NC}  $1"; }
error()   { echo -e "${RED}${BOLD}✗${NC}  $1" >&2; exit 1; }
section() { echo -e "\n${BOLD}${BLUE}━━━ $1 ━━━${NC}"; }

# ─── VERIFICATIONS INITIALES ─────────────────────────────────────────────────

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        error "Ce script doit etre execute en tant que root: sudo bash deploy.sh"
    fi
}

check_traefik_config() {
    local traefik_config="$PROJECT_DIR/traefik/traefik.yml"
    if [[ ! -f "$traefik_config" ]]; then
        error "Fichier manquant: traefik/traefik.yml"
    fi
    if grep -q "REMPLACER_PAR_VOTRE_EMAIL" "$traefik_config"; then
        error "Email non configure dans traefik/traefik.yml!\nRemplacez REMPLACER_PAR_VOTRE_EMAIL par votre vraie adresse email (requis par Let's Encrypt)."
    fi
    success "traefik/traefik.yml configure"
}

check_env_file() {
    local env_file="$PROJECT_DIR/backend/.env.production"
    if [[ ! -f "$env_file" ]]; then
        error "Fichier manquant: backend/.env.production"
    fi
    local placeholders=("REMPLACER_PAR_VOTRE_SUPABASE_ANON_KEY" "REMPLACER_PAR_VOTRE_SERVICE_ROLE_KEY" "REMPLACER_PAR_UNE_CLE_SECRETE_MINIMUM_32_CARACTERES")
    for placeholder in "${placeholders[@]}"; do
        if grep -q "$placeholder" "$env_file"; then
            error "Valeur non configuree dans backend/.env.production: $placeholder"
        fi
    done
    success "backend/.env.production configure"
}

check_flutter_builds() {
    section "Verification des builds Flutter"

    local app_build="$PROJECT_DIR/activ_education_app/build/web"
    if [[ ! -d "$app_build" ]] || [[ ! -f "$app_build/index.html" ]]; then
        error "Build Flutter manquant: activ_education_app/build/web/index.html\n\nGenerez-le sur votre machine locale:\n  cd activ_education_app\n  flutter build web --release --dart-define=API_BASE_URL=https://api.activeduhub.com\nPuis re-uploadez le projet sur le VPS."
    fi
    success "Build app etudiante: activ_education_app/build/web/"

    local admin_build="$PROJECT_DIR/admin_dashboard/build/web"
    if [[ ! -d "$admin_build" ]] || [[ ! -f "$admin_build/index.html" ]]; then
        error "Build Flutter manquant: admin_dashboard/build/web/index.html\n\nGenerez-le sur votre machine locale:\n  cd admin_dashboard\n  flutter build web --release --dart-define=API_BASE_URL=https://api.activeduhub.com/api/v1\nPuis re-uploadez le projet sur le VPS."
    fi
    success "Build admin dashboard: admin_dashboard/build/web/"
}

# ─── INSTALLATION DEPENDANCES ─────────────────────────────────────────────────

install_dependencies() {
    section "Installation des dependances systeme"
    apt-get update -qq
    apt-get install -y -qq curl git ufw openssl
    success "Paquets systeme installes"
}

install_docker() {
    if command -v docker &>/dev/null; then
        success "Docker deja installe: $(docker --version)"
        return
    fi
    log "Installation de Docker..."
    curl -fsSL https://get.docker.com | bash -s
    systemctl enable docker --now
    success "Docker installe et demarre"
}

install_docker_compose() {
    if docker compose version &>/dev/null 2>&1; then
        success "Docker Compose deja installe: $(docker compose version)"
        return
    fi
    log "Installation de Docker Compose plugin..."
    apt-get install -y -qq docker-compose-plugin
    success "Docker Compose installe"
}

# ─── PARE-FEU ─────────────────────────────────────────────────────────────────

setup_firewall() {
    section "Configuration du pare-feu UFW"
    ufw --force reset > /dev/null 2>&1
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    success "Pare-feu configure (SSH + HTTP + HTTPS)"
}

# ─── PREPARATION TRAEFIK ──────────────────────────────────────────────────────

setup_traefik() {
    section "Preparation Traefik + Let's Encrypt"

    # Creer le repertoire de stockage des certificats
    mkdir -p "$PROJECT_DIR/traefik/letsencrypt"

    # acme.json doit exister avec permissions 600 avant le demarrage de Traefik
    local acme_file="$PROJECT_DIR/traefik/letsencrypt/acme.json"
    touch "$acme_file"
    chmod 600 "$acme_file"

    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org 2>/dev/null || echo "INCONNUE")
    warn "IP de ce serveur: $SERVER_IP"
    warn "Verifiez que ces 4 enregistrements DNS A pointent vers $SERVER_IP:"
    warn "  activeduhub.com        -> $SERVER_IP"
    warn "  www.activeduhub.com    -> $SERVER_IP"
    warn "  admin.activeduhub.com  -> $SERVER_IP"
    warn "  api.activeduhub.com    -> $SERVER_IP"
    echo ""
    warn "Si les DNS ne sont pas encore propagés, Traefik reessaiera automatiquement."
    echo ""

    success "Traefik prepare (acme.json cree avec permissions 600)"
}

# ─── DEMARRAGE ────────────────────────────────────────────────────────────────

start_all_services() {
    section "Demarrage de tous les services"
    cd "$PROJECT_DIR"

    # Arreter les anciens conteneurs si besoin (migration depuis nginx/certbot)
    docker compose down --remove-orphans 2>/dev/null || true

    # Demarrer avec la nouvelle configuration
    docker compose up -d --build

    success "Tous les services demarres (traefik + backend + app + admin)"
    log "Traefik obtient les certificats SSL automatiquement au premier acces."
    log "Cela peut prendre 30-60 secondes apres le demarrage."
}

# ─── VERIFICATION DE SANTE ───────────────────────────────────────────────────

health_check() {
    section "Verification de sante"
    log "Attente du demarrage complet (30 secondes)..."
    sleep 30

    local all_ok=true

    if curl -sf --max-time 15 "https://$API_DOMAIN/health" > /dev/null 2>&1; then
        success "API Backend:       https://$API_DOMAIN/health [OK]"
    else
        warn "API Backend:       https://$API_DOMAIN/health [En attente - verifiez: docker compose logs backend]"
        all_ok=false
    fi

    if curl -sf --max-time 15 "https://$DOMAIN" > /dev/null 2>&1; then
        success "App Etudiante:     https://$DOMAIN [OK]"
    else
        warn "App Etudiante:     https://$DOMAIN [En attente - verifiez: docker compose logs app-frontend]"
        all_ok=false
    fi

    if curl -sf --max-time 15 "https://$ADMIN_DOMAIN" > /dev/null 2>&1; then
        success "Admin Dashboard:   https://$ADMIN_DOMAIN [OK]"
    else
        warn "Admin Dashboard:   https://$ADMIN_DOMAIN [En attente - verifiez: docker compose logs admin-frontend]"
        all_ok=false
    fi

    echo ""
    log "Status des containers Docker:"
    cd "$PROJECT_DIR"
    docker compose ps

    if [[ "$all_ok" == "false" ]]; then
        echo ""
        warn "Certains services ne repondent pas encore - c'est normal si les DNS viennent d'etre configures."
        warn "Traefik reessaie d'obtenir les certificats automatiquement."
        warn "Reessayez dans 2-3 minutes: curl -I https://$DOMAIN"
        warn "Logs Traefik: docker compose logs -f traefik"
    fi
}

# ─── SUMMARY ─────────────────────────────────────────────────────────────────

print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║             DEPLOIEMENT TERMINE AVEC SUCCES!                ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                              ║"
    printf "║  App Etudiante:   https://%-34s ║\n" "$DOMAIN"
    printf "║  Admin Dashboard: https://%-34s ║\n" "$ADMIN_DOMAIN"
    printf "║  API Backend:     https://%-34s ║\n" "$API_DOMAIN"
    echo "║                                                              ║"
    echo "║  SSL: automatique via Traefik + Let's Encrypt               ║"
    echo "║  Renouvellement: automatique tous les 90 jours              ║"
    echo "║                                                              ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  Commandes utiles:                                           ║"
    echo "║  docker compose logs -f traefik      (logs Traefik/SSL)     ║"
    echo "║  docker compose logs -f backend      (logs API)             ║"
    echo "║  docker compose logs -f app-frontend (logs app web)         ║"
    echo "║  docker compose ps                   (status services)      ║"
    echo "║  docker compose restart backend      (redemarrer API)       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ─── MAIN ─────────────────────────────────────────────────────────────────────

main() {
    clear
    echo -e "${BOLD}${GREEN}"
    echo "  ActivEducation - Deploiement VPS Hostinger (Traefik + Let's Encrypt)"
    echo "  App: $DOMAIN | Admin: $ADMIN_DOMAIN | API: $API_DOMAIN"
    echo -e "${NC}"

    check_root
    check_traefik_config
    check_env_file
    check_flutter_builds

    install_dependencies
    install_docker
    install_docker_compose
    setup_firewall

    setup_traefik
    start_all_services
    health_check
    print_summary
}

main "$@"

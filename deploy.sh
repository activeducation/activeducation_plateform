#!/bin/bash
# =============================================================================
# ActivEducation - Script de deploiement VPS Hostinger
# Domaine: activeduhub.com | api.activeduhub.com
# =============================================================================
# Usage: sudo bash deploy.sh
# Prerequis: Projet uploade sur le VPS, .env.production configure
# =============================================================================

set -euo pipefail

# ─── CONFIGURATION ────────────────────────────────────────────────────────────
DOMAIN="activeduhub.com"
API_DOMAIN="api.activeduhub.com"
WWW_DOMAIN="www.activeduhub.com"
CERTBOT_EMAIL="REMPLACER_PAR_VOTRE_EMAIL"   # <-- Changez ceci avant de lancer!
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

check_email() {
    if [[ "$CERTBOT_EMAIL" == "REMPLACER_PAR_VOTRE_EMAIL" ]]; then
        error "Editez deploy.sh et remplacez CERTBOT_EMAIL par votre vraie adresse email!"
    fi
}

check_env_file() {
    local env_file="$PROJECT_DIR/backend/.env.production"
    if [[ ! -f "$env_file" ]]; then
        error "Fichier manquant: backend/.env.production\nCopiez et editez le fichier avec vos vraies valeurs."
    fi

    # Verifier que les valeurs placeholder ont ete remplacees
    local placeholders=("REMPLACER_PAR_VOTRE_SUPABASE_ANON_KEY" "REMPLACER_PAR_VOTRE_SERVICE_ROLE_KEY" "REMPLACER_PAR_UNE_CLE_SECRETE_MINIMUM_32_CARACTERES")
    for placeholder in "${placeholders[@]}"; do
        if grep -q "$placeholder" "$env_file"; then
            error "Valeur non configuree dans .env.production: $placeholder\nRemplissez toutes les valeurs avant de deployer."
        fi
    done
    success "Fichier .env.production valide"
}

check_flutter_build() {
    local build_dir="$PROJECT_DIR/admin_dashboard/build/web"
    if [[ ! -d "$build_dir" ]] || [[ ! -f "$build_dir/index.html" ]]; then
        error "Build Flutter Web manquant!\n\nSur votre machine locale (avant d'uploader):\n  cd admin_dashboard\n  flutter build web --release --dart-define=API_BASE_URL=https://api.activeduhub.com/api/v1\n\nPuis re-uploadez le projet complet sur le VPS."
    fi
    success "Build Flutter Web trouve"
}

# ─── INSTALLATION DEPENDANCES ─────────────────────────────────────────────────

install_dependencies() {
    section "Installation des dependances systeme"
    log "Mise a jour des paquets..."
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

# ─── PHASE 1: NGINX HTTP POUR CERTBOT ─────────────────────────────────────────

start_nginx_http() {
    section "Phase 1/3 - Nginx HTTP (validation Let's Encrypt)"

    # Creer les repertoires necessaires
    mkdir -p "$PROJECT_DIR/nginx/certbot/conf"
    mkdir -p "$PROJECT_DIR/nginx/certbot/www"

    # Utiliser la config HTTP initiale
    cp "$PROJECT_DIR/nginx/conf.d/init.conf" "$PROJECT_DIR/nginx/conf.d/activeduhub.conf"

    log "Demarrage de Nginx (HTTP)..."
    cd "$PROJECT_DIR"
    docker compose up -d nginx backend

    # Attendre que Nginx soit pret
    log "Attente de Nginx..."
    sleep 5

    if docker compose ps nginx | grep -q "Up"; then
        success "Nginx HTTP demarre"
    else
        error "Nginx n'a pas pu demarrer. Verifiez: docker compose logs nginx"
    fi
}

# ─── PHASE 2: CERTIFICAT SSL ─────────────────────────────────────────────────

get_ssl_certificate() {
    section "Phase 2/3 - Certificat SSL Let's Encrypt"

    log "Verification que les DNS pointent vers ce serveur..."
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org 2>/dev/null || echo "INCONNUE")
    warn "IP de ce serveur: $SERVER_IP"
    warn "Assurez-vous que ces DNS ont bien ete configures:"
    warn "  A  activeduhub.com      -> $SERVER_IP"
    warn "  A  www.activeduhub.com  -> $SERVER_IP"
    warn "  A  api.activeduhub.com  -> $SERVER_IP"
    echo ""

    log "Obtention du certificat SSL pour $DOMAIN, $WWW_DOMAIN, $API_DOMAIN..."
    cd "$PROJECT_DIR"
    docker compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$CERTBOT_EMAIL" \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d "$DOMAIN" \
        -d "$WWW_DOMAIN" \
        -d "$API_DOMAIN"

    success "Certificat SSL obtenu pour $DOMAIN"
}

# ─── PHASE 3: ACTIVATION HTTPS ────────────────────────────────────────────────

enable_https() {
    section "Phase 3/3 - Activation HTTPS"

    log "Remplacement de la config Nginx par la version HTTPS..."
    cp "$PROJECT_DIR/nginx/conf.d/ssl.conf" "$PROJECT_DIR/nginx/conf.d/activeduhub.conf"

    log "Rechargement de Nginx avec la config SSL..."
    cd "$PROJECT_DIR"
    docker compose exec nginx nginx -t  # Test de la config
    docker compose exec nginx nginx -s reload

    success "HTTPS active sur $DOMAIN et $API_DOMAIN"
}

# ─── DEMARRAGE COMPLET ────────────────────────────────────────────────────────

start_all_services() {
    section "Demarrage de tous les services"
    cd "$PROJECT_DIR"
    docker compose up -d
    success "Tous les services demarres (backend + nginx + certbot auto-renouvellement)"
}

# ─── VERIFICATION DE SANTE ───────────────────────────────────────────────────

health_check() {
    section "Verification de sante"
    log "Attente du demarrage complet (20 secondes)..."
    sleep 20

    # Test API
    if curl -sf --max-time 10 "https://$API_DOMAIN/health" > /dev/null 2>&1; then
        success "API Backend:      https://$API_DOMAIN/health [OK]"
    else
        warn "API Backend:      https://$API_DOMAIN/health [En cours de demarrage - reessayez dans 30s]"
    fi

    # Test Dashboard
    if curl -sf --max-time 10 "https://$DOMAIN" > /dev/null 2>&1; then
        success "Admin Dashboard:  https://$DOMAIN [OK]"
    else
        warn "Admin Dashboard:  https://$DOMAIN [En cours de demarrage - reessayez dans 30s]"
    fi

    # Status des containers
    echo ""
    log "Status des containers Docker:"
    cd "$PROJECT_DIR"
    docker compose ps
}

# ─── SUMMARY ─────────────────────────────────────────────────────────────────

print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║            DEPLOIEMENT TERMINE AVEC SUCCES!             ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║                                                          ║"
    printf "║  Admin Dashboard: https://%-30s ║\n" "$DOMAIN"
    printf "║  API Backend:     https://%-30s ║\n" "$API_DOMAIN"
    echo "║                                                          ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║  Commandes utiles:                                       ║"
    echo "║  docker compose logs -f backend   (logs API)            ║"
    echo "║  docker compose logs -f nginx     (logs Nginx)          ║"
    echo "║  docker compose restart backend   (redemarrer API)      ║"
    echo "║  docker compose ps                (status services)     ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ─── MAIN ─────────────────────────────────────────────────────────────────────

main() {
    clear
    echo -e "${BOLD}${GREEN}"
    echo "  ActivEducation - Deploiement VPS Hostinger"
    echo "  Domaine: activeduhub.com"
    echo -e "${NC}"

    check_root
    check_email
    check_env_file
    check_flutter_build

    install_dependencies
    install_docker
    install_docker_compose
    setup_firewall

    start_nginx_http
    get_ssl_certificate
    enable_https
    start_all_services
    health_check
    print_summary
}

main "$@"

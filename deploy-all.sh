#!/bin/bash
# =============================================================================
# ActivEducation - Script de déploiement tout-en-un
# =============================================================================
# Ce script gère TOUT depuis votre machine locale :
#   1. Vérifie les prérequis (Flutter, configs)
#   2. Builde les 2 applications Flutter Web
#   3. Upload le projet complet vers le VPS via SSH
#   4. Installe Docker, configure Traefik et démarre tous les services
#   5. Le SSL Let's Encrypt est obtenu automatiquement par Traefik
#
# Compatible : WSL (recommandé) et Git Bash
# Usage      : bash deploy-all.sh
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── COULEURS ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; CYAN='\033[0;36m'; NC='\033[0m'
log()     { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}  ✓${NC} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}  ⚠${NC}  $1"; }
error()   { echo -e "\n${RED}${BOLD}  ✗ ERREUR:${NC} $1\n" >&2; exit 1; }
section() { echo -e "\n${BOLD}${CYAN}  ┌─ $1 ─────────────────────────────────${NC}"; }
ask()     { echo -e "${BOLD}  → ${NC}$1"; }

# ─── DÉTECTION DE L'ENVIRONNEMENT ────────────────────────────────────────────
detect_environment() {
    if grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
        ENV_TYPE="wsl"
    else
        ENV_TYPE="gitbash"
    fi
}

# ─── BANNIÈRE ────────────────────────────────────────────────────────────────
banner() {
    clear
    echo -e "${GREEN}${BOLD}"
    echo "  ╔════════════════════════════════════════════════════════════╗"
    echo "  ║           ActivEducation — Déploiement Complet            ║"
    echo "  ║     Build Flutter + Upload VPS + Docker + SSL auto        ║"
    echo "  ╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    if [[ "$ENV_TYPE" == "wsl" ]]; then
        success "Environnement détecté : WSL (Windows Subsystem for Linux)"
    else
        success "Environnement détecté : Git Bash"
    fi
    echo ""
}

# ─── INSTALLATION AUTOMATIQUE DE FLUTTER (WSL uniquement) ────────────────────
install_flutter_wsl() {
    warn "Flutter n'est pas installé dans WSL."
    echo ""
    echo "  Flutter doit être installé dans l'environnement Linux de WSL"
    echo "  (le Flutter Windows ne fonctionne pas depuis WSL)."
    echo ""
    ask "Installer Flutter automatiquement dans WSL ? (o/n) [o] :"
    read -r INSTALL_FLUTTER
    INSTALL_FLUTTER="${INSTALL_FLUTTER:-o}"
    [[ ! "$INSTALL_FLUTTER" =~ ^[oOyY1] ]] && \
        error "Flutter requis pour builder les apps.\nInstallez-le manuellement :\n  https://docs.flutter.dev/get-started/install/linux/web"

    section "Installation de Flutter dans WSL"
    log "Installation des dépendances système..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build libgtk-3-dev

    log "Téléchargement de Flutter (branche stable)..."
    FLUTTER_HOME="$HOME/flutter"
    if [[ -d "$FLUTTER_HOME" ]]; then
        log "Dossier Flutter existant trouvé, mise à jour..."
        git -C "$FLUTTER_HOME" pull --quiet
    else
        git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_HOME" --quiet
    fi

    # Ajouter Flutter au PATH pour cette session et les suivantes
    export PATH="$PATH:$FLUTTER_HOME/bin"
    if ! grep -q "flutter/bin" "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$PATH:$HOME/flutter/bin"' >> "$HOME/.bashrc"
    fi

    log "Précache Flutter pour le web..."
    flutter precache --web --quiet

    success "Flutter installé : $(flutter --version 2>/dev/null | head -1)"
    echo ""
    warn "Pour les prochaines sessions WSL, Flutter sera disponible automatiquement."
}

# ─── VÉRIFICATION DU CHEMIN DU PROJET (WSL) ──────────────────────────────────
check_project_path_wsl() {
    # Avertir si le projet est sur un disque Windows (/mnt/c, /mnt/d, etc.)
    if [[ "$SCRIPT_DIR" =~ ^/mnt/[a-zA-Z]/ ]]; then
        warn "Le projet est sur un disque Windows : $SCRIPT_DIR"
        warn "Les builds Flutter depuis /mnt/ sont plus lents (filesystem NTFS)."
        echo ""
        echo "  Option A (recommandée) : Copier le projet dans WSL pour builder plus vite"
        echo "    cp -r $SCRIPT_DIR ~/activeducation && cd ~/activeducation && bash deploy-all.sh"
        echo ""
        echo "  Option B : Continuer depuis le disque Windows (plus lent, mais ça marche)"
        echo ""
        ask "Continuer depuis le disque Windows ? (o/n) [o] :"
        read -r CONTINUE_NTFS
        CONTINUE_NTFS="${CONTINUE_NTFS:-o}"
        [[ ! "$CONTINUE_NTFS" =~ ^[oOyY1] ]] && {
            echo ""
            echo "  Copiez le projet dans WSL, puis relancez :"
            echo "    cp -r \"$SCRIPT_DIR\" ~/activeducation"
            echo "    bash ~/activeducation/deploy-all.sh"
            exit 0
        }
    fi
}

# ─── VÉRIFICATIONS PRÉREQUIS ─────────────────────────────────────────────────
check_prerequisites() {
    section "Vérifications locales"

    # Flutter SDK
    if ! command -v flutter &>/dev/null; then
        if [[ "$ENV_TYPE" == "wsl" ]]; then
            install_flutter_wsl
        else
            error "Flutter SDK non trouvé dans le PATH.\nInstallez Flutter pour Windows :\n  https://docs.flutter.dev/get-started/install/windows/web"
        fi
    fi
    FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -1 || echo "version inconnue")
    success "Flutter SDK : $FLUTTER_VERSION"

    # traefik/traefik.yml
    local traefik_cfg="$SCRIPT_DIR/traefik/traefik.yml"
    [[ ! -f "$traefik_cfg" ]] && error "Fichier manquant : traefik/traefik.yml"
    if grep -q "REMPLACER_PAR_VOTRE_EMAIL" "$traefik_cfg"; then
        error "Email non configuré dans traefik/traefik.yml\nOuvrez ce fichier et remplacez 'REMPLACER_PAR_VOTRE_EMAIL' par votre adresse email."
    fi
    success "traefik/traefik.yml : OK"

    # backend/.env.production
    local env_file="$SCRIPT_DIR/backend/.env.production"
    [[ ! -f "$env_file" ]] && error "Fichier manquant : backend/.env.production"
    local placeholders=("REMPLACER_PAR_VOTRE_SUPABASE_ANON_KEY" "REMPLACER_PAR_VOTRE_SERVICE_ROLE_KEY" "REMPLACER_PAR_UNE_CLE_SECRETE_MINIMUM_32_CARACTERES")
    for p in "${placeholders[@]}"; do
        if grep -q "$p" "$env_file"; then
            error "Valeur non configurée dans backend/.env.production :\n  $p"
        fi
    done
    success "backend/.env.production : OK"
}

# ─── CONNEXION VPS ────────────────────────────────────────────────────────────
collect_vps_info() {
    section "Connexion au VPS"

    ask "Adresse IP du VPS Hostinger :"
    read -r VPS_IP
    [[ -z "$VPS_IP" ]] && error "L'adresse IP est requise."

    ask "Utilisateur SSH [root] :"
    read -r VPS_USER
    VPS_USER="${VPS_USER:-root}"

    ask "Répertoire de déploiement sur le VPS [/var/www/activeducation] :"
    read -r VPS_DIR_INPUT
    VPS_DIR="${VPS_DIR_INPUT:-/var/www/activeducation}"

    echo ""
    warn "Méthode d'authentification SSH :"
    echo "    1) Clé SSH  (recommandé)"
    if [[ "$ENV_TYPE" == "wsl" ]]; then
        echo "       Chemin ex : ~/.ssh/id_rsa  ou  /mnt/c/Users/VotreNom/.ssh/id_rsa"
    else
        echo "       Chemin ex : ~/.ssh/id_rsa  ou  C:/Users/VotreNom/.ssh/id_rsa"
    fi
    echo "    2) Mot de passe"
    echo "    3) Clé SSH par défaut du système (~/.ssh/id_rsa)"
    ask "Votre choix [1/2/3] :"
    read -r AUTH_CHOICE
    AUTH_CHOICE="${AUTH_CHOICE:-3}"

    SSH_OPTS="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=30 -o ServerAliveInterval=30 -o ServerAliveCountMax=6"

    case "$AUTH_CHOICE" in
        1)
            if [[ "$ENV_TYPE" == "wsl" ]]; then
                ask "Chemin vers la clé SSH (ex: ~/.ssh/id_rsa ou /mnt/c/Users/VotreNom/.ssh/id_rsa) :"
            else
                ask "Chemin vers la clé SSH (ex: ~/.ssh/id_rsa) :"
            fi
            read -r SSH_KEY_PATH

            # Expansion manuelle du ~ si nécessaire
            SSH_KEY_PATH="${SSH_KEY_PATH/#\~/$HOME}"

            # Git Bash uniquement : convertir chemin Windows style (C:\...) en Unix
            if [[ "$ENV_TYPE" == "gitbash" ]]; then
                SSH_KEY_PATH="${SSH_KEY_PATH/C:\//\/c\/}"
                SSH_KEY_PATH="${SSH_KEY_PATH//\\/\/}"
            fi

            [[ ! -f "$SSH_KEY_PATH" ]] && error "Clé SSH introuvable : $SSH_KEY_PATH"

            # WSL : si la clé vient de /mnt/ elle peut avoir des permissions trop ouvertes
            if [[ "$ENV_TYPE" == "wsl" && "$SSH_KEY_PATH" =~ ^/mnt/ ]]; then
                # Copier la clé dans WSL pour pouvoir changer ses permissions
                local WSL_KEY="$HOME/.ssh/hostinger_deploy_key"
                mkdir -p "$HOME/.ssh"
                cp "$SSH_KEY_PATH" "$WSL_KEY"
                chmod 600 "$WSL_KEY"
                SSH_KEY_PATH="$WSL_KEY"
                warn "Clé copiée dans WSL : $WSL_KEY (permissions 600 appliquées)"
            else
                chmod 600 "$SSH_KEY_PATH" 2>/dev/null || true
            fi

            SSH_OPTS="$SSH_OPTS -i $SSH_KEY_PATH"
            ;;
        2)
            if ! command -v sshpass &>/dev/null; then
                if [[ "$ENV_TYPE" == "wsl" ]]; then
                    log "Installation de sshpass..."
                    sudo apt-get install -y -qq sshpass
                else
                    error "sshpass non installé.\nInstallez-le via Chocolatey : choco install sshpass\nOu utilisez une clé SSH (option 1)."
                fi
            fi
            ask "Mot de passe SSH du VPS :"
            read -rs SSH_PASSWORD
            echo ""
            SSH_OPTS="$SSH_OPTS"  # sshpass s'ajoute à la commande plus bas
            ;;
        3)
            : # Utilise la clé par défaut ~/.ssh/id_rsa
            ;;
        *)
            error "Choix invalide."
            ;;
    esac

    # Construction de la commande SSH finale
    if [[ "${AUTH_CHOICE}" == "2" ]]; then
        SSH_CMD="sshpass -p $SSH_PASSWORD ssh $SSH_OPTS $VPS_USER@$VPS_IP"
    else
        SSH_CMD="ssh $SSH_OPTS $VPS_USER@$VPS_IP"
    fi

    # Test de connexion
    log "Test de connexion SSH vers ${VPS_USER}@${VPS_IP}..."
    if ! $SSH_CMD "echo 'Connexion SSH OK'" 2>/dev/null | grep -q "OK"; then
        error "Impossible de se connecter au VPS.\n  Vérifiez :\n  - L'IP : $VPS_IP\n  - L'utilisateur : $VPS_USER\n  - Votre clé SSH ou mot de passe\n  - Que le port 22 est ouvert"
    fi
    success "Connexion SSH établie → ${VPS_USER}@${VPS_IP}"
}

# ─── BUILD FLUTTER WEB ────────────────────────────────────────────────────────
build_flutter_apps() {
    section "Build des applications Flutter Web"

    # App étudiante
    log "Build de l'app étudiante (activeduhub.com)..."
    cd "$SCRIPT_DIR/activ_education_app"
    flutter pub get --quiet
    flutter build web --release \
        --dart-define=API_BASE_URL=https://api.activeduhub.com \
        2>&1 | tail -5
    [[ ! -f "build/web/index.html" ]] && error "Le build de l'app étudiante a échoué."
    success "App étudiante buildée → activ_education_app/build/web/"

    # Dashboard admin
    log "Build du dashboard admin (admin.activeduhub.com)..."
    cd "$SCRIPT_DIR/admin_dashboard"
    flutter pub get --quiet
    flutter build web --release \
        --dart-define=API_BASE_URL=https://api.activeduhub.com/api/v1 \
        2>&1 | tail -5
    [[ ! -f "build/web/index.html" ]] && error "Le build du dashboard admin a échoué."
    success "Dashboard admin buildé → admin_dashboard/build/web/"

    cd "$SCRIPT_DIR"
}

# ─── UPLOAD VERS LE VPS ───────────────────────────────────────────────────────
upload_to_vps() {
    section "Upload du projet vers le VPS"

    log "Création du répertoire distant : $VPS_DIR"
    $SSH_CMD "mkdir -p $VPS_DIR"

    log "Compression et transfert en cours..."
    log "(1-3 minutes selon votre connexion)"

    tar -czf - \
        --exclude='.git' \
        --exclude='.dart_tool' \
        --exclude='*/.dart_tool' \
        --exclude='*/venv' \
        --exclude='*/.venv' \
        --exclude='*/__pycache__' \
        --exclude='*/.flutter-plugins' \
        --exclude='*/.flutter-plugins-dependencies' \
        --exclude='traefik/letsencrypt/acme.json' \
        --exclude='backend/.env' \
        --exclude='*/node_modules' \
        --exclude='*/.pytest_cache' \
        -C "$SCRIPT_DIR" . | \
        $SSH_CMD "cd '$VPS_DIR' && tar -xzf - && echo '-- Extraction terminée --'"

    success "Projet uploadé vers ${VPS_USER}@${VPS_IP}:${VPS_DIR}"
}

# ─── DÉPLOIEMENT SUR LE VPS ──────────────────────────────────────────────────
deploy_on_vps() {
    section "Déploiement sur le VPS"
    log "Lancement de deploy.sh sur le VPS..."
    log "(Docker, Traefik, backend, frontends, SSL automatique)"
    log "Durée estimée : 3-8 minutes selon la vitesse du VPS"
    echo ""

    local IS_ROOT
    IS_ROOT=$($SSH_CMD "id -u" 2>/dev/null || echo "1")

    if [[ "$IS_ROOT" == "0" ]]; then
        $SSH_CMD "cd '$VPS_DIR' && bash deploy.sh"
    else
        $SSH_CMD "cd '$VPS_DIR' && sudo bash deploy.sh"
    fi
}

# ─── RÉSUMÉ FINAL ─────────────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║              DÉPLOIEMENT RÉUSSI !                          ║"
    echo "  ╠══════════════════════════════════════════════════════════════╣"
    echo "  ║                                                              ║"
    echo "  ║   App étudiante :   https://activeduhub.com                ║"
    echo "  ║   Dashboard admin : https://admin.activeduhub.com          ║"
    echo "  ║   API Backend :     https://api.activeduhub.com            ║"
    echo "  ║                                                              ║"
    echo "  ║   SSL : automatique via Traefik + Let's Encrypt             ║"
    echo "  ║   Renouvellement : automatique tous les 90 jours           ║"
    echo "  ╠══════════════════════════════════════════════════════════════╣"
    echo "  ║   Pour les mises à jour futures :                           ║"
    echo "  ║     bash deploy-all.sh                                      ║"
    echo "  ║                                                              ║"
    echo "  ║   Commandes utiles sur le VPS :                             ║"
    echo "  ║     docker compose logs -f traefik                         ║"
    echo "  ║     docker compose logs -f backend                         ║"
    echo "  ║     docker compose ps                                       ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ─── MAIN ────────────────────────────────────────────────────────────────────
main() {
    detect_environment
    banner

    # Avertissement chemin Windows depuis WSL
    if [[ "$ENV_TYPE" == "wsl" ]]; then
        check_project_path_wsl
    fi

    check_prerequisites
    collect_vps_info

    # Choix build Flutter
    echo ""
    section "Builds Flutter"
    ask "Rebuilder les apps Flutter ? (o = oui, n = utiliser les builds existants) [o] :"
    read -r BUILD_CHOICE
    BUILD_CHOICE="${BUILD_CHOICE:-o}"

    if [[ "$BUILD_CHOICE" =~ ^[oOyY1] ]]; then
        build_flutter_apps
    else
        warn "Build Flutter ignoré. Vérification des builds existants..."
        [[ ! -f "$SCRIPT_DIR/activ_education_app/build/web/index.html" ]] && \
            error "Build manquant : activ_education_app/build/web/\nRelancez et choisissez 'o' pour builder."
        [[ ! -f "$SCRIPT_DIR/admin_dashboard/build/web/index.html" ]] && \
            error "Build manquant : admin_dashboard/build/web/\nRelancez et choisissez 'o' pour builder."
        success "Builds existants trouvés"
    fi

    # Confirmation
    echo ""
    warn "Récapitulatif :"
    echo "    VPS         : ${VPS_USER}@${VPS_IP}"
    echo "    Répertoire  : ${VPS_DIR}"
    echo "    App         : https://activeduhub.com"
    echo "    Admin       : https://admin.activeduhub.com"
    echo "    API         : https://api.activeduhub.com"
    echo ""
    ask "Lancer le déploiement ? (o/n) [o] :"
    read -r CONFIRM
    CONFIRM="${CONFIRM:-o}"
    [[ ! "$CONFIRM" =~ ^[oOyY1] ]] && { echo "Déploiement annulé."; exit 0; }

    upload_to_vps
    deploy_on_vps
    print_summary
}

main "$@"

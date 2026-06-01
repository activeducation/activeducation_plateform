#!/usr/bin/env bash
# Deploiement du fix police Hanken Grotesque (admin + app etudiant).
# Les 2 builds web sont deja generes localement avec la police bundlee.
#
# Usage :
#   bash deploy-fonts-fix.sh
# (demande le mot de passe root du VPS une fois si sshpass est installe,
#  sinon ssh/scp le demanderont a chaque etape)

set -euo pipefail

VPS_USER="root"
VPS_IP="185.98.128.154"
ADMIN_LOCAL="admin_dashboard/build/web"
APP_LOCAL="activ_education_app/build/web"
ADMIN_REMOTE="/opt/activeducation/admin_dashboard/build/web"
APP_REMOTE="/opt/activeducation/activ_education_app/build/web"
TS="$(date +%Y%m%d-%H%M%S)"

# --- Verifs locales : la police DOIT etre dans les builds ---
check_build() {
  local web="$1" name="$2"
  if [ ! -f "$web/main.dart.js" ]; then echo "ERREUR: $name/main.dart.js manquant — relance flutter build web."; exit 1; fi
  if ! grep -q "Hanken Grotesque" "$web/assets/FontManifest.json" 2>/dev/null; then
    echo "ERREUR: $name FontManifest sans Hanken Grotesque — build non valide."; exit 1
  fi
  echo "OK $name : build present + police Hanken declaree."
}
check_build "$ADMIN_LOCAL" "admin"
check_build "$APP_LOCAL" "app"

# --- sshpass optionnel (sinon prompt manuel a chaque commande) ---
SSH="ssh -o StrictHostKeyChecking=no"
SCP="scp -o StrictHostKeyChecking=no"
if command -v sshpass >/dev/null 2>&1; then
  read -rsp "Mot de passe root@$VPS_IP : " VPS_PWD; echo
  SSH="sshpass -p $VPS_PWD $SSH"
  SCP="sshpass -p $VPS_PWD $SCP"
fi

echo "=== 1/4 Upload build admin ==="
$SCP -r "$ADMIN_LOCAL" "$VPS_USER@$VPS_IP:/tmp/new-admin-$TS"

echo "=== 2/4 Upload build app ==="
$SCP -r "$APP_LOCAL" "$VPS_USER@$VPS_IP:/tmp/new-app-$TS"

echo "=== 3/4 Swap + restart admin ==="
$SSH "$VPS_USER@$VPS_IP" "
  set -e
  grep -q 'Hanken Grotesque' /tmp/new-admin-$TS/assets/FontManifest.json
  mv $ADMIN_REMOTE ${ADMIN_REMOTE}.OLD.$TS
  mv /tmp/new-admin-$TS $ADMIN_REMOTE
  docker restart activeducation-admin
  echo 'admin OK'
"

echo "=== 4/4 Swap + restart app ==="
$SSH "$VPS_USER@$VPS_IP" "
  set -e
  grep -q 'Hanken Grotesque' /tmp/new-app-$TS/assets/FontManifest.json
  mv $APP_REMOTE ${APP_REMOTE}.OLD.$TS
  mv /tmp/new-app-$TS $APP_REMOTE
  docker restart activeducation-app
  echo 'app OK'
"

echo
echo "=== DEPLOIEMENT TERMINE ==="
echo "Verifie en navigation privee :"
echo "  - https://admin.activeducationhub.com  (le dashboard doit s'afficher, plus de page blanche)"
echo "  - https://activeducationhub.com"
echo "Si l'ancienne version persiste : Ctrl+Shift+R (vide le cache du service worker)."
echo "Rollback eventuel : mv ${ADMIN_REMOTE}.OLD.$TS $ADMIN_REMOTE && docker restart activeducation-admin"

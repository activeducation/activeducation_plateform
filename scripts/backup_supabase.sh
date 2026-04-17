#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# backup_supabase.sh — snapshot manuel de la base Supabase (PostgreSQL).
#
# Usage:
#   ./backup_supabase.sh                   # snapshot -> storage/backups/<date>.sql.gz
#   ./backup_supabase.sh --restore FILE    # restaure depuis FILE (destructif)
#
# Variables requises:
#   DATABASE_URL   postgresql://user:pwd@host:5432/dbname
#                  (ou SUPABASE_DB_HOST + SUPABASE_DB_PASSWORD avec user=postgres)
#
# Variables optionnelles:
#   BACKUP_DIR     Repertoire de sortie (defaut: ./storage/backups)
#   AGE_PUBLIC_KEY Cle age pour chiffrer le dump (recommande hors-site)
# -----------------------------------------------------------------------------
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-./storage/backups}"
RESTORE_MODE=0
RESTORE_FILE=""

if [[ "${1:-}" == "--restore" ]]; then
  if [[ -z "${2:-}" ]]; then
    echo "ERREUR: --restore requiert un chemin de fichier" >&2
    exit 1
  fi
  RESTORE_MODE=1
  RESTORE_FILE="$2"
fi

# Resolution de DATABASE_URL si absente
if [[ -z "${DATABASE_URL:-}" ]]; then
  if [[ -n "${SUPABASE_DB_HOST:-}" && -n "${SUPABASE_DB_PASSWORD:-}" ]]; then
    DATABASE_URL="postgresql://postgres:${SUPABASE_DB_PASSWORD}@${SUPABASE_DB_HOST}:5432/postgres"
  else
    echo "ERREUR: DATABASE_URL (ou SUPABASE_DB_HOST + SUPABASE_DB_PASSWORD) requis" >&2
    exit 1
  fi
fi

# Verifier les outils
command -v pg_dump >/dev/null || { echo "ERREUR: pg_dump non installe (apt install postgresql-client-16)" >&2; exit 1; }
command -v gzip >/dev/null || { echo "ERREUR: gzip non installe" >&2; exit 1; }

# ----- RESTORE -----
if [[ $RESTORE_MODE -eq 1 ]]; then
  if [[ ! -f "$RESTORE_FILE" ]]; then
    echo "ERREUR: fichier introuvable: $RESTORE_FILE" >&2
    exit 1
  fi
  echo "=== RESTAURATION (destructif) depuis $RESTORE_FILE ==="
  read -r -p "Tape 'RESTORE' pour confirmer: " confirm
  [[ "$confirm" == "RESTORE" ]] || { echo "Abandon."; exit 1; }

  # Detection format: .age -> dechiffrer, .gz -> decompresser
  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT

  if [[ "$RESTORE_FILE" == *.age ]]; then
    command -v age >/dev/null || { echo "ERREUR: age non installe" >&2; exit 1; }
    age --decrypt --identity "${AGE_IDENTITY_FILE:-$HOME/.age/key.txt}" "$RESTORE_FILE" | gunzip > "$TMP"
  elif [[ "$RESTORE_FILE" == *.gz ]]; then
    gunzip -c "$RESTORE_FILE" > "$TMP"
  else
    cp "$RESTORE_FILE" "$TMP"
  fi

  psql "$DATABASE_URL" < "$TMP"
  echo "=== Restauration terminee ==="
  exit 0
fi

# ----- BACKUP -----
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
BASE_NAME="activeducation_${TIMESTAMP}.sql.gz"
OUT_PATH="${BACKUP_DIR}/${BASE_NAME}"

echo "=== Backup Supabase ==="
echo "Dest: $OUT_PATH"

# Options pg_dump: schema + data, pas d'objets proprietaires, format plain (portable)
pg_dump "$DATABASE_URL" \
  --no-owner --no-privileges \
  --exclude-schema='auth' --exclude-schema='storage' --exclude-schema='realtime' \
  --exclude-schema='supabase_functions' --exclude-schema='graphql' --exclude-schema='graphql_public' \
  --exclude-schema='pgsodium' --exclude-schema='pgsodium_masks' --exclude-schema='vault' \
  | gzip -9 > "$OUT_PATH"

echo "Taille: $(du -h "$OUT_PATH" | cut -f1)"

# Chiffrement optionnel avec age
if [[ -n "${AGE_PUBLIC_KEY:-}" ]]; then
  command -v age >/dev/null || { echo "AVERTISSEMENT: AGE_PUBLIC_KEY defini mais 'age' non installe" >&2; exit 0; }
  age --encrypt --recipient "$AGE_PUBLIC_KEY" --output "${OUT_PATH}.age" "$OUT_PATH"
  rm "$OUT_PATH"
  echo "Chiffre: ${OUT_PATH}.age"
fi

# Rotation: garder les 14 derniers
find "$BACKUP_DIR" -name 'activeducation_*.sql.gz*' -type f -printf '%T@ %p\n' \
  | sort -n | head -n -14 | cut -d' ' -f2- | xargs -r rm -f

echo "=== Termine ==="

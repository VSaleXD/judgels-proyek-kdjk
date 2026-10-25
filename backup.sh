#!/usr/bin/env bash
#
# backup.sh - Skrip Otomatisasi Backup Database & File Judgels
#
set -Eeuo pipefail

BASE_DIR="${BASE_DIR:-/opt/judgels}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backup-judgels}"
DATE="$(date +%F_%H%M%S)"

log() { printf '[INFO] %s\n' "$*"; }
ok()  { printf '[ OK ] %s\n' "$*"; }
die() { printf '[FAIL] %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Jalankan skrip ini sebagai root atau dengan sudo."

# Cari file .env
ENV_FILE="$BASE_DIR/.env"
[ -f "$ENV_FILE" ] || ENV_FILE="./.env"
[ -f "$ENV_FILE" ] || die "File .env tidak ditemukan di $BASE_DIR atau direktori saat ini."

# shellcheck disable=SC1090
. "$ENV_FILE"

DB_CONTAINER="judgels-db"
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
  if docker ps --format '{{.Names}}' | grep -q "^judgels-mysql$"; then
    DB_CONTAINER="judgels-mysql"
  else
    die "Kontainer database (judgels-db atau judgels-mysql) tidak sedang berjalan."
  fi
fi

mkdir -p "$BACKUP_DIR"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

log "1. Backup database MySQL ($DB_NAME)..."
docker exec "$DB_CONTAINER" mysqldump -u root -p"${DB_ROOT_PASSWORD}" "${DB_NAME}" > "$TEMP_DIR/database.sql"
ok "Dump database selesai."

log "2. Backup file data server (soal, testcase, submission)..."
if [ -d "$BASE_DIR/server/var/data" ]; then
  cp -r "$BASE_DIR/server/var/data" "$TEMP_DIR/server_data"
elif docker ps --format '{{.Names}}' | grep -q "^judgels-server$"; then
  docker cp judgels-server:/judgels/server/var/data "$TEMP_DIR/server_data"
else
  mkdir -p "$TEMP_DIR/server_data"
fi
ok "File data berhasil disalin."

log "3. Backup file konfigurasi..."
cp "$ENV_FILE" "$TEMP_DIR/.env"
if [ -d "$BASE_DIR/conf" ]; then
  cp -r "$BASE_DIR/conf" "$TEMP_DIR/conf"
fi

ARCHIVE_FILE="$BACKUP_DIR/judgels-backup-$DATE.tar.gz"
log "4. Mengompresi seluruh cadangan ke $ARCHIVE_FILE ..."
tar -czf "$ARCHIVE_FILE" -C "$TEMP_DIR" .
ok "Backup selesai! File cadangan tersimpan di:"
echo "   $ARCHIVE_FILE"

# Hapus backup yang lebih lama dari 30 hari secara otomatis
find "$BACKUP_DIR" -type f -name 'judgels-backup-*.tar.gz' -mtime +30 -delete 2>/dev/null || true

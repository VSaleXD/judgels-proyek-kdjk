#!/usr/bin/env bash
#
# restore.sh - Skrip Otomatisasi Pemulihan Basis Data & Berkas Judgels
#
set -Eeuo pipefail

BACKUP_FILE="${1:-}"
BASE_DIR="${BASE_DIR:-/opt/judgels}"

log() { printf '[INFO] %s\n' "$*"; }
ok()  { printf '[ OK ] %s\n' "$*"; }
die() { printf '[FAIL] %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Jalankan skrip ini sebagai root atau dengan sudo."
[ -n "$BACKUP_FILE" ] || die "Pemakaian: sudo ./restore.sh <path/to/judgels-backup-YYYY-MM-DD.tar.gz>"
[ -f "$BACKUP_FILE" ] || die "Berkas backup tidak ditemukan: $BACKUP_FILE"

ENV_FILE="$BASE_DIR/.env"
[ -f "$ENV_FILE" ] || ENV_FILE="./.env"
[ -f "$ENV_FILE" ] || die "Berkas .env tidak ditemukan di $BASE_DIR atau direktori saat ini."

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

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

log "1. Mengekstrak berkas arsip cadangan..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

if [ -f "$TEMP_DIR/database.sql" ]; then
  log "2. Memulihkan basis data MySQL ($DB_NAME)..."
  docker exec -i "$DB_CONTAINER" mysql -u root -p"${DB_ROOT_PASSWORD}" "${DB_NAME}" < "$TEMP_DIR/database.sql"
  ok "Pemulihan basis data berhasil."
else
  log "Peringatan: Berkas database.sql tidak ditemukan dalam arsip backup."
fi

if [ -d "$TEMP_DIR/server_data" ]; then
  log "3. Memulihkan berkas data server..."
  if docker ps --format '{{.Names}}' | grep -q "^judgels-server$"; then
    docker cp "$TEMP_DIR/server_data/." judgels-server:/judgels/server/var/data/
    docker exec -u 0 judgels-server chown -R judgels:nogroup /judgels/server/var/data
    ok "Berkas data server berhasil disalin ke kontainer."
  fi
fi

log "4. Memulai ulang kontainer server dan grader..."
docker restart judgels-server judgels-grader 2>/dev/null || docker restart judgels-server || true

ok "Proses pemulihan (restore) selesai secara sempurna!"

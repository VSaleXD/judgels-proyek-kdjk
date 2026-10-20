#!/usr/bin/env bash
#
# setup.sh - Menyiapkan Judgels (core stack) berbasis Docker
#
# Dijalankan DI SERVER sebagai root. Skrip ini TIDAK menyentuh nginx/apache,
# firewall, GRUB, atau database yang sudah ada di host. Ia hanya:
#   1. membuat folder /opt/judgels
#   2. membuat password acak (.env)
#   3. membuat config server, config client, dan contoh vhost nginx
#   4. (opsional) menjalankan `docker compose up -d`
#
# Pemakaian:
#   sudo ./setup.sh <domain> [versi]
#   contoh: sudo ./setup.sh judge.cp-codetoday.web.id 3.0.0
#
# Domain yang dipakai:
#   <domain>          antarmuka peserta
#   api.<domain>      API server
#   admin.<domain>    antarmuka admin
#
# Variabel opsional: BASE_DIR (default /opt/judgels), START=yes untuk langsung
# menjalankan compose, SKIP_DOCKER_CHECK=1 untuk melewati cek docker (uji coba).

set -Eeuo pipefail

DOMAIN="${1:-}"
VERSION="${2:-3.0.0}"
BASE_DIR="${BASE_DIR:-/opt/judgels}"
START="${START:-no}"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die()  { printf '[FAIL] %s\n' "$*" >&2; exit 1; }
log()  { printf '[INFO] %s\n' "$*"; }
ok()   { printf '[ OK ] %s\n' "$*"; }

[ -n "$DOMAIN" ] || die "Pemakaian: sudo ./setup.sh <domain> [versi]"
[[ "$DOMAIN" =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]] || die "Domain tidak valid: $DOMAIN"
[[ "$VERSION" =~ ^[0-9A-Za-z._-]+$ ]] || die "Versi tidak valid: $VERSION"
[ "$(id -u)" -eq 0 ] || [ -n "${SKIP_DOCKER_CHECK:-}" ] || die "Jalankan sebagai root (sudo)."

API_DOMAIN="api.$DOMAIN"
ADMIN_DOMAIN="admin.$DOMAIN"

# --- cek docker --------------------------------------------------------------
if [ -z "${SKIP_DOCKER_CHECK:-}" ]; then
  command -v docker >/dev/null 2>&1 || die "Docker belum terpasang. Lihat README langkah 1."
  docker compose version >/dev/null 2>&1 || die "Plugin 'docker compose' belum ada. Lihat README langkah 1."
  command -v openssl >/dev/null 2>&1 || die "openssl belum terpasang."
fi

# --- cek bentrok port --------------------------------------------------------
if command -v ss >/dev/null 2>&1; then
  for p in 5000 9101; do
    if ss -ltn "( sport = :$p )" 2>/dev/null | grep -q LISTEN; then
      die "Port $p sudah dipakai proses lain. Cek dengan: ss -ltnp | grep :$p"
    fi
  done
fi

# --- folder ------------------------------------------------------------------
log "Menyiapkan folder di $BASE_DIR ..."
mkdir -p "$BASE_DIR"/{mysql/data,server/var/conf,client/var/conf}
# Playbook resmi memakai mode 0777 untuk var server karena container berjalan
# sebagai user non-root (judgels).
chmod 777 "$BASE_DIR/server/var" "$BASE_DIR/server/var/conf"
chmod 755 "$BASE_DIR/client/var" "$BASE_DIR/client/var/conf"

cp "$SRC_DIR/docker-compose.yml" "$BASE_DIR/docker-compose.yml"

# --- .env (password acak; tidak ditimpa kalau sudah ada) ----------------------
ENV_FILE="$BASE_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  ok ".env sudah ada; password tidak diganti."
  ARG_DOMAIN="$DOMAIN"; ARG_VERSION="$VERSION"
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  DOMAIN="$ARG_DOMAIN"; VERSION="$ARG_VERSION"
  sed -i -e "s|^DOMAIN=.*|DOMAIN=$DOMAIN|" -e "s|^JUDGELS_VERSION=.*|JUDGELS_VERSION=$VERSION|" "$ENV_FILE"
else
  DB_ROOT_PASSWORD="$(openssl rand -hex 16)"
  DB_PASSWORD="$(openssl rand -hex 16)"
  RABBITMQ_PASSWORD="$(openssl rand -hex 16)"
  SUPERADMIN_PASSWORD="$(openssl rand -hex 12)"
  umask 077
  cat > "$ENV_FILE" <<EOF
JUDGELS_VERSION=$VERSION
DOMAIN=$DOMAIN
DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD
DB_PASSWORD=$DB_PASSWORD
RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD
SUPERADMIN_PASSWORD=$SUPERADMIN_PASSWORD
# Opsional, batasi heap Java server, mis. JAVA_OPTS_SERVER=-Xmx1g
JAVA_OPTS_SERVER=
EOF
  umask 022
  ok ".env dibuat dengan password acak (mode 600)."
fi

# --- config server (dari template resmi, bagian yang dipakai) -----------------
cat > "$BASE_DIR/server/var/conf/judgels-server.yml" <<EOF
server:
  applicationConnectors:
    - type: http
      port: 9101

  adminConnectors:
    - type: http
      port: 9111

  requestLog:
    appenders:
    - type: file
      currentLogFilename: var/log/judgels-server-request.log
      archivedLogFilenamePattern: var/log/judgels-server-request-%d.log.gz
      archivedFileCount: 14

database:
  driverClass: com.mysql.cj.jdbc.Driver
  url: jdbc:mysql://mysql:3306/judgels?useSSL=false
  user: judgels
  password: $DB_PASSWORD
  properties:
    charSet: UTF-8
    hibernate.dialect: org.hibernate.dialect.MySQLDialect
    hibernate.generate_statistics: false
    hibernate.query.plan_cache_max_size: 64
    hibernate.query.plan_parameter_metadata_max_size: 32

logging:
  appenders:
    - type: console
      threshold: INFO
    - type: file
      currentLogFilename: var/log/judgels-server.log
      archivedLogFilenamePattern: var/log/judgels-server-%d.log.gz
      archivedFileCount: 14

  loggers:
    org.hibernate.type.BasicTypeRegistry:
      level: OFF

webSecurity:
  cors:
    allowedOrigins: https://$DOMAIN
    allowCredentials: true

judgels:
  baseDataDir: var/data

  app:
    mode: JUDGELS

  rabbitmq:
    host: rabbitmq
    username: judgels
    password: $RABBITMQ_PASSWORD

  grading:
    gradingRequestQueueName: judgels-grading-request
    gradingResponseQueueName: judgels-grading-response

  auth:

  userRegistration:
    enabled: false
    useRecaptcha: false
    activationEmailTemplate:
      subject: UNUSED
      body: UNUSED

  userResetPassword:
    enabled: false
    requestEmailTemplate:
      subject: UNUSED
      body: UNUSED
    resetEmailTemplate:
      subject: UNUSED
      body: UNUSED

  superadmin:
    initialPassword: $SUPERADMIN_PASSWORD
EOF
chmod 644 "$BASE_DIR/server/var/conf/judgels-server.yml"   # dibaca user non-root di container

# --- config client -------------------------------------------------------------
# PENTING: pada image client v3.0.0, apiUrl HARUS berakhiran /v2 (client memanggil
# ${apiUrl}/user-web/config). Pada rilis yang lebih baru (master) /v2 ditambahkan
# oleh client sendiri, jadi apiUrl-nya tanpa /v2. Sesuaikan jika versi diganti.
cat > "$BASE_DIR/client/var/conf/judgels-client.js" <<EOF
window.conf = {
  mode: 'JUDGELS',
  apiUrl: 'https://$API_DOMAIN/v2',
};
EOF
chmod 644 "$BASE_DIR/client/var/conf/judgels-client.js"

# --- contoh vhost nginx (reverse proxy; belum dipasang otomatis) ---------------
cat > "$BASE_DIR/nginx-judgels.conf" <<EOF
# Vhost untuk Judgels. HTTP dulu; HTTPS ditambahkan oleh certbot.
# Salin ke /etc/nginx/sites-available/judgels lalu aktifkan (lihat README).

# --- peserta ---
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Connection "";
        proxy_http_version 1.1;
        proxy_buffering off;
        client_max_body_size 512M;
    }
}

# --- API ---
server {
    listen 80;
    listen [::]:80;
    server_name $API_DOMAIN;
    access_log off;

    location ~ ^(/api)?/v[0-9]+/ {
        rewrite ^(?:/api)?(.*) /api\$1 break;
        include proxy_params;
        proxy_pass http://127.0.0.1:9101;
        proxy_set_header Connection "";
        proxy_http_version 1.1;
        proxy_buffering off;
        client_max_body_size 512M;
    }
}

# --- admin ---
server {
    listen 80;
    listen [::]:80;
    server_name $ADMIN_DOMAIN;
    access_log off;

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:9101;
        proxy_set_header Connection "";
        proxy_http_version 1.1;
        proxy_buffering off;
        client_max_body_size 512M;
    }
}
EOF

ok "File siap di $BASE_DIR"

# --- jalankan ------------------------------------------------------------------
if [ "$START" = "yes" ]; then
  log "Menjalankan docker compose up -d ..."
  (cd "$BASE_DIR" && docker compose up -d)
  ok "Container dijalankan. Cek dengan: cd $BASE_DIR && docker compose ps"
else
  log "Belum dijalankan. Jalankan:  cd $BASE_DIR && docker compose up -d"
fi

cat <<EOF

------------------------------------------------------------
 Domain peserta : https://$DOMAIN
 Domain API     : https://$API_DOMAIN
 Domain admin   : https://$ADMIN_DOMAIN
 Login admin    : superadmin
 Password       : $SUPERADMIN_PASSWORD   (juga ada di $ENV_FILE)
------------------------------------------------------------
EOF

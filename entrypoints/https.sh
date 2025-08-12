#!/bin/bash
set -e

source /entrypoints/base.sh

if [[ -z "$DOMAINS" ]]; then
    DOMAINS="localhost *.localhost"
fi

MAIN_DOMAIN=$(awk '{print $1}' <<< "$DOMAINS")

CURRENT_HASH=$(sha1sum <<< "$DOMAINS" | awk '{print $1}')

CERT_DIR="/etc/letsencrypt/live/${MAIN_DOMAIN}"

CERT_PRIVKEY="$CERT_DIR/privkey.pem"
CERT_FULLCHAIN="$CERT_DIR/fullchain.pem"

CERT_EMAIL="${CERT_EMAIL:-admin@$MAIN_DOMAIN}"

DOMAINS_HASH_FILE="$CERT_DIR/.domains.hash"

mkdir -p "$CERT_DIR"

main() {

  generate_new_cert_if_missing_or_domains_changed
  generate_nginx_conf
  renew_cert_loop &
  start_nginx
}

renew_cert_loop() {
  while true; do
    local now_ts=$(date +%s)
    local expiry_ts=$(get_cert_expiry_ts)
    local seconds_left=$(( expiry_ts - now_ts ))
    local days_left=$(( seconds_left / 86400 ))

    echo "[openssl] Certificado expira em $days_left dias."

    if (( days_left <= 7 )); then
      echo "[openssl] Renovando certificado..."
      renew_cert
      sleep 43200 # 12h
    elif (( days_left <= 30 )); then
      sleep 86400 # 24h
    else
      local sleep_sec=$(( seconds_left - 30*86400 ))
      if (( sleep_sec < 60 )); then
        sleep_sec=60 # 60s
      fi
      echo "[openssl] Dormindo até 30 dias antes da expiração ($(($sleep_sec / 3600)) horas)..."
      sleep $sleep_sec
    fi
  done
}

generate_new_cert_if_missing_or_domains_changed() {

  local SAVED_HASH=""
  [[ -f "$DOMAINS_HASH_FILE" ]] && SAVED_HASH=$(<"$DOMAINS_HASH_FILE")

  if [[ "$CURRENT_HASH" != "$SAVED_HASH" ]]; then

    echo "$CURRENT_HASH" > "$DOMAINS_HASH_FILE"

    echo "[cert] Recreating cert..."

    generate_cert
  fi

  if [[ ! -f "$CERT_FULLCHAIN" ]] || [[ ! -f "$CERT_PRIVKEY" ]]; then
    echo "[openssl] Generating new cert"
    generate_cert
  fi
}


get_cert_expiry_ts() {
  date -d "$(openssl x509 -enddate -noout -in "$CERT_FULLCHAIN" | cut -d= -f2)" +%s
}

get_cert_expiry_date() {
  date -d "@$(get_cert_expiry_ts)" +%F
}


generate_https_servers() {

  local prefix="$1" 


  local ssl_protocols=${NGINX_SSL_PROTOCOLS:-TLSv1.2 TLSv1.3}
  local ssl_ciphers=${NGINX_SSL_CIPHERS:-HIGH:!aNULL:!MD5}
  local ssl_prefer_server_ciphers=${NGINX_SSL_PREFER_SERVER_CIPHERS:-on}

  local https_certificate=$(cat <<EOF

ssl_certificate ${CERT_DIR}/fullchain.pem;
ssl_certificate_key ${CERT_DIR}/privkey.pem;

ssl_protocols $ssl_protocols;
ssl_prefer_server_ciphers $ssl_prefer_server_ciphers;
ssl_ciphers $ssl_ciphers;

location /ssl {
    alias ${CERT_DIR}/fullchain.pem;
    add_header Content-Disposition "attachment; filename=${MAIN_DOMAIN}.crt";
    default_type application/x-x509-ca-cert;
}
EOF
)

  for var in $(compgen -v | grep "^${prefix}"); do
    local DEFAULT_SERVER=""
    local hsts_header=""

    if [ "$var" = "${prefix}DEFAULT" ]; then
      DEFAULT_SERVER="default_server"
    fi

    if [ "${NGINX_FORCE_HTTPS,,}" = "true" ]; then
      hsts_header='add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;'
    fi

    cat <<EOF >> /tmp/nginx.conf.tmp
server {
  listen 443 ssl $DEFAULT_SERVER;
  ${!var}
  $hsts_header
  $https_certificate
}
EOF


  done
}

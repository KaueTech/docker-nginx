#!/bin/bash
set -e

start_nginx() {
  echo "[nginx] Starting nginx reverse proxy..."

  nginx -t

  exec nginx -g "daemon off;"
}


generate_stream_servers() {
  for var in $(compgen -v | grep '^NGINX_STREAM_SERVER_'); do
    cat <<EOF
server {
  ${!var}
}
EOF
  done
}

generate_force_https_server() {

  if [ "${NGINX_FORCE_HTTPS,,}" = "true" ]; then
    cat <<EOF >> /tmp/nginx.conf.tmp
server {
  listen 80 default_server;
  server_name _;

  return 301 https://\$host\$request_uri;
}
EOF
  fi
}

generate_http_servers() {

  local prefix="$1" 

  if [ "${NGINX_FORCE_HTTPS,,}" != "true" ]; then
    for var in $(compgen -v | grep "^${prefix}"); do
      local default_server=""

      if [ "$var" == "${prefix}DEFAULT" ]; then
        default_server="default_server"
      fi

      cat <<EOF >> /tmp/nginx.conf.tmp
server {
  listen 80 $default_server;
  ${!var}
}
EOF
    done
  fi
}

generate_upstreams() {
  local prefix="$1" 

  for var in $(compgen -v | grep "^${prefix}"); do
    # Remove o prefixo exato da variável
    upstream_name=${var#"$prefix"}
    upstream_name=$(echo "$upstream_name" | tr '[:upper:]' '[:lower:]')

    cat <<EOF >> /tmp/nginx.conf.tmp

  upstream $upstream_name {
    ${!var}
  }
EOF
  done
}


generate_maps() {
  local prefix="$1"

  for var in $(compgen -v | grep "^${prefix}"); do
    rest=$(echo "${var#$prefix}" | tr '[:upper:]' '[:lower:]')

    if [[ "$rest" =~ ^(.+)_as_(.+)$ ]]; then
      map_key_name="${BASH_REMATCH[1]}"
      map_target_name="${BASH_REMATCH[2]}"
    else
      map_key_name="$rest"
      map_target_name="${rest}_map"
    fi

    map_key="\$$map_key_name"
    map_target="\$$map_target_name"

    cat <<EOF >> /tmp/nginx.conf.tmp

  map ${map_key} ${map_target} {
    ${!var}
  }
EOF
  done
}

generate_nginx_conf() {

  if [ -z "${NGINX_SERVER_DEFAULT}" ]; then

    found_map_target=false

    while IFS='=' read -r name value; do
      if [[ "$name" =~ ^NGINX_MAP_.*_AS_TARGET$ ]]; then
        found_map_target=true
        break
      fi
    done < <(env | grep '^NGINX_MAP_')

    # Se não achou nenhuma, define o fallback
    if ! $found_map_target; then
      NGINX_MAP_HOST_AS_TARGET="default http://localhost:8080"
    fi

    NGINX_SERVER_DEFAULT=$(cat <<'EOF'
server_name _;

location / {
    proxy_pass $target;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
EOF
)
  fi

  cat <<EOF >> /tmp/nginx.conf.tmp
user nginx;
worker_processes ${NGINX_WORKER_PROCESSES:-auto};

error_log /var/log/nginx/error.log ${NGINX_LOG_LEVEL:-warn};
pid /var/run/nginx.pid;

events {
  worker_connections ${NGINX_WORKER_CONNECTIONS:-1024};
}

EOF

  local resolver="${NGINX_RESOLVER:-"127.0.0.11 valid=10s"}"

  cat <<EOF >> /tmp/nginx.conf.tmp

stream {
  resolver $resolver;

  ${NGINX_STREAM}
EOF
  
  generate_upstreams "NGINX_STREAM_UPSTREAM_"
  generate_maps "NGINX_STREAM_MAP_"
  generate_stream_servers

  cat <<EOF >> /tmp/nginx.conf.tmp
}

http {
  include /etc/nginx/mime.types;
  default_type ${NGINX_HTTP_DEFAULT_TYPE:-'application/octet-stream'};

  resolver $resolver;

  sendfile ${NGINX_SENDFILE:-on};
  keepalive_timeout ${NGINX_KEEPALIVE_TIMEOUT:-65};

  ${NGINX_HTTP}
EOF

  generate_upstreams "NGINX_HTTPS_UPSTREAM_"
  generate_upstreams "NGINX_HTTP_UPSTREAM_"
  generate_upstreams "NGINX_UPSTREAM_"

  generate_maps "NGINX_HTTPS_MAP_"
  generate_maps "NGINX_HTTP_MAP_"
  generate_maps "NGINX_MAP_"

  generate_force_https_server

  generate_http_servers "NGINX_HTTP_SERVER_"
  generate_http_servers "NGINX_SERVER_"

  generate_https_servers "NGINX_HTTPS_SERVER_"
  generate_https_servers "NGINX_SERVER_"

  echo "}" >> /tmp/nginx.conf.tmp

  mv /tmp/nginx.conf.tmp /etc/nginx/nginx.conf

}
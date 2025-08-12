#!/bin/bash

source /entrypoints/https.sh

generate_cert() {
  local san_list=""
  for d in $DOMAINS; do
    san_list+="DNS:${d},"
  done
  san_list="${san_list%,}" # remove última vírgula

  mkdir -p "$CERT_DIR"

  if [[ ! -f "$CERT_PRIVKEY" ]]; then
    openssl genpkey -algorithm RSA -out "$CERT_PRIVKEY" -pkeyopt rsa_keygen_bits:2048
  fi

  local sslconf="$CERT_DIR/openssl.cnf"

  cat > "$sslconf" <<EOF
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[ req_distinguished_name ]
CN = $MAIN_DOMAIN

[ v3_req ]
subjectAltName = $san_list
EOF

  openssl req -x509 -new -key "$CERT_PRIVKEY" \
    -out "$CERT_FULLCHAIN" \
    -days 90 -sha256 \
    -config $sslconf

  # rm -f "$sslconf"

}

renew_cert() {
  generate_cert
  nginx -s reload

}

main "$@"


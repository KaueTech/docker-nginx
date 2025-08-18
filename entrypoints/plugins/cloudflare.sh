#!/bin/bash
source /entrypoints/https.sh

CLOUDFLARE_FILE=$CERT_DIR/cloudflare.ini
echo "dns_cloudflare_api_token = $CLOUDFLARE_TOKEN" > $CLOUDFLARE_FILE

generate_cert() { 
  chmod 600 $CLOUDFLARE_FILE

  local san_list=""
  for d in $NGINX_DOMAINS; do
    san_list+=" -d $d"
  done
  
  certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials $CLOUDFLARE_FILE \
    $san_list \
    --email "$CERT_EMAIL" \
    --agree-tos \
    --non-interactive \
    --config-dir /etc/letsencrypt \
    --work-dir /var/lib/letsencrypt \
    --logs-dir /var/log/letsencrypt
}

renew_cert() {
    certbot renew --dns-cloudflare --dns-cloudflare-credentials $CLOUDFLARE_FILE --quiet --deploy-hook "nginx -s reload"
}

main "$@"

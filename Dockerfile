ARG PLUGIN=http

FROM --platform=$BUILDPLATFORM nginx:latest AS base
COPY ./entrypoints/base.sh /entrypoints/base.sh
EXPOSE 80

FROM base AS https
COPY ./entrypoints/https.sh /entrypoints/https.sh
EXPOSE 443
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

FROM https AS certbot
RUN apt-get update && apt-get install -y certbot curl python3-pip && rm -rf /var/lib/apt/lists/*

##########
# PLUGINS
##########

FROM base AS plugin-http
COPY ./entrypoints/plugins/http.sh /entrypoints/entrypoint.sh

FROM https AS plugin-openssl
COPY ./entrypoints/plugins/openssl.sh /entrypoints/entrypoint.sh

FROM certbot AS plugin-cloudflare
RUN apt-get update && apt-get install -y python3-certbot-dns-cloudflare && rm -rf /var/lib/apt/lists/*
COPY ./entrypoints/plugins/cloudflare.sh /entrypoints/entrypoint.sh

########
# FINAL
########

FROM plugin-$PLUGIN AS final

RUN chmod +x /entrypoints/*.sh || true
ENTRYPOINT ["/entrypoints/entrypoint.sh"]

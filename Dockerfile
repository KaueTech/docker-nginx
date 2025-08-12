FROM --platform=$BUILDPLATFORM nginx:latest as base

EXPOSE 80 443

FROM base AS https
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

FROM https AS certbot
RUN apt-get update && apt-get install -y certbot curl && rm -rf /var/lib/apt/lists/*

###############
# Final Images
###############

FROM base AS http

COPY ./entrypoints /entrypoints
RUN find /entrypoints -type f -name '*.sh' -exec chmod +x {} +

ENTRYPOINT ["/entrypoints/http.sh"]

FROM https AS self-signed

COPY ./entrypoints /entrypoints
RUN find /entrypoints -type f -name '*.sh' -exec chmod +x {} +

ENTRYPOINT ["/entrypoints/plugins/self-signed.sh"]

FROM certbot AS cloudflare
RUN apt-get update && apt-get install -y python3-certbot-dns-cloudflare && rm -rf /var/lib/apt/lists/*

COPY ./entrypoints /entrypoints
RUN find /entrypoints -type f -name '*.sh' -exec chmod +x {} +

ENTRYPOINT ["/entrypoints/plugins/cloudflare.sh"]

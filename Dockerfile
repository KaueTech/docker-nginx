# Multi-stage Dockerfile for nginx with different configurations
# Supports HTTP, HTTPS with openssl, and various DNS providers
FROM --platform=$BUILDPLATFORM nginx:latest AS base

EXPOSE 80

# HTTPS base image with OpenSSL
FROM base AS https

EXPOSE 443

RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

# Certbot base image for SSL certificate management
FROM https AS certbot
RUN apt-get update && apt-get install -y certbot curl python3-pip && rm -rf /var/lib/apt/lists/*

###############
# Final Images
###############

FROM base AS http

COPY ./entrypoints/base /entrypoints
RUN find /entrypoints -type f -name '*.sh' -exec chmod +x {} +

ENTRYPOINT ["/entrypoints/http.sh"]

# HTTPS with openssl certificates
FROM https AS openssl

COPY ./entrypoints /entrypoints
RUN find /entrypoints -type f -name '*.sh' -exec chmod +x {} +

ENTRYPOINT ["/entrypoints/plugins/openssl.sh"]

# HTTPS with Cloudflare DNS for automatic SSL certificates
FROM certbot AS cloudflare
RUN apt-get update && apt-get install -y python3-certbot-dns-cloudflare && rm -rf /var/lib/apt/lists/*

COPY ./entrypoints /entrypoints
RUN find /entrypoints -type f -name '*.sh' -exec chmod +x {} +

ENTRYPOINT ["/entrypoints/plugins/cloudflare.sh"]

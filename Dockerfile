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

##################################
# BASIC NGINX IMAGE
##################################

FROM base AS http

COPY ./entrypoint/base.sh /entrypoints/base.sh
COPY ./entrypoints/http.sh /entrypoints/http.sh

RUN chmod +x /entrypoints/*.sh
ENTRYPOINT ["/entrypoints/http.sh"]

##################################
# HTTPS with openssl certificates
##################################

FROM https AS openssl

COPY ./entrypoints/base.sh /entrypoints/base.sh
COPY ./entrypoints/https.sh /entrypoints/https.sh
COPY ./entrypoints/plugins/openssl.sh /entrypoints/plugins/openssl.sh

RUN chmod +x /entrypoints/**/*.sh || true
ENTRYPOINT ["/entrypoints/plugins/openssl.sh"]

############################
# HTTPS with Cloudflare API
############################

FROM certbot AS cloudflare
RUN apt-get update && apt-get install -y python3-certbot-dns-cloudflare && rm -rf /var/lib/apt/lists/*

COPY ./entrypoints/base.sh /entrypoints/base.sh
COPY ./entrypoints/https.sh /entrypoints/https.sh
COPY ./entrypoints/plugins/cloudflare.sh /entrypoints/plugins/cloudflare.sh

RUN chmod +x /entrypoints/**/*.sh || true
ENTRYPOINT ["/entrypoints/plugins/cloudflare.sh"]

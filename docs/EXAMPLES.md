# Examples Guide

This guide provides practical examples for using the Docker Nginx image in different scenarios.

## Table of Contents

- [Basic HTTP Setup](#basic-http-setup)
- [HTTPS with openssl Certificates](#https-with-openssl-certificates)
- [Production Setup with Cloudflare DNS](#production-setup-with-cloudflare-dns)
- [Microservices Architecture](#microservices-architecture)

## Basic HTTP Setup

Simple HTTP reverse proxy configuration for development or internal use.

```yaml
version: '3.8'

services:
  nginx-http:
    image: kauech/nginx:http
    ports:
      - "80:80"
    environment:
      NGINX_MAP_HOST_AS_TARGET: |
        default http://app:3000;
    depends_on:
      - app

  app:
    image: nginx:alpine
    expose:
      - "3000"
```

**Usage:**
```bash
docker-compose up -d nginx-http
```

## HTTPS with openssl Certificates

HTTPS configuration with automatically generated openssl certificates.

```yaml
version: '3.8'

services:
  nginx-openssl:
    image: kauech/nginx:openssl
    ports:
      - "80:80"
      - "443:443"
    environment:
      NGINX_MAP_HOST_AS_TARGET: |
        default http://app:3000;
      NGINX_FORCE_HTTPS: "true"
    volumes:
      - ./data/letsencrypt:/etc/letsencrypt
    depends_on:
      - app

  app:
    image: nginx:alpine
    expose:
      - "3000"
```

**Usage:**
```bash
docker-compose up -d nginx-openssl
```

**Features:**
- Automatic openssl certificate generation
- HTTP to HTTPS redirect
- Certificate persistence in `./data/letsencrypt`

## Production Setup with Cloudflare DNS

Production-ready setup with Cloudflare DNS challenge for Let's Encrypt certificates.

```yaml
version: '3.8'

services:
  nginx-cloudflare:
    image: kauech/nginx:cloudflare
    ports:
      - "80:80"
      - "443:443"
    environment:
      CLOUDFLARE_API_TOKEN: ${CLOUDFLARE_API_TOKEN}
      CERT_EMAIL: ${CERT_EMAIL}
      DOMAINS: "example.com *.example.com"
      NGINX_MAP_HOST_AS_TARGET: |
        app.example.com http://app:3000;
        api.example.com http://api:8000;
        admin.example.com http://admin:4000;
      NGINX_FORCE_HTTPS: "true"
    volumes:
      - ./data/letsencrypt:/etc/letsencrypt
    depends_on:
      - app
      - api
      - admin

  app:
    image: your-app:latest
    expose:
      - "3000"

  api:
    image: your-api:latest
    expose:
      - "8000"

  admin:
    image: your-admin:latest
    expose:
      - "4000"
```


## Microservices Architecture

Advanced setup for microservices with load balancing and multiple domains.

```yaml
version: '3.8'

services:
  nginx-gateway:
    image: kauech/nginx:openssl
    ports:
      - "80:80"
      - "443:443"
    environment:
      CERT_EMAIL: ${CERT_EMAIL}
      DOMAINS: "example.com *.example.com"
      NGINX_FORCE_HTTPS: "true"
      NGINX_MAP_HOST_AS_TARGET: |
        api.example.com    http://api_gateway;
        web.example.com    http://web_app;
        mobile.example.com http://mobile_api;
        default            http://web_app;

      NGINX_UPSTREAM_API_GATEWAY: |
        server api-gateway:8080;
        server api-gateway-2:8080;

      NGINX_UPSTREAM_WEB_APP: |
        server web-app:3000;
        server web-app-2:3000;

      NGINX_UPSTREAM_MOBILE_API: |
        server mobile-api:9000;

    volumes:
      - ./data/letsencrypt:/etc/letsencrypt
    depends_on:
      - api-gateway
      - api-gateway-2
      - web-app
      - web-app-2
      - mobile-api

  api-gateway:
    image: your-api-gateway:latest
    expose:
      - "8080"

  api-gateway-2:
    image: your-api-gateway:latest
    expose:
      - "8080"

  web-app:
    image: your-web-app:latest
    expose:
      - "3000"

  web-app-2:
    image: your-web-app:latest
    expose:
      - "3000"

  mobile-api:
    image: your-mobile-api:latest
    expose:
      - "9000"
```

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token for DNS challenge | `your_token_here` |
| `CERT_EMAIL` | Email for certificate notifications | `admin@example.com` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DOMAINS` | Domains for SSL certificates | `localhost *.localhost` |
| `NGINX_FORCE_HTTPS` | Redirect HTTP to HTTPS | `false` |

## Customization

### Adding Custom Domains

```yaml
environment:
  DOMAINS: "myapp.com *.myapp.com api.myapp.com"
```

### Custom Upstream Configuration

```yaml
environment:
  NGINX_UPSTREAM_MYAPP: |
    server myapp-1:3000 weight=3;
    server myapp-2:3000 weight=2;
    server myapp-3:3000 weight=1;
```

### Custom Server Blocks

```yaml
environment:
  NGINX_SERVER_MYAPP: |
    server_name myapp.com;
    location / {
      proxy_pass http://myapp;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }
```

## Troubleshooting

### Getting Help

- Check the [Installation Guide](INSTALLATION.md) for setup instructions
- Create an issue on GitHub for bugs or feature requests

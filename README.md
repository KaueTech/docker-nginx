# Docker Nginx

A production-ready Docker Nginx image with multiple configurations for reverse proxy, SSL termination, and automatic certificate management.

## 🚀 Features

- **Multiple Configurations**: HTTP, HTTPS with openssl certificates, and Cloudflare DNS
- **Automatic SSL**: Let's Encrypt certificates with Cloudflare DNS challenge
- **Reverse Proxy**: Easy upstream configuration with environment variables
- **Multi-Architecture**: Supports AMD64, ARM64, and ARMv7
- **Production Ready**: Optimized for production deployments
- **Easy Configuration**: Simple environment variable-based configuration

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Docker Compose Examples](#docker-compose-examples)
- [Environment Variables](#environment-variables)
- [Architecture Support](#architecture-support)
- [Contributing](#contributing)
- [License](#license)

## 🏃 Quick Start

### Using Docker Hub

```bash
# HTTP only
docker run -d -p 80:80 kauech/nginx:http

# HTTPS with openssl certificates
docker run -d -p 80:80 -p 443:443 kauech/nginx:openssl

# HTTPS with Cloudflare DNS
docker run -d -p 80:80 -p 443:443 \
  -e CLOUDFLARE_API_TOKEN=your_token \
  -e CERT_EMAIL=your_email \
  kauech/nginx:cloudflare
```

### Using Docker Compose

```bash
# Clone the repository
git clone https://github.com/kauech/docker-nginx.git
cd docker-nginx

# Start with openssl certificates
docker-compose up -d
```

## 📦 Installation

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+ (optional)
- Git

### Method 1: Docker Hub (Recommended)

```bash
# Pull the latest image
docker pull kauech/nginx:latest

# Or pull specific variants
docker pull kauech/nginx:http
docker pull kauech/nginx:openssl
docker pull kauech/nginx:cloudflare
```

### Method 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/kauech/docker-nginx.git
cd docker-nginx

# Quick build for current architecture
make quick-build

# Build all variants for all architectures
make build-all

# Build specific variant
make build-openssl
```

### Method 3: Multi-Architecture Build

```bash
# Build for multiple architectures
make build-all

# Or build for specific platforms (set environment variable)
export PLATFORMS="linux/amd64,linux/arm64"
make build-all
```

### Method 4: Push to Docker Hub

```bash
# Login to Docker Hub
docker login

# Build and push all variants
make build-all

# Complete release (build + push)
make release
```

For detailed build instructions, see the [Build Guide](docs/BUILD.md).

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NGINX_MAP_HOST_AS_TARGET` | Host to upstream mapping | `default http://localhost:8080;` |
| `NGINX_FORCE_HTTPS` | Redirect HTTP to HTTPS | `false` |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token | - |
| `CERT_EMAIL` | Cert email | - |
| `DOMAINS` | Domain for SSL certificate | - |

### Basic Configuration

```bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -e NGINX_MAP_HOST_AS_TARGET="default http://localhost:8080;" \
  -e NGINX_FORCE_HTTPS=true \
  kauech/nginx:openssl
```

### Advanced Configuration

```bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -e NGINX_MAP_HOST_AS_TARGET="app.example.com http://app:3000;" \
  -e NGINX_UPSTREAM_APP="server app:3000;" \
  -e NGINX_SERVER_APP="server_name app.example.com; location / { proxy_pass http://app; }" \
  kauech/nginx:openssl
```

## 🐳 Docker Compose Examples

For comprehensive Docker Compose examples, see the [Examples Guide](docs/EXAMPLES.md).

### Quick Start

```bash
# Clone the repository
git clone https://github.com/kauech/docker-nginx.git
cd docker-nginx

# Start with openssl certificates
docker-compose up -d
```

### Basic Example

```yaml
version: '3.8'

services:
  nginx:
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

## 🏗️ Architecture Support

This image supports multiple architectures:

- **linux/amd64** - Intel/AMD 64-bit
- **linux/arm64** - ARM 64-bit (Apple Silicon, Raspberry Pi 4)
- **linux/arm/v7** - ARM 32-bit (Raspberry Pi 3)

### Building for Specific Architecture

```bash
# Build for ARM64
export PLATFORMS="linux/arm64"
make build-all

# Build for all supported architectures
export PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"
make build-all
```

## 🔧 Development

### Building Locally

```bash
# Clone the repository
git clone https://github.com/kauech/docker-nginx.git
cd docker-nginx

# Quick build for current architecture
make quick-build

# Build all variants for all architectures
make build-all

# Build specific variant
make build-openssl
```

### Multi-Architecture Build

```bash
# Build for multiple architectures
make build-all

# Or build for specific platforms
export PLATFORMS="linux/amd64,linux/arm64"
make build-all
```

### Pushing to Docker Hub

```bash
# Login to Docker Hub
docker login

# Build and push all variants
make build-all

# Complete release (build + push)
make release
```

For detailed build instructions, see the [Build Guide](docs/BUILD.md).

### Testing

```bash
# Test HTTP variant
docker run --rm -d --name test-http kauech/nginx:http
sleep 5
curl -f http://localhost:80 || exit 1
docker stop test-http

# Test openssl variant
docker run --rm -d --name test-openssl kauech/nginx:openssl
sleep 5
curl -f -k https://localhost:443 || exit 1
docker stop test-openssl
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support

- 📖 [Documentation](https://github.com/kauech/docker-nginx/wiki)
- 🐛 [Issues](https://github.com/kauech/docker-nginx/issues)
- 💬 [Discussions](https://github.com/kauech/docker-nginx/discussions)

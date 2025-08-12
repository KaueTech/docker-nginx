# Build and Push Guide

This guide explains how to build and push Docker images for different architectures using the Makefile system.

## 🛠️ Prerequisites

- Docker 20.10+
- Docker Buildx (usually included with Docker Desktop)
- Docker Hub account
- Git

## 📦 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/kauech/docker-nginx.git
cd docker-nginx
```

### 2. Login to Docker Hub

```bash
docker login
```

### 3. Build and Push

```bash
# Quick build and push for current architecture
make release

# Or build and push all variants
make build-all
```

## 🚀 Build Methods

### Method 1: Using Makefile (Recommended)

#### Build Commands

```bash
# Build all variants for all architectures
make build-all

# Build specific variant
make build-openssl

# Build with custom version
export VERSION="1.0.0"
make build-all

# Build for specific platform only
export PLATFORMS="linux/amd64"
make build-all

# Quick build for current architecture
make quick-build
```

#### Push Commands

```bash
# Build and push all variants
make build-all

# Push specific variant
make push-openssl

# Build and push with custom version
export VERSION="1.0.0"
make build-all
```

#### Release Commands

```bash
# Complete release for all architectures
make release

# Release with custom version
export VERSION="1.0.0"
make release

# Build locally (no push)
make dev-build
```

### Method 2: Manual Docker Commands

```bash
# Setup Docker Buildx
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap

# Build and push for multiple architectures
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --target openssl \
  -t kauech/nginx:openssl \
  -t kauech/nginx:latest \
  --push .
```

## 🏗️ Architecture Support

The build system supports multiple architectures:

- **linux/amd64** - Intel/AMD 64-bit
- **linux/arm64** - ARM 64-bit (Apple Silicon, Raspberry Pi 4)
- **linux/arm/v7** - ARM 32-bit (Raspberry Pi 3)

### Customizing Platforms

```bash
# Build for AMD64 only
export PLATFORMS="linux/amd64"
make build-all

# Build for ARM64 and ARMv7 only
export PLATFORMS="linux/arm64,linux/arm/v7"
make build-all

# Set custom platforms via environment variable
export PLATFORMS="linux/amd64,linux/arm64"
make build-all
```

## 🏷️ Versioning

### Default Versioning

Images are tagged with multiple tags:

- `kauech/nginx:http` - HTTP variant (latest)
- `kauech/nginx:openssl` - openssl HTTPS variant (latest)
- `kauech/nginx:cloudflare` - Cloudflare HTTPS variant (latest)
- `kauech/nginx:latest` - Default (openssl variant)
- `kauech/nginx:http-1.0.0` - HTTP variant with version
- `kauech/nginx:openssl-1.0.0` - openssl variant with version
- `kauech/nginx:cloudflare-1.0.0` - Cloudflare variant with version
- `kauech/nginx:1.0.0` - Default with version

### Custom Versioning

```bash
# Set version via environment variable
export VERSION="1.0.0"
make release
```

## 🔧 Configuration

### Environment Variables

You can customize the build process using environment variables:

```bash
# Registry (default: kauech)
export DOCKER_REGISTRY="myregistry"

# Image name (default: nginx)
export IMAGE_NAME="my-nginx"

# Version (default: latest)
export VERSION="1.0.0"

# Platforms (default: linux/amd64,linux/arm64,linux/arm/v7)
export PLATFORMS="linux/amd64,linux/arm64"
```

### Custom Registry

```bash
# Set environment variable
export DOCKER_REGISTRY="myregistry"
make release
```

## 📋 Build Variants

### openssl HTTPS Variant

```bash
# Build openssl variant only
make build-openssl

# Push openssl variant
make push-openssl
```

**Features:**
- HTTPS with openssl certificates
- Self-signed certificate generation
- HTTP to HTTPS redirect
- Default variant

## 🔍 Troubleshooting

### Common Issues

#### Docker Buildx Not Available

```bash
# Install Docker Buildx
docker buildx install

# Or use Docker Desktop which includes Buildx
```

#### Permission Denied

```bash
# Make scripts executable
chmod +x entrypoints/plugins/*.sh
```

#### Login Required

```bash
# Login to Docker Hub
docker login

# Or skip login if already authenticated
make build-all
```

#### Build Fails

```bash
# Check Docker is running
docker info

# Check available platforms
docker buildx ls

# Try building for single platform first
export PLATFORMS="linux/amd64"
make build-all
```

### Debug Mode

```bash
# Enable debug output
set -x
make build-all
set +x
```

## 📊 Performance Tips

### Parallel Builds

For faster builds, you can build variants in parallel:

```bash
# Build all variants in parallel
make build-http &
make build-openssl &
make build-cloudflare &
wait
```

### Caching

Docker Buildx automatically caches layers. For even better caching:

```bash
# Use BuildKit cache
export DOCKER_BUILDKIT=1
make build-all
```

### Resource Optimization

```bash
# Limit memory usage
docker buildx build --memory=2g --platform linux/amd64,linux/arm64 ...

# Use specific builder
docker buildx create --name mybuilder --driver docker-container
docker buildx use mybuilder
```

## 🎯 Examples

### Complete Release Process

```bash
# 1. Clone repository
git clone https://github.com/kauech/docker-nginx.git
cd docker-nginx

# 2. Login to Docker Hub
docker login

# 3. Release version 1.0.0
export VERSION="1.0.0"
make release
```

### Development Workflow

```bash
# 1. Quick build for testing
make quick-build

# 2. Test locally
docker run -d -p 80:80 -p 443:443 kauech/nginx:openssl

# 3. Push to registry
make quick-push
```

### Production Release

```bash
# 1. Set production version
export VERSION="2.1.0"

# 2. Build and push all variants
make release

# 3. Verify images
docker pull kauech/nginx:2.1.0
docker pull kauech/nginx:openssl-2.1.0
docker pull kauech/nginx:cloudflare-2.1.0
```

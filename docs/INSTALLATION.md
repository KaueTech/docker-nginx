# Installation Guide

This guide will help you install and configure the Docker Nginx image for your environment.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** 
- **Git** - for cloning the repository

## Installation Methods

### Method 1: Using Docker Hub (Recommended)

This is the easiest method for most users.

```bash
# Pull the latest image
docker pull kauech/nginx:latest

# Or pull specific variants
docker pull kauech/nginx:http
docker pull kauech/nginx:openssl
docker pull kauech/nginx:cloudflare
```

### Method 2: Building from Source

If you want to customize the image or build for specific architectures:

```bash
# Clone the repository
git clone https://github.com/kauech/docker-nginx.git
cd docker-nginx

# Build all variants
make build-all

# Or build specific variants
make build-http
make build-openssl
make build-cloudflare
```

## Configuration

### Environment Variables

The image can be configured using environment variables:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `NGINX_MAP_HOST_AS_TARGET` | Host to upstream mapping | `default http://localhost:8080;` | No |
| `NGINX_FORCE_HTTPS` | Redirect HTTP to HTTPS | `false` | No |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token | - | Yes (for Cloudflare variant) |
| `CERT_EMAIL` | Certbot email | - | Yes (for https) |
| `DOMAINS` | Domain for SSL certificate | `localhost *.localhost` | Yes (for Cloudflare variant) |

### Basic Configuration Example

```bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -e NGINX_MAP_HOST_AS_TARGET="default http://app:3000;" \
  -e NGINX_FORCE_HTTPS=true \
  kauech/nginx:openssl
```

## Verification

After installation, verify that everything is working:

```bash
# Check if container is running
docker ps

# Test HTTP access
curl -I http://localhost

# Test HTTPS access (for openssl variant)
curl -I -k https://localhost

# Check logs
docker logs <container_name>
```

## Troubleshooting

### Common Issues

1. **Permission denied errors**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   # Log out and log back in
   ```

2. **Port already in use**
   ```bash
   # Check what's using the port
   sudo netstat -tulpn | grep :80
   # Stop conflicting service
   sudo systemctl stop apache2  # or nginx
   ```

### Getting Help

If you encounter issues:

1. Check the [GitHub Issues](https://github.com/kauech/docker-nginx/issues)
2. Review the [Documentation](https://github.com/kauech/docker-nginx/wiki)
3. Create a new issue with detailed information

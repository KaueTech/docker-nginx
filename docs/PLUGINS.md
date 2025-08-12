# Plugin Development Guide

This guide explains how to add new plugins to the Docker Nginx system.

## 🏗️ Plugin Architecture

The system uses a modular plugin architecture where each plugin is:
1. A Docker stage in the `Dockerfile`
2. A shell script in `entrypoints/plugins/`
3. Automatically detected by the Makefile

## 📋 Available Plugins

| Plugin | Description | Environment Variables |
|--------|-------------|---------------------|
| `http` | HTTP only (no SSL) | None |
| `openssl` | Self-signed certificates | `CERT_EMAIL`, `DOMAINS` |
| `cloudflare` | Cloudflare DNS challenge | `CLOUDFLARE_API_TOKEN`, `CERT_EMAIL`, `DOMAINS` |
| `letsencrypt` | Manual DNS challenge | `CERT_EMAIL`, `DOMAINS` |
| `route53` | AWS Route53 DNS challenge | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `CERT_EMAIL`, `DOMAINS` |
| `godaddy` | GoDaddy DNS challenge | `GODADDY_API_KEY`, `GODADDY_API_SECRET`, `CERT_EMAIL`, `DOMAINS` |

## 🚀 Adding a New Plugin

### Step 1: Create the Plugin Script

Create a new file in `entrypoints/plugins/your-plugin.sh`:

```bash
#!/bin/bash

# Your Plugin DNS Challenge Plugin
# Description of what your plugin does

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check required environment variables
if [ -z "$CERT_EMAIL" ]; then
    print_error "CERT_EMAIL environment variable is required"
    exit 1
fi

if [ -z "$DOMAINS" ]; then
    print_error "DOMAINS environment variable is required"
    exit 1
fi

# Add your plugin-specific environment variables
if [ -z "$YOUR_API_KEY" ]; then
    print_error "YOUR_API_KEY environment variable is required"
    exit 1
fi

print_info "Setting up Let's Encrypt certificates with Your Plugin DNS challenge..."

# Install your plugin dependencies
if ! certbot plugins | grep -q "your-plugin"; then
    print_info "Installing certbot your-plugin plugin..."
    pip install certbot-dns-your-plugin
fi

# Create certbot configuration
cat > /etc/letsencrypt/cli.ini << EOF
# Let's Encrypt CLI configuration
email = ${CERT_EMAIL}
agree-tos = true
non-interactive = true
manual-public-ip-logging-ok = true
EOF

# Function to obtain certificate
obtain_certificate() {
    local domain=$1
    
    print_info "Obtaining certificate for domain: $domain"
    
    # Create certificate directory
    mkdir -p /etc/letsencrypt/live/$domain
    
    # Run certbot with your plugin DNS challenge
    certbot certonly \
        --dns-your-plugin \
        --dns-your-plugin-credentials /etc/letsencrypt/your-plugin.ini \
        --email $CERT_EMAIL \
        --agree-tos \
        --non-interactive \
        --manual-public-ip-logging-ok \
        -d $domain \
        --config-dir /etc/letsencrypt \
        --work-dir /var/lib/letsencrypt \
        --logs-dir /var/log/letsencrypt
    
    print_success "Certificate obtained for $domain"
}

# Function to renew certificate
renew_certificate() {
    local domain=$1
    
    print_info "Renewing certificate for domain: $domain"
    
    certbot renew \
        --cert-name $domain \
        --config-dir /etc/letsencrypt \
        --work-dir /var/lib/letsencrypt \
        --logs-dir /var/log/letsencrypt
    
    print_success "Certificate renewed for $domain"
}

# Create your plugin credentials file
cat > /etc/letsencrypt/your-plugin.ini << EOF
# Your Plugin API credentials
dns_your_plugin_api_key = ${YOUR_API_KEY}
dns_your_plugin_api_secret = ${YOUR_API_SECRET}
EOF

chmod 600 /etc/letsencrypt/your-plugin.ini

# Process each domain
IFS=',' read -ra DOMAIN_ARRAY <<< "$DOMAINS"
for domain in "${DOMAIN_ARRAY[@]}"; do
    domain=$(echo $domain | xargs) # Trim whitespace
    
    if [ -d "/etc/letsencrypt/live/$domain" ]; then
        print_info "Certificate directory exists for $domain, attempting renewal"
        renew_certificate $domain
    else
        print_info "No certificate found for $domain, obtaining new certificate"
        obtain_certificate $domain
    fi
done

print_success "Your Plugin DNS challenge setup completed"
print_info "Certificates will be automatically renewed"
```

### Step 2: Add Docker Stage

Add a new stage to your `Dockerfile`:

```dockerfile
# HTTPS with Your Plugin DNS for automatic SSL certificates
FROM certbot AS your-plugin
RUN pip3 install certbot-dns-your-plugin

COPY ./entrypoints /entrypoints
RUN find /entrypoints -type f -name '*.sh' -exec chmod +x {} +

ENTRYPOINT ["/entrypoints/plugins/your-plugin.sh"]
```

### Step 3: Make Script Executable

```bash
chmod +x entrypoints/plugins/your-plugin.sh
```

### Step 4: Test Your Plugin

```bash
# Build your plugin
make build-your-plugin

# Test locally
docker run -d -p 80:80 -p 443:443 \
  -e CERT_EMAIL=your@email.com \
  -e DOMAINS=example.com \
  -e YOUR_API_KEY=your_key \
  kauech/nginx:your-plugin
```

### Step 5: Add to Docker Compose (Optional)

Add to `compose.yml`:

```yaml
# HTTPS with Your Plugin DNS for automatic SSL certificates
nginx-your-plugin:
  build:
    context: .
    target: your-plugin
  image: kauech/nginx:your-plugin
  ports:
    - "8084:80"
    - "8447:443"
  environment:
    YOUR_API_KEY: ${YOUR_API_KEY}
    YOUR_API_SECRET: ${YOUR_API_SECRET}
    CERT_EMAIL: ${CERT_EMAIL}
    DOMAINS: ${DOMAINS:-example.com}
    NGINX_MAP_HOST_AS_TARGET: |
      default http://app:3000;
    NGINX_FORCE_HTTPS: "true"
  volumes:
    - ./data/letsencrypt:/etc/letsencrypt
  restart: unless-stopped
  depends_on:
    - app
```

## 🔧 Plugin Template

Use this template for new plugins:

```bash
#!/bin/bash

# [Plugin Name] DNS Challenge Plugin
# [Brief description]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check required environment variables
if [ -z "$CERT_EMAIL" ]; then
    print_error "CERT_EMAIL environment variable is required"
    exit 1
fi

if [ -z "$DOMAINS" ]; then
    print_error "DOMAINS environment variable is required"
    exit 1
fi

# [Add your plugin-specific environment variable checks]

print_info "Setting up Let's Encrypt certificates with [Plugin Name] DNS challenge..."

# [Install your plugin dependencies]

# Create certbot configuration
cat > /etc/letsencrypt/cli.ini << EOF
# Let's Encrypt CLI configuration
email = ${CERT_EMAIL}
agree-tos = true
non-interactive = true
manual-public-ip-logging-ok = true
EOF

# Function to obtain certificate
obtain_certificate() {
    local domain=$1
    
    print_info "Obtaining certificate for domain: $domain"
    
    # Create certificate directory
    mkdir -p /etc/letsencrypt/live/$domain
    
    # [Run certbot with your plugin DNS challenge]
    
    print_success "Certificate obtained for $domain"
}

# Function to renew certificate
renew_certificate() {
    local domain=$1
    
    print_info "Renewing certificate for domain: $domain"
    
    certbot renew \
        --cert-name $domain \
        --config-dir /etc/letsencrypt \
        --work-dir /var/lib/letsencrypt \
        --logs-dir /var/log/letsencrypt
    
    print_success "Certificate renewed for $domain"
}

# [Create your plugin credentials file if needed]

# Process each domain
IFS=',' read -ra DOMAIN_ARRAY <<< "$DOMAINS"
for domain in "${DOMAIN_ARRAY[@]}"; do
    domain=$(echo $domain | xargs) # Trim whitespace
    
    if [ -d "/etc/letsencrypt/live/$domain" ]; then
        print_info "Certificate directory exists for $domain, attempting renewal"
        renew_certificate $domain
    else
        print_info "No certificate found for $domain, obtaining new certificate"
        obtain_certificate $domain
    fi
done

print_success "[Plugin Name] DNS challenge setup completed"
print_info "Certificates will be automatically renewed"
```

## 📚 Popular DNS Providers

Here are some popular DNS providers you can add as plugins:

### Already Implemented
- ✅ Cloudflare
- ✅ AWS Route53
- ✅ GoDaddy

### To Implement
- 🔲 Google Cloud DNS
- 🔲 Azure DNS
- 🔲 DigitalOcean DNS
- 🔲 Namecheap
- 🔲 Vultr DNS
- 🔲 Linode DNS
- 🔲 Hetzner DNS
- 🔲 OVH DNS

## 🧪 Testing Plugins

### Test Individual Plugin

```bash
# Build specific plugin
make build-your-plugin

# Test with environment variables
docker run -d --name test-your-plugin \
  -p 80:80 -p 443:443 \
  -e CERT_EMAIL=test@example.com \
  -e DOMAINS=test.example.com \
  -e YOUR_API_KEY=test_key \
  kauech/nginx:your-plugin

# Check logs
docker logs test-your-plugin

# Clean up
docker stop test-your-plugin
docker rm test-your-plugin
```

### Test All Plugins

```bash
# Build all plugins
make dev-build

# Test all plugins
make dev-test
```

## 🔍 Debugging

### Enable Debug Mode

```bash
# Add to your plugin script
set -x  # Enable debug mode
```

### Check Plugin Installation

```bash
# Check if certbot plugin is installed
docker run --rm kauech/nginx:your-plugin certbot plugins
```

### Check Environment Variables

```bash
# Print environment variables
docker run --rm kauech/nginx:your-plugin env | grep -E "(CERT_EMAIL|DOMAINS|YOUR_)"
```

## 📝 Best Practices

1. **Error Handling**: Always check required environment variables
2. **Logging**: Use colored output for better readability
3. **Security**: Set proper permissions on credential files (600)
4. **Documentation**: Document all required environment variables
5. **Testing**: Test with both new certificates and renewals
6. **Compatibility**: Ensure compatibility with certbot plugins

## 🚀 Example: Adding Google Cloud DNS

Here's a complete example of adding Google Cloud DNS:

### 1. Create Plugin Script

```bash
# entrypoints/plugins/googlecloud.sh
#!/bin/bash

# Google Cloud DNS Challenge Plugin
# Automatic DNS challenge using Google Cloud DNS

set -e

# [Standard plugin code with Google Cloud specific variables]
# Check for GOOGLE_CLOUD_PROJECT, GOOGLE_APPLICATION_CREDENTIALS
# Install certbot-dns-google
# Use --dns-google and --dns-google-credentials
```

### 2. Add Docker Stage

```dockerfile
# HTTPS with Google Cloud DNS for automatic SSL certificates
FROM certbot AS googlecloud
RUN pip3 install certbot-dns-google

COPY ./entrypoints /entrypoints
RUN find /entrypoints -type f -name '*.sh' -exec chmod +x {} +

ENTRYPOINT ["/entrypoints/plugins/googlecloud.sh"]
```

### 3. Test

```bash
make build-googlecloud
make test-googlecloud
```

That's it! Your new plugin is automatically detected and available in all build commands.

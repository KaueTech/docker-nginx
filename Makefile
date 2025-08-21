# Docker Nginx Build and Push Makefile
# Smart build system for single-stage final Dockerfile with plugins
export DOCKER_BUILDKIT=1

# Variables
DOCKER_REGISTRY ?= kauech
IMAGE_NAME ?= nginx
VERSION ?= latest
PLATFORMS ?= linux/amd64,linux/arm64,linux/arm/v7

# Auto-detect plugins from entrypoints/plugins folder
PLUGINS := $(shell find ./entrypoints/plugins -maxdepth 1 -type f -name '*.sh' -exec basename {} .sh \; | tr '\n' ' ')

# Derived targets
PUSH_TARGETS := $(addprefix push-,$(PLUGINS))
CLEAN_TARGETS := $(addprefix clean-,$(PLUGINS))

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help build-all clean-all docker-login setup-buildx
.PHONY: $(PUSH_TARGETS) $(CLEAN_TARGETS)
.PHONY: $(addprefix build-,$(PLUGINS))

# --------------------------
# Help
# --------------------------
help: ## Show this help message
	@echo 'Docker Nginx Build and Push System'
	@echo ''
	@echo 'Available plugins: $(PLUGINS)'
	@echo ''
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ''
	@echo 'Plugin-specific targets:'
	@for plugin in $(PLUGINS); do \
		echo "  build-$$plugin     Build $$plugin variant"; \
		echo "  push-$$plugin      Push $$plugin variant"; \
		echo "  clean-$$plugin     Clean $$plugin variant"; \
	done

# --------------------------
# Setup Buildx
# --------------------------
setup-buildx: ## Setup Docker Buildx for multi-architecture builds
	@echo "$(BLUE)[INFO]$(NC) Setting up Docker Buildx..."
	docker buildx create --name multiarch --use || true
	docker buildx inspect --bootstrap
	@echo "$(GREEN)[SUCCESS]$(NC) Docker Buildx setup complete"

# --------------------------
# Build a single plugin variant
# --------------------------
build-%: ## Build specific plugin variant via ARG PLUGIN
	@echo "$(BLUE)[INFO]$(NC) Building $* variant..."
	docker build --build-arg PLUGIN=$* \
		-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$* \
		-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):latest .

# --------------------------
# Push a single plugin variant
# --------------------------
$(PUSH_TARGETS): push-%: build-% ## Push specific plugin variant
	@echo "$(BLUE)[INFO]$(NC) Pushing $* variant..."
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):$*

# --------------------------
# Clean a single plugin variant
# --------------------------
$(CLEAN_TARGETS): clean-%: ## Clean specific plugin variant
	@echo "$(BLUE)[INFO]$(NC) Cleaning $* variant..."
	docker rmi $(DOCKER_REGISTRY)/$(IMAGE_NAME):$* || true

# --------------------------
# Build all variants for all architectures and push
# --------------------------
build-all: setup-buildx ## Build and push all plugin variants
	@echo "$(BLUE)[INFO]$(NC) Building all plugin variants..."
	@for plugin in $(PLUGINS); do \
		echo "$(BLUE)[INFO]$(NC) Building $$plugin variant..."; \
		docker buildx build --platform $(PLATFORMS) \
			--build-arg PLUGIN=$$plugin \
			-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$$plugin \
			-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$$plugin-$(VERSION) \
			--push .; \
	done
	@echo "$(GREEN)[SUCCESS]$(NC) All variants built and pushed successfully"

# --------------------------
# Clean all plugin variants
# --------------------------
clean-all: $(CLEAN_TARGETS) ## Clean up all Docker images
	@echo "$(GREEN)[SUCCESS]$(NC) All images cleaned"

# --------------------------
# Docker login
# --------------------------
docker-login: ## Login to Docker registry
	@echo "$(BLUE)[INFO]$(NC) Please enter your Docker Hub credentials:"
	docker login

# --------------------------
# Quick build/push for a specific plugin (example: openssl)
# --------------------------
quick-build: ## Quick build for current architecture (openssl)
	@echo "$(BLUE)[INFO]$(NC) Quick build for current architecture..."
	docker build --build-arg PLUGIN=openssl \
		-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):openssl \
		-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):latest .
	@echo "$(GREEN)[SUCCESS]$(NC) Quick build completed"

quick-push: docker-login quick-build ## Quick build and push for current architecture
	@echo "$(BLUE)[INFO]$(NC) Pushing to registry..."
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):openssl
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):latest
	@echo "$(GREEN)[SUCCESS]$(NC) Quick push completed"

# --------------------------
# Release: full multiarch build and push
# --------------------------
release: docker-login build-all ## Full release build and push for all architectures
	@echo "$(GREEN)[SUCCESS]$(NC) Release completed successfully!"

# --------------------------
# Development: build locally without push
# --------------------------
dev-build: ## Build all plugin variants locally (no push)
	@echo "$(BLUE)[INFO]$(NC) Building all variants locally..."
	@for plugin in $(PLUGINS); do \
		echo "$(BLUE)[INFO]$(NC) Building $$plugin variant..."; \
		docker build --build-arg PLUGIN=$$plugin \
			-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$$plugin .; \
	done
	@echo "$(GREEN)[SUCCESS]$(NC) All variants built locally"

# --------------------------
# List plugins
# --------------------------
list-plugins: ## List all available plugins
	@echo "$(BLUE)[INFO]$(NC) Available plugins:"
	@for plugin in $(PLUGINS); do \
		echo "  - $$plugin"; \
	done

# --------------------------
# Show build info
# --------------------------
info: ## Show build information
	@echo "$(BLUE)[INFO]$(NC) Build Information:"
	@echo "  Registry: $(DOCKER_REGISTRY)"
	@echo "  Image: $(IMAGE_NAME)"
	@echo "  Version: $(VERSION)"
	@echo "  Platforms: $(PLATFORMS)"
	@echo "  Plugins: $(PLUGINS)"
# Docker Nginx Build and Push Makefile
# Smart build system that automatically detects all plugins

# Variables
DOCKER_REGISTRY ?= kauech
IMAGE_NAME ?= nginx
VERSION ?= latest
PLATFORMS ?= linux/amd64,linux/arm64,linux/arm/v7

# Auto-detect plugins from Dockerfile (only final stages)
PLUGINS := $(shell grep -E '^FROM.*AS [a-zA-Z]' Dockerfile | grep -v '^FROM.*AS base' | grep -v '^FROM.*AS https' | grep -v '^FROM.*AS certbot' | sed 's/.*AS //' | tr '\n' ' ')
BUILD_TARGETS := $(addprefix build-,$(PLUGINS))
PUSH_TARGETS := $(addprefix push-,$(PLUGINS))
CLEAN_TARGETS := $(addprefix clean-,$(PLUGINS))

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help build-all clean-all docker-login setup-buildx
.PHONY: $(BUILD_TARGETS) $(PUSH_TARGETS) $(CLEAN_TARGETS)

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

setup-buildx: ## Setup Docker Buildx for multi-architecture builds
	@echo "$(BLUE)[INFO]$(NC) Setting up Docker Buildx..."
	docker buildx create --name multiarch --use || true
	docker buildx inspect --bootstrap
	@echo "$(GREEN)[SUCCESS]$(NC) Docker Buildx setup complete"

# Auto-generate build targets for each plugin
$(BUILD_TARGETS): build-%: ## Build specific plugin variant
	@echo "$(BLUE)[INFO]$(NC) Building $* variant..."
	docker build --target $* -t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$* .

# Auto-generate push targets for each plugin
$(PUSH_TARGETS): push-%: build-% ## Push specific plugin variant
	@echo "$(BLUE)[INFO]$(NC) Pushing $* variant..."
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):$*

# Auto-generate clean targets for each plugin
$(CLEAN_TARGETS): clean-%: ## Clean specific plugin variant
	@echo "$(BLUE)[INFO]$(NC) Cleaning $* variant..."
	docker rmi $(DOCKER_REGISTRY)/$(IMAGE_NAME):$* || true

build-all: setup-buildx ## Build and push all variants for all architectures
	@echo "$(BLUE)[INFO]$(NC) Building all variants for all architectures..."
	@for plugin in $(PLUGINS); do \
		echo "$(BLUE)[INFO]$(NC) Building $$plugin variant..."; \
		if [ "$$plugin" = "http" ]; then \
			docker buildx build --platform $(PLATFORMS) --target $$plugin \
				-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):latest \
				-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(VERSION) \
				-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$$plugin \
				-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$$plugin-$(VERSION) \
				--push .; \
		else \
			docker buildx build --platform $(PLATFORMS) --target $$plugin \
				-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$$plugin \
				-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$$plugin-$(VERSION) \
				--push .; \
		fi; \
	done
	@echo "$(GREEN)[SUCCESS]$(NC) All variants built and pushed successfully"

clean-all: $(CLEAN_TARGETS) ## Clean up all Docker images
	@echo "$(GREEN)[SUCCESS]$(NC) All images cleaned"

docker-login: ## Login to Docker registry
	@echo "$(BLUE)[INFO]$(NC) Please enter your Docker Hub credentials:"
	docker login

# Quick commands
quick-build: ## Quick build for current architecture
	@echo "$(BLUE)[INFO]$(NC) Quick build for current architecture..."
	docker build --target openssl -t $(DOCKER_REGISTRY)/$(IMAGE_NAME):openssl -t $(DOCKER_REGISTRY)/$(IMAGE_NAME):latest .
	@echo "$(GREEN)[SUCCESS]$(NC) Quick build completed"

quick-push: docker-login quick-build ## Quick build and push for current architecture
	@echo "$(BLUE)[INFO]$(NC) Pushing to registry..."
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):openssl
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):latest
	@echo "$(GREEN)[SUCCESS]$(NC) Quick push completed"

release: docker-login build-all ## Full release build and push for all architectures
	@echo "$(GREEN)[SUCCESS]$(NC) Release completed successfully!"

# Development commands
dev-build: ## Build all variants locally (no push)
	@echo "$(BLUE)[INFO]$(NC) Building all variants locally..."
	@for plugin in $(PLUGINS); do \
		echo "$(BLUE)[INFO]$(NC) Building $$plugin variant..."; \
		if [ "$$plugin" = "openssl" ]; then \
			docker build --target $$plugin -t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$$plugin -t $(DOCKER_REGISTRY)/$(IMAGE_NAME):latest .; \
		else \
			docker build --target $$plugin -t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$$plugin .; \
		fi; \
	done
	@echo "$(GREEN)[SUCCESS]$(NC) All variants built locally"

# Utility commands
list-plugins: ## List all available plugins
	@echo "$(BLUE)[INFO]$(NC) Available plugins:"
	@for plugin in $(PLUGINS); do \
		echo "  - $$plugin"; \
	done

info: ## Show build information
	@echo "$(BLUE)[INFO]$(NC) Build Information:"
	@echo "  Registry: $(DOCKER_REGISTRY)"
	@echo "  Image: $(IMAGE_NAME)"
	@echo "  Version: $(VERSION)"
	@echo "  Platforms: $(PLATFORMS)"
	@echo "  Plugins: $(PLUGINS)"


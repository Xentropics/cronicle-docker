.PHONY: help build up down restart logs clean backup restore shell

# Variables
IMAGE_NAME := xentropics/cronicle
VERSION := latest
CONTAINER_NAME := cronicle

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the Docker image
	docker-compose build

up: ## Start the containers
	docker-compose up -d

down: ## Stop and remove containers
	docker-compose down

restart: ## Restart the containers
	docker-compose restart

logs: ## View container logs
	docker-compose logs -f

ps: ## Show running containers
	docker-compose ps

clean: ## Remove containers, volumes, and images
	docker-compose down -v
	docker rmi $(IMAGE_NAME):$(VERSION) 2>/dev/null || true

shell: ## Open a shell in the running container
	docker-compose exec cronicle /bin/bash

backup: ## Backup data and logs volumes
	@echo "Creating backups..."
	@mkdir -p backups
	docker run --rm -v cronicle-data:/data -v $(PWD)/backups:/backup \
		ubuntu tar czf /backup/cronicle-data-$(shell date +%Y%m%d_%H%M%S).tar.gz -C /data .
	docker run --rm -v cronicle-logs:/logs -v $(PWD)/backups:/backup \
		ubuntu tar czf /backup/cronicle-logs-$(shell date +%Y%m%d_%H%M%S).tar.gz -C /logs .
	@echo "Backups created in ./backups/"

restore-data: ## Restore data volume from backup (requires BACKUP_FILE variable)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Error: BACKUP_FILE variable is required"; \
		echo "Usage: make restore-data BACKUP_FILE=backups/cronicle-data-YYYYMMDD_HHMMSS.tar.gz"; \
		exit 1; \
	fi
	docker run --rm -v cronicle-data:/data -v $(PWD)/backups:/backup \
		ubuntu tar xzf /backup/$(notdir $(BACKUP_FILE)) -C /data

restore-logs: ## Restore logs volume from backup (requires BACKUP_FILE variable)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Error: BACKUP_FILE variable is required"; \
		echo "Usage: make restore-logs BACKUP_FILE=backups/cronicle-logs-YYYYMMDD_HHMMSS.tar.gz"; \
		exit 1; \
	fi
	docker run --rm -v cronicle-logs:/logs -v $(PWD)/backups:/backup \
		ubuntu tar xzf /backup/$(notdir $(BACKUP_FILE)) -C /logs

init: ## Initialize environment (copy .env.example to .env)
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file from .env.example"; \
		echo "Please edit .env and update the CRONICLE_secret_key!"; \
	else \
		echo ".env file already exists"; \
	fi

setup: init build ## Complete setup (init + build)
	@echo "Setup complete! Run 'make up' to start the service."

chmod-workloads: ## Make workload scripts executable
	find workloads -type f -name "*.sh" -exec chmod +x {} \;
	find workloads -type f -name "*.py" -exec chmod +x {} \;
	@echo "Made all .sh and .py files in workloads executable"

test: ## Run basic tests
	@echo "Testing container health..."
	docker-compose up -d
	@sleep 10
	@docker-compose exec cronicle curl -f http://localhost:3012/ && echo "✓ Health check passed" || echo "✗ Health check failed"

update: ## Update and rebuild the image
	docker-compose down
	docker-compose build --no-cache
	docker-compose up -d
	@echo "Update complete!"

stats: ## Show container resource usage
	docker stats $(CONTAINER_NAME) --no-stream

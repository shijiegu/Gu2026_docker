.PHONY: run down check_env only_run

run: check_env only_run

# Include .env file
include .env

# Helper: detect whether the collab_hub container is currently running
IS_RUNNING=$(shell docker ps --filter "name=collab_hub" --filter "status=running" -q)

# Verify the .env file is present
check_env:
	@if [ ! -f .env ]; then \
		echo ".env file not found!"; \
		echo "This repo ships with a .env file; restore it before running."; \
		exit 1; \
	fi

# Pull (if needed) and start the published containers in the background
only_run:
	@docker compose -f docker-compose-collab.yml up -d

# Stop and remove the running containers (volumes are preserved)
down:
	@if [ -z "$(IS_RUNNING)" ]; then \
		echo "The containers are not running."; \
	else \
		docker compose -f docker-compose-collab.yml down; \
	fi

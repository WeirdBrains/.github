#!/bin/bash
# Mandible Ecosystem Cleanup Script for Linux/macOS
# This script stops and removes all Mandible ecosystem containers

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print banner
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}  Mandible Ecosystem Cleanup Tool  ${NC}"
echo -e "${GREEN}=================================${NC}"

# Define docker-compose file path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_COMPOSE_FILE="${SCRIPT_DIR}/../docker/docker-compose.yml"

# Stop and remove Docker Compose services
echo -e "\n${YELLOW}Stopping Docker Compose services...${NC}"
docker-compose -f "${DOCKER_COMPOSE_FILE}" down

# Stop and remove PostgreSQL containers
echo -e "\n${YELLOW}Stopping and removing PostgreSQL containers...${NC}"
docker stop mandible_postgres_sso mandible_postgres_main 2>/dev/null || true
docker rm mandible_postgres_sso mandible_postgres_main 2>/dev/null || true

echo -e "\n${GREEN}Cleanup complete!${NC}"

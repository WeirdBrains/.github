#!/bin/bash
set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print banner
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}  Mandible Ecosystem Setup Tool  ${NC}"
echo -e "${GREEN}=================================${NC}"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Check Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git is not installed. Please install Git first.${NC}"
    exit 1
fi

echo -e "${GREEN}All prerequisites are installed.${NC}"

# Check if repositories exist and clone them if they don't
echo -e "\n${YELLOW}Checking for required repositories...${NC}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPOSITORIES=("sso_backend" "backend" "accounts" "mandible")

for repo in "${REPOSITORIES[@]}"; do
    if [ ! -d "${REPO_DIR}/${repo}" ]; then
        echo -e "${YELLOW}Repository ${repo} not found. Cloning from GitHub...${NC}"
        git clone "https://github.com/weirdbrains/${repo}.git" "${REPO_DIR}/${repo}"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to clone repository ${repo}. Please check your internet connection and GitHub access.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Repository ${repo} already exists.${NC}"
    fi
done

# Copy Dockerfiles to repositories
echo -e "\n${YELLOW}Setting up Dockerfiles...${NC}"
cp docker/sso_backend.Dockerfile ../../sso_backend/Dockerfile
cp docker/backend.Dockerfile ../../backend/Dockerfile

# Copy environment files
echo -e "\n${YELLOW}Setting up environment files...${NC}"
cp config/sso_backend.envrc ../../sso_backend/.envrc
cp config/backend.envrc ../../backend/.envrc

# Create build output directories
echo -e "\n${YELLOW}Creating build output directories...${NC}"
mkdir -p ../../accounts/build_output
mkdir -p ../../mandible/build_output

# Define docker-compose file path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_COMPOSE_FILE="${SCRIPT_DIR}/../docker/docker-compose.yml"

# Check for existing PostgreSQL containers and remove them if necessary
echo -e "\n${YELLOW}Checking for existing PostgreSQL containers...${NC}"
if docker ps -a --filter "name=mandible_postgres_sso" --format "{{.Names}}" | grep -q "mandible_postgres_sso"; then
    echo -e "${YELLOW}Found existing SSO PostgreSQL container. Removing it...${NC}"
    docker stop mandible_postgres_sso 2>/dev/null || true
    docker rm mandible_postgres_sso 2>/dev/null || true
fi

if docker ps -a --filter "name=mandible_postgres_main" --format "{{.Names}}" | grep -q "mandible_postgres_main"; then
    echo -e "${YELLOW}Found existing main PostgreSQL container. Removing it...${NC}"
    docker stop mandible_postgres_main 2>/dev/null || true
    docker rm mandible_postgres_main 2>/dev/null || true
fi

# Start PostgreSQL containers
echo -e "\n${YELLOW}Starting PostgreSQL containers...${NC}"
docker run -d --name mandible_postgres_sso -p 5433:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=sso_db postgres:13
docker run -d --name mandible_postgres_main -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=mandible_db postgres:13

# Wait for PostgreSQL to be ready
echo -e "\n${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
sleep 5

# Initialize databases
echo -e "\n${YELLOW}Initializing databases...${NC}"
cat sql/sso_db.sql | docker exec -i mandible_postgres_sso psql -U postgres -d sso_db

# Create test data
echo -e "\n${YELLOW}Creating test data...${NC}"

# Create test user in SSO database
docker exec -i mandible_postgres_sso psql -U postgres -d sso_db -c "INSERT INTO users (id, first_name, last_name, email, pass, admin_status) VALUES ('test-user-id', 'Test', 'User', 'test@example.com', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', true);"

# Create application record for Mandible
docker exec -i mandible_postgres_sso psql -U postgres -d sso_db -c "INSERT INTO applications (id, name, description, url, redirect_url, client_id, client_secret, user_id) VALUES ('mandible-app-id', 'Mandible', 'Mandible Application', 'http://localhost:8001', 'http://localhost:8001/callback', '41efb87a-ea14-475c-a49f-45c39f74bcbd', '2459eca2-faa1-4e95-9b30-077ed7e8fcd9', 'test-user-id');"

# Associate user with application
docker exec -i mandible_postgres_sso psql -U postgres -d sso_db -c "INSERT INTO application_users (id, user_id, application_id, user_role) VALUES ('app-user-id', 'test-user-id', 'mandible-app-id', 'admin');"

# Check if Docker Compose services are already running
echo -e "\n${YELLOW}Checking for existing Docker Compose services...${NC}"
if docker-compose -f "${DOCKER_COMPOSE_FILE}" ps --services --filter "status=running" | grep -q "."; then
    echo -e "${YELLOW}Found running Docker Compose services. Stopping them...${NC}"
    docker-compose -f "${DOCKER_COMPOSE_FILE}" down
fi

# Start services with Docker Compose
echo -e "\n${YELLOW}Starting services with Docker Compose...${NC}"
cd "${SCRIPT_DIR}/.."
docker-compose -f "${DOCKER_COMPOSE_FILE}" up -d

echo -e "\n${GREEN}Setup complete!${NC}"
echo -e "${GREEN}Accounts app: http://localhost:8000${NC}"
echo -e "${GREEN}Mandible app: http://localhost:8001${NC}"
echo -e "${GREEN}Test user: test@example.com / 123456${NC}"

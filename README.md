# Mandible Ecosystem Setup

This repository contains scripts and configuration files to automate the setup of the Mandible ecosystem.

## Prerequisites

- Docker and Docker Compose
- Git
- Flutter
- Dart

## Complete Setup from Scratch

### For Windows Users

```powershell
# Clone all required repositories
git clone https://github.com/weirdbrains/mandible-setup.git
cd mandible-setup

# Clone the Mandible ecosystem repositories
git clone https://github.com/weirdbrains/sso_backend.git
git clone https://github.com/weirdbrains/backend.git
git clone https://github.com/weirdbrains/accounts.git
git clone https://github.com/weirdbrains/mandible.git

# Run the setup script
.\scripts\setup.ps1
```

### For Linux/macOS Users

```bash
# Clone all required repositories
git clone https://github.com/weirdbrains/mandible-setup.git
cd mandible-setup

# Clone the Mandible ecosystem repositories
git clone https://github.com/weirdbrains/sso_backend.git
git clone https://github.com/weirdbrains/backend.git
git clone https://github.com/weirdbrains/accounts.git
git clone https://github.com/weirdbrains/mandible.git

# Make scripts executable
chmod +x scripts/*.sh

# Run the setup script
./scripts/setup.sh
```

## What This Does

1. Checks for required prerequisites
2. Sets up Dockerfiles and environment files
3. Creates PostgreSQL containers for SSO and main databases
4. Initializes the databases with required tables
5. Creates test data (test user, application, and associations)
6. Starts all services with Docker Compose

## Accessing the Applications

- Accounts App: http://localhost:8000
- Mandible App: http://localhost:8001

## Test User Credentials

- Email: test@example.com
- Password: 123456

## Cleanup

To stop and remove all containers and services:

### For Windows Users

```powershell
# Run the cleanup script
.\scripts\cleanup.ps1
```

### For Linux/macOS Users

```bash
# Run the cleanup script
./scripts/cleanup.sh
```

## Manual Setup

If you prefer to set up the ecosystem manually, follow these steps:

### 1. Clone the Repositories

```bash
# Clone all required repositories
git clone https://github.com/weirdbrains/sso_backend.git
git clone https://github.com/weirdbrains/backend.git
git clone https://github.com/weirdbrains/accounts.git
git clone https://github.com/weirdbrains/mandible.git
```

### 2. Set Up PostgreSQL Containers

```bash
# Create PostgreSQL container for SSO backend
docker run -d --name mandible_postgres_sso -p 5433:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=sso_db postgres:13

# Create PostgreSQL container for main backend
docker run -d --name mandible_postgres_main -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=mandible_db postgres:13
```

### 3. Initialize the Databases

```bash
# Initialize SSO database with tables
cat sql/sso_db.sql | docker exec -i mandible_postgres_sso psql -U postgres -d sso_db

# Create test user in SSO database
docker exec -i mandible_postgres_sso psql -U postgres -d sso_db -c "INSERT INTO users (id, first_name, last_name, email, pass, admin_status) VALUES ('test-user-id', 'Test', 'User', 'test@example.com', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', true);"

# Create application record for Mandible
docker exec -i mandible_postgres_sso psql -U postgres -d sso_db -c "INSERT INTO applications (id, name, description, url, redirect_url, client_id, client_secret, user_id) VALUES ('mandible-app-id', 'Mandible', 'Mandible Application', 'http://localhost:8001', 'http://localhost:8001/callback', '41efb87a-ea14-475c-a49f-45c39f74bcbd', '2459eca2-faa1-4e95-9b30-077ed7e8fcd9', 'test-user-id');"

# Associate user with application
docker exec -i mandible_postgres_sso psql -U postgres -d sso_db -c "INSERT INTO application_users (id, user_id, application_id, user_role) VALUES ('app-user-id', 'test-user-id', 'mandible-app-id', 'admin');"

# Initialize main database (if there's a ddl.sql file)
# cat sql/mandible_db.sql | docker exec -i mandible_postgres_main psql -U postgres -d mandible_db
```

### 4. Start Services with Docker Compose

```bash
# Start all services
docker-compose up -d
```

## Repository Structure

```
mandible-setup/
├── scripts/
│   ├── setup.ps1          # Windows setup script
│   ├── setup.sh           # Linux/macOS setup script
│   ├── cleanup.ps1        # Windows cleanup script
│   └── cleanup.sh         # Linux/macOS cleanup script
├── docker/
│   ├── sso_backend.Dockerfile
│   └── backend.Dockerfile
├── config/
│   ├── sso_backend.envrc
│   └── backend.envrc
└── sql/
    └── sso_db.sql         # SQL schema for SSO database
```

## Troubleshooting

### Database Connection Issues

If the backend services can't connect to the PostgreSQL databases:

1. Make sure the PostgreSQL containers are running:
   ```bash
   docker ps | grep postgres
   ```

2. Check if the host.docker.internal resolution is working:
   ```bash
   docker-compose exec sso_backend ping host.docker.internal
   ```

3. Verify the database credentials in the docker-compose.yml file

### Authentication Issues

If you encounter authentication issues:

1. Verify the client credentials in the database match those in the Mandible app:
   ```bash
   docker exec -i mandible_postgres_sso psql -U postgres -d sso_db -c "SELECT client_id, client_secret FROM applications WHERE id = 'mandible-app-id';"
   ```

2. Check the SSO backend logs for authentication errors:
   ```bash
   docker-compose logs sso_backend
   ```
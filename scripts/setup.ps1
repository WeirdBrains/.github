# Mandible Ecosystem Setup Script for Windows
# This script automates the setup of the Mandible ecosystem

# Define colors for output
$GREEN = "Green"
$YELLOW = "Yellow"
$RED = "Red"

# Print banner
Write-Host "=================================" -ForegroundColor $GREEN
Write-Host "  Mandible Ecosystem Setup Tool  " -ForegroundColor $GREEN
Write-Host "=================================" -ForegroundColor $GREEN

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor $YELLOW

# Check Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker is not installed. Please install Docker first." -ForegroundColor $RED
    exit 1
}

# Check Docker Compose
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "Docker Compose is not installed. Please install Docker Compose first." -ForegroundColor $RED
    exit 1
}

# Check Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed. Please install Git first." -ForegroundColor $RED
    exit 1
}

Write-Host "All prerequisites are installed." -ForegroundColor $GREEN

# Check if repositories exist and clone them if they don't
Write-Host "`nChecking for required repositories..." -ForegroundColor $YELLOW

$repoDir = Join-Path $PSScriptRoot "..\..\"
$repoDir = (Resolve-Path $repoDir).Path

$repositories = @(
    "sso_backend",
    "backend",
    "accounts",
    "mandible"
)

foreach ($repo in $repositories) {
    $repoPath = Join-Path $repoDir $repo
    if (-not (Test-Path $repoPath)) {
        Write-Host "Repository $repo not found. Cloning from GitHub..." -ForegroundColor $YELLOW
        $repoUrl = "https://github.com/weirdbrains/$repo.git"
        git clone $repoUrl $repoPath
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to clone repository $repo. Please check your internet connection and GitHub access." -ForegroundColor $RED
            exit 1
        }
    } else {
        Write-Host "Repository $repo already exists." -ForegroundColor $GREEN
    }
}

# Copy Dockerfiles to repositories
Write-Host "`nSetting up Dockerfiles..." -ForegroundColor $YELLOW
Copy-Item -Path "docker\sso_backend.Dockerfile" -Destination "..\..\sso_backend\Dockerfile" -Force
Copy-Item -Path "docker\backend.Dockerfile" -Destination "..\..\backend\Dockerfile" -Force

# Copy environment files
Write-Host "`nSetting up environment files..." -ForegroundColor $YELLOW
Copy-Item -Path "config\sso_backend.envrc" -Destination "..\..\sso_backend\.envrc" -Force
Copy-Item -Path "config\backend.envrc" -Destination "..\..\backend\.envrc" -Force

# Create build output directories
Write-Host "`nCreating build output directories..." -ForegroundColor $YELLOW
New-Item -Path "..\..\accounts\build_output" -ItemType Directory -Force | Out-Null
New-Item -Path "..\..\mandible\build_output" -ItemType Directory -Force | Out-Null

# Define docker-compose file path
$dockerComposeFile = Join-Path $PSScriptRoot "..\docker\docker-compose.yml"

# Check for existing PostgreSQL containers and remove them if necessary
Write-Host "`nChecking for existing PostgreSQL containers..." -ForegroundColor $YELLOW
$ssoContainerExists = docker ps -a --filter "name=mandible_postgres_sso" --format "{{.Names}}" | Select-String -Pattern "mandible_postgres_sso"
$mainContainerExists = docker ps -a --filter "name=mandible_postgres_main" --format "{{.Names}}" | Select-String -Pattern "mandible_postgres_main"

if ($ssoContainerExists) {
    Write-Host "Found existing SSO PostgreSQL container. Removing it..." -ForegroundColor $YELLOW
    docker stop mandible_postgres_sso 2>$null
    docker rm mandible_postgres_sso 2>$null
}

if ($mainContainerExists) {
    Write-Host "Found existing main PostgreSQL container. Removing it..." -ForegroundColor $YELLOW
    docker stop mandible_postgres_main 2>$null
    docker rm mandible_postgres_main 2>$null
}

# Start PostgreSQL containers
Write-Host "`nStarting PostgreSQL containers..." -ForegroundColor $YELLOW
docker run -d --name mandible_postgres_sso -p 5433:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=sso_db postgres:13
docker run -d --name mandible_postgres_main -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=mandible_db postgres:13

# Wait for PostgreSQL to be ready
Write-Host "`nWaiting for PostgreSQL to be ready..." -ForegroundColor $YELLOW
Start-Sleep -Seconds 5

# Initialize databases
Write-Host "`nInitializing databases..." -ForegroundColor $YELLOW
Get-Content "sql\sso_db.sql" | docker exec -i mandible_postgres_sso psql -U postgres -d sso_db

# Create test data
Write-Host "`nCreating test data..." -ForegroundColor $YELLOW

# Create test user in SSO database
docker exec -i mandible_postgres_sso psql -U postgres -d sso_db -c "INSERT INTO users (id, first_name, last_name, email, pass, admin_status) VALUES ('test-user-id', 'Test', 'User', 'test@example.com', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', true);"

# Create application record for Mandible
docker exec -i mandible_postgres_sso psql -U postgres -d sso_db -c "INSERT INTO applications (id, name, description, url, redirect_url, client_id, client_secret, user_id) VALUES ('mandible-app-id', 'Mandible', 'Mandible Application', 'http://localhost:8001', 'http://localhost:8001/callback', '41efb87a-ea14-475c-a49f-45c39f74bcbd', '2459eca2-faa1-4e95-9b30-077ed7e8fcd9', 'test-user-id');"

# Associate user with application
docker exec -i mandible_postgres_sso psql -U postgres -d sso_db -c "INSERT INTO application_users (id, user_id, application_id, user_role) VALUES ('app-user-id', 'test-user-id', 'mandible-app-id', 'admin');"

# Check if Docker Compose services are already running
Write-Host "`nChecking for existing Docker Compose services..." -ForegroundColor $YELLOW
$runningServices = docker-compose ps --services --filter "status=running" | Measure-Object -Line

if ($runningServices.Lines -gt 0) {
    Write-Host "Found running Docker Compose services. Stopping them..." -ForegroundColor $YELLOW
    docker-compose down
}

# Start services with Docker Compose
Write-Host "`nStarting services with Docker Compose..." -ForegroundColor $YELLOW
Set-Location $PSScriptRoot
docker-compose -f $dockerComposeFile up -d

Write-Host "`nSetup complete!" -ForegroundColor $GREEN
Write-Host "Accounts app: http://localhost:8000" -ForegroundColor $GREEN
Write-Host "Mandible app: http://localhost:8001" -ForegroundColor $GREEN
Write-Host "Test user: test@example.com / 123456" -ForegroundColor $GREEN

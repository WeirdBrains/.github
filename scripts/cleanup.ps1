# Mandible Ecosystem Cleanup Script for Windows
# This script stops and removes all Mandible ecosystem containers

# Define colors for output
$GREEN = "Green"
$YELLOW = "Yellow"
# $RED variable removed as it's not used

# Print banner
Write-Host "=================================" -ForegroundColor $GREEN
Write-Host "  Mandible Ecosystem Cleanup Tool  " -ForegroundColor $GREEN
Write-Host "=================================" -ForegroundColor $GREEN

# Define docker-compose file path
$dockerComposeFile = Join-Path $PSScriptRoot "..\docker\docker-compose.yml"

# Stop and remove Docker Compose services
Write-Host "`nStopping Docker Compose services..." -ForegroundColor $YELLOW
docker-compose -f $dockerComposeFile down

# Stop and remove PostgreSQL containers
Write-Host "`nStopping and removing PostgreSQL containers..." -ForegroundColor $YELLOW
docker stop mandible_postgres_sso mandible_postgres_main 2>$null
docker rm mandible_postgres_sso mandible_postgres_main 2>$null

Write-Host "`nCleanup complete!" -ForegroundColor $GREEN

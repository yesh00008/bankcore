# BankCore Deployment Script
# Deploys all 10 microservices + Backend API + Frontend

param(
    [switch]$Rebuild,
    [switch]$StopOnly,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  BankCore Advanced Deployment Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$services = @(
    "core-banking",
    "account-management",
    "transaction-processing",
    "loan-origination",
    "loan-servicing",
    "card-management",
    "bill-payment",
    "customer-service",
    "reporting-analytics",
    "compliance-aml"
)

# Stop existing containers
if ($StopOnly -or $Rebuild -or $Clean) {
    Write-Host "Stopping existing BankCore services..." -ForegroundColor Yellow
    
    foreach ($service in $services) {
        $containerName = "bankcore-$service"
        docker stop $containerName 2>$null
        docker rm $containerName 2>$null
    }
    
    # Stop Backend API and Frontend
    docker stop bankcore-backend-api 2>$null
    docker rm bankcore-backend-api 2>$null
    docker stop bankcore-frontend 2>$null
    docker rm bankcore-frontend 2>$null
    
    Write-Host "✓ All services stopped" -ForegroundColor Green
}

if ($Clean) {
    Write-Host "Removing Docker images..." -ForegroundColor Yellow
    docker rmi $(docker images 'bankcore-*' -q) 2>$null
    Write-Host "✓ Cleanup complete" -ForegroundColor Green
    exit 0
}

if ($StopOnly) {
    Write-Host "Services stopped. Use without -StopOnly to start them." -ForegroundColor Gray
    exit 0
}

# Check if infrastructure is running
Write-Host "Checking infrastructure..." -ForegroundColor Yellow
$postgres = docker ps --filter "name=payflow-postgres" --filter "status=running" --format "{{.Names}}"
$redis = docker ps --filter "name=payflow-redis" --filter "status=running" --format "{{.Names}}"

if (-not $postgres) {
    Write-Host "✗ PostgreSQL is not running!" -ForegroundColor Red
    Write-Host "  Start it with: cd platform/compose && docker-compose -f docker-compose.full.yml up -d" -ForegroundColor Gray
    exit 1
}

if (-not $redis) {
    Write-Host "⚠ Redis is not running (optional)" -ForegroundColor Yellow
}

Write-Host "✓ Infrastructure is ready" -ForegroundColor Green
Write-Host ""

# Build and start services using Docker Compose
Write-Host "Building and starting BankCore services..." -ForegroundColor Cyan
Write-Host ""

cd apps/application-2-bankcore

if ($Rebuild) {
    Write-Host "Rebuilding Docker images..." -ForegroundColor Yellow
    docker-compose -f docker-compose.bankcore.yml build --no-cache
} else {
    docker-compose -f docker-compose.bankcore.yml build
}

Write-Host ""
Write-Host "Starting all services..." -ForegroundColor Yellow
docker-compose -f docker-compose.bankcore.yml up -d

Write-Host ""
Write-Host "Waiting for services to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Check health of all services
Write-Host ""
Write-Host "=== Service Health Check ===" -ForegroundColor Cyan
Write-Host ""

$ports = 8100..8109
$healthy = 0
$total = 10

foreach ($port in $ports) {
    $serviceName = "Port $port"
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$port/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.status -eq "UP") {
            Write-Host "✓ $serviceName`: HEALTHY" -ForegroundColor Green
            $healthy++
        } else {
            Write-Host "⚠ $serviceName`: DEGRADED" -ForegroundColor Yellow
            $healthy++
        }
    } catch {
        Write-Host "✗ $serviceName`: DOWN" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Deployment Summary ===" -ForegroundColor Cyan
Write-Host "Services Running: $healthy/$total" -ForegroundColor $(if($healthy -eq $total){"Green"}else{"Yellow"})
Write-Host ""

if ($healthy -eq $total) {
    Write-Host "✓ All services deployed successfully!" -ForegroundColor Green
} elseif ($healthy -gt 0) {
    Write-Host "⚠ Partial deployment: $healthy/$total services running" -ForegroundColor Yellow
    Write-Host "Check logs with: docker-compose logs -f" -ForegroundColor Gray
} else {
    Write-Host "✗ Deployment failed. Check logs:" -ForegroundColor Red
    Write-Host "  docker-compose logs" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "=== Quick Access URLs ===" -ForegroundColor Cyan
Write-Host "Core Banking:           http://localhost:8100/health" -ForegroundColor White
Write-Host "Account Management:     http://localhost:8101/health" -ForegroundColor White
Write-Host "Transaction Processing: http://localhost:8102/health" -ForegroundColor White
Write-Host "Loan Origination:       http://localhost:8103/health" -ForegroundColor White
Write-Host "Loan Servicing:         http://localhost:8104/health" -ForegroundColor White
Write-Host "Card Management:        http://localhost:8105/health" -ForegroundColor White
Write-Host "Bill Payment:           http://localhost:8106/health" -ForegroundColor White
Write-Host "Customer Service:       http://localhost:8107/health" -ForegroundColor White
Write-Host "Reporting & Analytics:  http://localhost:8108/health" -ForegroundColor White
Write-Host "Compliance & AML:       http://localhost:8109/health" -ForegroundColor White
Write-Host ""
WriteHost "Backend API:            http://localhost:4000/api/health" -ForegroundColor White
Write-Host "Frontend App:           http://localhost:3002" -ForegroundColor White
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

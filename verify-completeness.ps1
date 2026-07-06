# BankCore Completeness Verification Script
# Checks that all files and services are properly created

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  BankCore Completeness Verification" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$baseDir = "c:\Users\thota\Music\Internship\fintech-benchmarks\apps\application-2-bankcore"
$totalChecks = 0
$passedChecks = 0

function Test-FileExists {
    param($path, $description)
    
    $global:totalChecks++
    $fullPath = Join-Path $baseDir $path
    
    if (Test-Path $fullPath) {
        Write-Host "✓ $description" -ForegroundColor Green
        $global:passedChecks++
        return $true
    } else {
        Write-Host "✗ $description" -ForegroundColor Red
        Write-Host "  Missing: $path" -ForegroundColor Gray
        return $false
    }
}

Write-Host "=== Microservices (10 Total) ===" -ForegroundColor Yellow
Write-Host ""

$services = @(
    @{Name="core-banking-service"; Port=8100},
    @{Name="account-management-service"; Port=8101},
    @{Name="transaction-processing-service"; Port=8102},
    @{Name="loan-origination-service"; Port=8103},
    @{Name="loan-servicing-service"; Port=8104},
    @{Name="card-management-service"; Port=8105},
    @{Name="bill-payment-service"; Port=8106},
    @{Name="customer-service-portal"; Port=8107},
    @{Name="reporting-analytics-service"; Port=8108},
    @{Name="compliance-aml-service"; Port=8109}
)

foreach ($service in $services) {
    $serviceName = $service.Name
    $port = $service.Port
    
    Write-Host "Service: $serviceName (Port $port)" -ForegroundColor Cyan
    Test-FileExists "bankcore\services\$serviceName\main.go" "  main.go"
    Test-FileExists "bankcore\services\$serviceName\go.mod" "  go.mod"
    Test-FileExists "bankcore\services\$serviceName\Dockerfile" "  Dockerfile"
    Write-Host ""
}

Write-Host "=== Frontend & Backend ===" -ForegroundColor Yellow
Write-Host ""
Test-FileExists "backend-api\index.js" "Backend API - index.js"
Test-FileExists "backend-api\package.json" "Backend API - package.json"
Test-FileExists "backend-api\Dockerfile" "Backend API - Dockerfile"
Write-Host ""
Test-FileExists "frontend\package.json" "Frontend - package.json"
Test-FileExists "frontend\Dockerfile" "Frontend - Dockerfile"
Test-FileExists "frontend\nginx.conf" "Frontend - nginx.conf"
Write-Host ""

Write-Host "=== Configuration Files ===" -ForegroundColor Yellow
Write-Host ""
Test-FileExists "docker-compose.bankcore.yml" "Docker Compose file"
Test-FileExists "deploy-bankcore.ps1" "Deployment script"
Test-FileExists "generate-services.ps1" "Service generator script"
Write-Host ""

Write-Host "=== Documentation ===" -ForegroundColor Yellow
Write-Host ""
Test-FileExists "README.md" "Main README"
Test-FileExists "API-DOCUMENTATION.md" "API Documentation"
Test-FileExists "ARCHITECTURE.md" "Architecture Overview"
Test-FileExists "LOGGING.md" "Logging Documentation"
Write-Host ""

Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Checks Passed: $passedChecks / $totalChecks" -ForegroundColor $(if($passedChecks -eq $totalChecks){"Green"}else{"Yellow"})

$percentage = [math]::Round(($passedChecks / $totalChecks) * 100, 1)
Write-Host "Completion: $percentage%" -ForegroundColor $(if($percentage -eq 100){"Green"}elseif($percentage -gt 90){"Yellow"}else{"Red"})

Write-Host ""

if ($passedChecks -eq $totalChecks) {
    Write-Host "✓ All files present! BankCore is complete." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Build services: .\deploy-bankcore.ps1 -Rebuild" -ForegroundColor White
    Write-Host "2. Start services: .\deploy-bankcore.ps1" -ForegroundColor White
    Write-Host "3. Check health: http://localhost:8100-8109/health" -ForegroundColor White
} else {
    $missing = $totalChecks - $passedChecks
    Write-Host "⚠ $missing file(s) missing. Review the list above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Count lines of code
Write-Host "=== Code Statistics ===" -ForegroundColor Cyan
Write-Host ""

$goFiles = Get-ChildItem "$baseDir\bankcore\services" -Filter "*.go" -Recurse -File
$goLines = ($goFiles | Get-Content | Measure-Object -Line).Lines

$jsFiles = Get-ChildItem "$baseDir\backend-api" -Filter "*.js" -File
$jsLines = ($jsFiles | Get-Content | Measure-Object -Line).Lines

$reactFiles = Get-ChildItem "$baseDir\frontend\src" -Filter "*.js" -Recurse -File -ErrorAction SilentlyContinue
$reactLines = if ($reactFiles) { ($reactFiles | Get-Content | Measure-Object -Line).Lines } else { 0 }

Write-Host "Go Code:        $goLines lines" -ForegroundColor White
Write-Host "Backend API:    $jsLines lines" -ForegroundColor White
Write-Host "Frontend Code:  $reactLines lines" -ForegroundColor White
Write-Host "Total:          $($goLines + $jsLines + $reactLines) lines" -ForegroundColor Green

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan

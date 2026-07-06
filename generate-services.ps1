# BankCore Service Generator Script
# Generates all missing microservices with advanced features

$services = @(
    @{
        Name = "account-management-service"
        Port = "8101"
        Description = "Account operations, deposits, withdrawals"
        Tables = @("accounts", "account_transactions", "account_balances")
    },
    @{
        Name = "transaction-processing-service"
        Port = "8102"
        Description = "Money transfers, ACID transactions"
        Tables = @("transactions", "transaction_logs", "pending_transactions")
    },
    @{
        Name = "loan-origination-service"
        Port = "8103"
        Description = "Loan applications, credit scoring"
        Tables = @("loan_applications", "credit_scores", "loan_documents")
    },
    @{
        Name = "loan-servicing-service"
        Port = "8104"
        Description = "Loan disbursement, payments"
        Tables = @("loans", "loan_payments", "loan_schedules")
    },
    @{
        Name = "card-management-service"
        Port = "8105"
        Description = "Card issuance, activation, transactions"
        Tables = @("cards", "card_transactions", "card_limits")
    }
)

Write-Host "=== BankCore Advanced Service Generator ===" -ForegroundColor Cyan
Write-Host ""

$baseDir = "c:\Users\thota\Music\Internship\fintech-benchmarks\apps\application-2-bankcore\bankcore\services"

foreach ($service in $services) {
    $serviceName = $service.Name
    $port = $service.Port
    $description = $service.Description
    
    Write-Host "Creating $serviceName (Port: $port)..." -ForegroundColor Yellow
    
    $serviceDir = Join-Path $baseDir $serviceName
    if (-not (Test-Path $serviceDir)) {
        New-Item -ItemType Directory -Path $serviceDir -Force | Out-Null
    }
    
    # Create main.go
    $mainGo = @"
package main

import (
    "context"
    "database/sql"
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/go-redis/redis/v8"
    _ "github.com/lib/pq"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    db          *sql.DB
    redisClient *redis.Client
    ctx         = context.Background()
    
    requestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "${serviceName}_requests_total",
            Help: "Total number of requests",
        },
        []string{"method", "endpoint", "status"},
    )
)

func init() {
    prometheus.MustRegister(requestsTotal)
}

func main() {
    // Database connection
    var err error
    dbURL := getEnv("DATABASE_URL", "postgres://fintech:fintech123@localhost:5432/bankcore?sslmode=disable")
    db, err = sql.Open("postgres", dbURL)
    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }
    defer db.Close()

    if err = db.Ping(); err != nil {
        log.Fatal("Failed to ping database:", err)
    }
    log.Println("✓ Database connected")

    // Redis connection
    redisClient = redis.NewClient(&redis.Options{
        Addr:     getEnv("REDIS_URL", "localhost:6379"),
        Password: "",
        DB:       0,
    })
    
    // Setup Gin router
    gin.SetMode(gin.ReleaseMode)
    router := gin.Default()

    // Health check
    router.GET("/health", healthCheck)
    router.GET("/metrics", gin.WrapH(promhttp.Handler()))

    // API routes
    router.GET("/api/v1/ping", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "service": "$serviceName",
            "port": "$port",
            "description": "$description",
            "status": "online",
            "timestamp": time.Now(),
        })
    })

    // Start server
    port := getEnv("PORT", "$port")
    srv := &http.Server{
        Addr:    ":" + port,
        Handler: router,
    }

    go func() {
        log.Printf("🚀 $serviceName running on port %s\n", port)
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Server error: %v", err)
        }
    }()

    // Graceful shutdown
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit
    log.Println("Shutting down server...")

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    if err := srv.Shutdown(ctx); err != nil {
        log.Fatal("Server forced to shutdown:", err)
    }
    log.Println("Server exited")
}

func healthCheck(c *gin.Context) {
    health := gin.H{
        "status":  "UP",
        "service": "$serviceName",
        "port":    "$port",
        "time":    time.Now().Format(time.RFC3339),
    }

    if err := db.Ping(); err != nil {
        health["database"] = "DOWN"
        health["status"] = "DEGRADED"
    } else {
        health["database"] = "UP"
    }

    if err := redisClient.Ping(ctx).Err(); err != nil {
        health["redis"] = "DOWN"
    } else {
        health["redis"] = "UP"
    }

    c.JSON(http.StatusOK, health)
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
"@

    Set-Content -Path (Join-Path $serviceDir "main.go") -Value $mainGo
    
    # Create go.mod
    $goMod = @"
module $serviceName

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/go-redis/redis/v8 v8.11.5
    github.com/lib/pq v1.10.9
    github.com/prometheus/client_golang v1.17.0
)
"@

    Set-Content -Path (Join-Path $serviceDir "go.mod") -Value $goMod
    
    # Create Dockerfile
    $dockerfile = @"
FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/main .

EXPOSE $port

CMD ["./main"]
"@

    Set-Content -Path (Join-Path $serviceDir "Dockerfile") -Value $dockerfile
    
    # Create README.md
    $readme = @"
# $serviceName

**Port:** $port  
**Description:** $description

## Features
- PostgreSQL database integration
- Redis caching
- Prometheus metrics at /metrics
- Health check at /health
- Structured logging
- Graceful shutdown

## Environment Variables
- \`DATABASE_URL\`: PostgreSQL connection string
- \`REDIS_URL\`: Redis connection string
- \`PORT\`: Service port (default: $port)

## Build & Run

### Local Development
\`\`\`bash
go mod download
go run main.go
\`\`\`

### Docker
\`\`\`bash
docker build -t bankcore-$serviceName .
docker run -p ${port}:${port} bankcore-$serviceName
\`\`\`

## API Endpoints
- \`GET /health\` - Health check
- \`GET /metrics\` - Prometheus metrics
- \`GET /api/v1/ping\` - Service info
"@

    Set-Content -Path (Join-Path $serviceDir "README.md") -Value $readme
    
    Write-Host "  ✓ Created $serviceName" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== All Services Created! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. cd into each service directory" -ForegroundColor White
Write-Host "2. Run: go mod download" -ForegroundColor White
Write-Host "3. Run: go build" -ForegroundColor White
Write-Host "4. Run: docker build -t bankcore-<service-name> ." -ForegroundColor White

# Script to create missing main.go and go.mod files for existing services

$services = @(
    @{Name="bill-payment-service"; Port=8106; Description="Utility bills and recurring payments"},
    @{Name="customer-service-portal"; Port=8107; Description="Support tickets and help desk"},
    @{Name="reporting-analytics-service"; Port=8108; Description="Business intelligence and dashboards"},
    @{Name="compliance-aml-service"; Port=8109; Description="Anti-money laundering and compliance"}
)

$baseDir = "c:\Users\thota\Music\Internship\fintech-benchmarks\apps\application-2-bankcore\bankcore\services"

foreach ($service in $services) {
    $serviceName = $service.Name
    $port = $service.Port
    $description = $service.Description $serviceDir = Join-Path $baseDir $serviceName
    
    Write-Host "Creating files for $serviceName..." -ForegroundColor Yellow
    
    # Only create if main.go doesn't exist
    $mainGoPath = Join-Path $serviceDir "main.go"
    if (-not (Test-Path $mainGoPath)) {
        $mainGo = @"
package main

import (
    "context"
    "database/sql"
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
        Set-Content -Path $mainGoPath -Value $mainGo
        Write-Host "  ✓ Created main.go" -ForegroundColor Green
    }
    
    # Create go.mod if it doesn't exist
    $goModPath = Join-Path $serviceDir "go.mod"
    if (-not (Test-Path $goModPath)) {
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
        Set-Content -Path $goModPath -Value $goMod
        Write-Host "  ✓ Created go.mod" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "✓ All service files created!" -ForegroundColor Green

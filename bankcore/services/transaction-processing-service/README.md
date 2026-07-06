# transaction-processing-service

**Port:** 8102  
**Description:** Money transfers, ACID transactions

## Features
- PostgreSQL database integration
- Redis caching
- Prometheus metrics at /metrics
- Health check at /health
- Structured logging
- Graceful shutdown

## Environment Variables
- \DATABASE_URL\: PostgreSQL connection string
- \REDIS_URL\: Redis connection string
- \PORT\: Service port (default: 8102)

## Build & Run

### Local Development
\\\ash
go mod download
go run main.go
\\\

### Docker
\\\ash
docker build -t bankcore-transaction-processing-service .
docker run -p 8102:8102 bankcore-transaction-processing-service
\\\

## API Endpoints
- \GET /health\ - Health check
- \GET /metrics\ - Prometheus metrics
- \GET /api/v1/ping\ - Service info

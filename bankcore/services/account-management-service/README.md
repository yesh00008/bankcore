# account-management-service

**Port:** 8101  
**Description:** Account operations, deposits, withdrawals

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
- \PORT\: Service port (default: 8101)

## Build & Run

### Local Development
\\\ash
go mod download
go run main.go
\\\

### Docker
\\\ash
docker build -t bankcore-account-management-service .
docker run -p 8101:8101 bankcore-account-management-service
\\\

## API Endpoints
- \GET /health\ - Health check
- \GET /metrics\ - Prometheus metrics
- \GET /api/v1/ping\ - Service info

# loan-servicing-service

**Port:** 8104  
**Description:** Loan disbursement, payments

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
- \PORT\: Service port (default: 8104)

## Build & Run

### Local Development
\\\ash
go mod download
go run main.go
\\\

### Docker
\\\ash
docker build -t bankcore-loan-servicing-service .
docker run -p 8104:8104 bankcore-loan-servicing-service
\\\

## API Endpoints
- \GET /health\ - Health check
- \GET /metrics\ - Prometheus metrics
- \GET /api/v1/ping\ - Service info

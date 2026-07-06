# loan-origination-service

**Port:** 8103  
**Description:** Loan applications, credit scoring

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
- \PORT\: Service port (default: 8103)

## Build & Run

### Local Development
\\\ash
go mod download
go run main.go
\\\

### Docker
\\\ash
docker build -t bankcore-loan-origination-service .
docker run -p 8103:8103 bankcore-loan-origination-service
\\\

## API Endpoints
- \GET /health\ - Health check
- \GET /metrics\ - Prometheus metrics
- \GET /api/v1/ping\ - Service info

# card-management-service

**Port:** 8105  
**Description:** Card issuance, activation, transactions

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
- \PORT\: Service port (default: 8105)

## Build & Run

### Local Development
\\\ash
go mod download
go run main.go
\\\

### Docker
\\\ash
docker build -t bankcore-card-management-service .
docker run -p 8105:8105 bankcore-card-management-service
\\\

## API Endpoints
- \GET /health\ - Health check
- \GET /metrics\ - Prometheus metrics
- \GET /api/v1/ping\ - Service info

FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o /app/main .
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
CMD ["./main"]

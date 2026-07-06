# Build stage
FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Production stage
FROM node:18-alpine

WORKDIR /app

RUN apk add --no-cache wget

COPY --from=build /app .

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:4000/api/health || exit 1

CMD ["node", "index.js"]

# BankCore Logging System Documentation

## Overview

The BankCore application implements a comprehensive, centralized logging system that collects logs from all services (frontend, backend API gateway, and microservices) for monitoring, debugging, and audit purposes.

## Architecture

### Components

1. **Frontend Logger** (`frontend/src/services/logger.js`)
   - Singleton logger instance
   - In-memory log storage (last 1000 logs)
   - Automatic error tracking
   - API call tracking
   - Component lifecycle tracking
   - User action tracking

2. **Backend API Gateway Logger** (`backend-api/index.js`)
   - Winston-based logging with multiple transports
   - File-based logging (combined.log, error.log)
   - In-memory log storage for quick access
   - Request/response logging middleware
   - Log aggregation endpoints

3. **Logs Viewer UI** (`frontend/src/pages/Logs/Logs.js`)
   - Real-time log viewing
   - Filtering by level, source, and search query
   - Auto-refresh capability
   - Export logs functionality
   - Statistics dashboard

## Features

### Frontend Logging

#### Log Levels
- **ERROR** (❌) - Critical errors that need immediate attention
- **WARN** (⚠️) - Warning messages for potential issues
- **INFO** (ℹ️) - Informational messages
- **DEBUG** (🐛) - Debug information for development
- **SUCCESS** (✅) - Success confirmations

#### Automatic Tracking
- Global error handler for uncaught errors
- Unhandled promise rejection handler
- API call success/failure tracking with duration
- User actions and interactions

#### Usage Examples

```javascript
import logger from './services/logger';

// Basic logging
logger.info('User logged in', { userId: 123 });
logger.error('Failed to fetch data', { error: err.message });
logger.warn('Rate limit approaching', { requests: 95 });
logger.debug('Component state', { state: componentState });
logger.success('Transaction completed', { txId: '123' });

// API call tracking (automatic via interceptors)
// Logs method, URL, status code, and duration

// User action tracking
logger.logUserAction('Button Click', { button: 'Submit Form', page: 'Accounts' });

// Component lifecycle (optional)
logger.logComponentMount('Dashboard');
logger.logComponentUnmount('Dashboard');
```

### Backend Logging

#### Winston Configuration

```javascript
// Console output: Colorized, human-readable
// File output: JSON format for log analysis tools
// Memory storage: Quick access to recent logs

- combined.log: All logs (10MB max, 5 files rotation)
- error.log: Error logs only (10MB max, 5 files rotation)
```

#### Request/Response Logging

Every API request is automatically logged with:
- HTTP method
- URL path
- Status code
- Response time
- IP address
- User agent

### API Endpoints

#### Get Logs
```http
GET /api/logs?level=ERROR&limit=100&source=frontend&service=api-gateway
```

Query Parameters:
- `level` - Filter by log level (ERROR, WARN, INFO, DEBUG, SUCCESS)
- `limit` - Maximum number of logs to return (default: 100)
- `source` - Filter by source (frontend, backend-api)
- `service` - Filter by service name

Response:
```json
[
  {
    "id": 1708185600000.123,
    "timestamp": "2026-02-17T10:30:00.000Z",
    "level": "ERROR",
    "message": "Failed to fetch customers",
    "metadata": {
      "source": "frontend",
      "url": "http://localhost:3002/customers",
      "error": "Network Error"
    }
  }
]
```

#### Post Log (from frontend/services)
```http
POST /api/logs
Content-Type: application/json

{
  "level": "ERROR",
  "message": "Payment processing failed",
  "metadata": {
    "source": "frontend",
    "component": "PaymentForm",
    "txId": "TX123456"
  }
}
```

#### Get Log Statistics
```http
GET /api/logs/stats
```

Response:
```json
{
  "total": 543,
  "byLevel": {
    "ERROR": 12,
    "WARN": 34,
    "INFO": 450,
    "DEBUG": 47
  },
  "bySource": {
    "frontend": 230,
    "backend-api": 313
  },
  "errors": 12,
  "warnings": 34
}
```

#### Clear Logs (Admin)
```http
DELETE /api/logs
```

## Frontend Logs Viewer

### Access
Navigate to **System Logs** in the sidebar menu or visit `http://localhost:3002/logs`

### Features

1. **Search & Filter**
   - Free text search across all log messages and metadata
   - Filter by log level (All, ERROR, WARN, INFO, DEBUG, SUCCESS)
   - Real-time filtering

2. **Auto-Refresh**
   - Toggle auto-refresh (updates every 5 seconds)
   - Manual refresh button

3. **Statistics Dashboard**
   - Total logs count
   - Error count
   - Warning count
   - Frontend logs count

4. **Logs Table**
   - Scrollable table (max 600px height)
   - Sticky header
   - Columns: Level, Timestamp, Source, Message, Service
   - Hover to see full metadata

5. **Log Details Panel**
   - Bottom panel showing recent 10 logs
   - JSON-formatted metadata
   - Console-style display with color coding

6. **Export Functionality**
   - Export all logs as JSON file
   - Filename includes timestamp
   - Useful for sharing or offline analysis

7. **Clear Logs**
   - Clear all logs from memory
   - Useful for starting fresh during testing

## Log Storage

### In-Memory Storage
- **Frontend**: Last 1000 logs
- **Backend**: Last 1000 logs
- Automatically removes oldest logs when limit reached
- Fast access for real-time viewing

### File Storage (Backend Only)
- `logs/combined.log` - All logs in JSON format
- `logs/error.log` - Errors only
- Automatic file rotation (10MB max per file)
- Keeps last 5 files

## Integration with Existing Services

### BankCore Microservices (Go)
Each microservice already has basic logging. To enhance them:

```go
// Add structured logging with metadata
log.Printf("[INFO] Customer created - ID: %d, Name: %s", customer.ID, customer.Name)
log.Printf("[ERROR] Database error: %v - Query: %s", err, query)
```

### Future Enhancements

1. **Centralized Log Aggregation**
   - Add Loki to Docker Compose
   - Configure Grafana dashboards
   - Query logs across all services

2. **Log Retention**
   - Implement log rotation policies
   - Archive old logs to S3/Azure Blob
   - Set retention periods (e.g., 30 days)

3. **Alerting**
   - Set up alerts for error thresholds
   - Email/Slack notifications
   - Critical error escalation

4. **Log Analysis**
   - Add Elasticsearch for full-text search
   - Create Kibana dashboards
   - Implement log pattern detection

5. **Performance Monitoring**
   - Track API response times
   - Monitor slow queries
   - Identify bottlenecks

## Best Practices

### When to Log

✅ **DO LOG:**
- API requests and responses
- User actions (login, logout, data changes)
- Errors and exceptions
- System events (startup, shutdown)
- Security events (authentication, authorization)
- Performance metrics (slow operations)

❌ **DON'T LOG:**
- Passwords or sensitive data
- Credit card numbers
- Personal identification information (PII)
- Large data payloads (use summary instead)

### Log Level Guidelines

- **ERROR**: System failures, exceptions, data loss
- **WARN**: Deprecated usage, performance issues, recoverable errors
- **INFO**: User actions, API calls, business events
- **DEBUG**: Detailed execution flow, variable values (dev only)
- **SUCCESS**: Completed operations, successful transactions

### Example Implementation

```javascript
// Good ✅
logger.info('User created account', {
  userId: user.id,
  accountType: account.type,
  timestamp: new Date()
});

// Bad ❌
logger.info('User created account with password: ' + password);

// Good ✅
logger.error('Database connection failed', {
  error: err.message,
  database: dbName,
  retryCount: 3
});

// Bad ❌
logger.error('Error: ' + err);
```

## Troubleshooting

### Logs Not Appearing in Viewer
1. Check if backend API is running (port 4000)
2. Verify CORS is enabled in backend
3. Check browser console for errors
4. Ensure auto-refresh is enabled

### Backend Logs Not Persisting
1. Check if `logs/` directory exists
2. Verify file permissions
3. Check disk space
4. Review Winston configuration

### High Memory Usage
1. Reduce MAX_LOGS constant (default: 1000)
2. Implement log archiving
3. Clear old logs periodically
4. Use external log storage

## Monitoring & Maintenance

### Daily Tasks
- Review error logs
- Check warning counts
- Monitor log growth rate

### Weekly Tasks
- Export and archive logs
- Clean up old log files
- Review log patterns

### Monthly Tasks
- Analyze error trends
- Update log retention policies
- Optimize log storage

## Security Considerations

1. **Access Control**
   - Implement authentication for logs endpoint
   - Restrict log deletion to admins only
   - Use role-based access control

2. **Data Protection**
   - Sanitize sensitive data before logging
   - Encrypt log files at rest
   - Use HTTPS for log transmission

3. **Audit Trail**
   - Log all admin actions
   - Track log access and modifications
   - Maintain immutable audit logs

## Performance Impact

- Frontend logging: ~0.1-0.5ms per log entry
- Backend logging: ~1-2ms per log entry (including file write)
- In-memory storage: ~100KB per 1000 logs
- File storage: Depends on log volume

## Conclusion

The BankCore logging system provides comprehensive visibility into application behavior across all layers. With real-time viewing, filtering, and export capabilities, it's a powerful tool for debugging, monitoring, and maintaining the application.

For questions or improvements, refer to the development team or update this documentation.

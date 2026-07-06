const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const axios = require('axios');
const winston = require('winston');
const fs = require('fs');
const path = require('path');

// Ensure logs directory exists
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir);
}

// In-memory log storage (last 1000 logs)
const inMemoryLogs = [];
const MAX_LOGS = 1000;

// Custom transport to store logs in memory
class MemoryTransport extends winston.Transport {
  constructor(opts) {
    super(opts);
  }
  
  log(info, callback) {
    const logEntry = {
      id: Date.now() + Math.random(),
      timestamp: info.timestamp,
      level: info.level.toUpperCase(),
      message: info.message,
      metadata: {
        ...info,
        source: 'backend-api',
        service: 'api-gateway'
      }
    };
    
    inMemoryLogs.unshift(logEntry);
    if (inMemoryLogs.length > MAX_LOGS) {
      inMemoryLogs.pop();
    }
    
    if (callback) callback();
  }
}

// Configure logger with file and memory transports
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    // Console transport
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.printf(({ timestamp, level, message, ...rest }) => {
          return `${timestamp} [${level}] ${message}${Object.keys(rest).length ? ' ' + JSON.stringify(rest) : ''}`;
        })
      )
    }),
    // File transport for all logs
    new winston.transports.File({
      filename: path.join(logsDir, 'combined.log'),
      maxsize: 10485760, // 10MB
      maxFiles: 5
    }),
    // File transport for errors only
    new winston.transports.File({
      filename: path.join(logsDir, 'error.log'),
      level: 'error',
      maxsize: 10485760, // 10MB
      maxFiles: 5
    }),
    // Memory transport
    new MemoryTransport({})
  ]
});

const app = express();
const PORT = process.env.PORT || 4000;

// Request logging middleware

// Middleware
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting - Increased for development
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP to 1000 requests per windowMs (increased for development)
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' }
});
app.use('/api/', limiter);

// Request logging middleware
app.use((req, res, next) => {
  const startTime = Date.now();
  
  // Log request
  logger.info(`→ ${req.method} ${req.originalUrl}`, {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  
  // Capture response
  const originalSend = res.send;
  res.send = function(data) {
    const duration = Date.now() - startTime;
    logger.info(`← ${req.method} ${req.originalUrl} ${res.statusCode} (${duration}ms)`, {
      method: req.method,
      url: req.originalUrl,
      statusCode: res.statusCode,
      duration: `${duration}ms`
    });
    originalSend.call(this, data);
  };
  
  next();
});

// Service URLs
const SERVICES = {
  coreBanking: process.env.CORE_BANKING_URL || 'http://localhost:8100',
  accountManagement: process.env.ACCOUNT_MANAGEMENT_URL || 'http://localhost:8101',
  transactionProcessing: process.env.TRANSACTION_PROCESSING_URL || 'http://localhost:8102',
  loanOrigination: process.env.LOAN_ORIGINATION_URL || 'http://localhost:8103',
  loanServicing: process.env.LOAN_SERVICING_URL || 'http://localhost:8104',
  cardManagement: process.env.CARD_MANAGEMENT_URL || 'http://localhost:8105',
  billPayment: process.env.BILL_PAYMENT_URL || 'http://localhost:8106',
  customerService: process.env.CUSTOMER_SERVICE_URL || 'http://localhost:8107',
  reporting: process.env.REPORTING_URL || 'http://localhost:8108',
  compliance: process.env.COMPLIANCE_URL || 'http://localhost:8109'
};

// Proxy helper function
const proxyRequest = async (url, method = 'GET', data = null, params = null) => {
  try {
    const config = {
      method,
      url,
      timeout: 10000
    };
    if (data) config.data = data;
    if (params) config.params = params;
    
    const response = await axios(config);
    return { success: true, data: response.data };
  } catch (error) {
    logger.error(`Proxy request failed: ${url}`, error.message);
    return {
      success: false,
      error: error.response?.data?.error || error.message || 'Service unavailable'
    };
  }
};

// ==================== HEALTH CHECK ====================
app.get('/api/health', async (req, res) => {
  const healthChecks = await Promise.all([
    proxyRequest(`${SERVICES.coreBanking}/health`),
    proxyRequest(`${SERVICES.accountManagement}/health`),
    proxyRequest(`${SERVICES.transactionProcessing}/health`),
    proxyRequest(`${SERVICES.loanOrigination}/health`),
    proxyRequest(`${SERVICES.loanServicing}/health`),
    proxyRequest(`${SERVICES.cardManagement}/health`),
    proxyRequest(`${SERVICES.billPayment}/health`),
    proxyRequest(`${SERVICES.customerService}/health`),
    proxyRequest(`${SERVICES.reporting}/health`),
    proxyRequest(`${SERVICES.compliance}/health`)
  ]);

  const allHealthy = healthChecks.every(check => check.success);
  res.status(allHealthy ? 200 : 503).json({
    api: 'healthy',
    services: {
      coreBanking: healthChecks[0].success,
      accountManagement: healthChecks[1].success,
      transactionProcessing: healthChecks[2].success,
      loanOrigination: healthChecks[3].success,
      loanServicing: healthChecks[4].success,
      cardManagement: healthChecks[5].success,
      billPayment: healthChecks[6].success,
      customerService: healthChecks[7].success,
      reporting: healthChecks[8].success,
      compliance: healthChecks[9].success
    }
  });
});

// ==================== LOGS ENDPOINTS ====================
// Get all logs from API Gateway
app.get('/api/logs', (req, res) => {
  try {
    const { level, limit = 100, source, service } = req.query;
    
    let filteredLogs = [...inMemoryLogs];
    
    // Filter by level
    if (level) {
      filteredLogs = filteredLogs.filter(log => log.level === level.toUpperCase());
    }
    
    // Filter by source
    if (source) {
      filteredLogs = filteredLogs.filter(log => log.metadata?.source === source);
    }
    
    // Filter by service
    if (service) {
      filteredLogs = filteredLogs.filter(log => log.metadata?.service === service);
    }
    
    // Limit results
    const limitNum = parseInt(limit);
    if (limitNum > 0) {
      filteredLogs = filteredLogs.slice(0, limitNum);
    }
    
    logger.info(`Logs retrieved: ${filteredLogs.length} entries`);
    res.json(filteredLogs);
  } catch (error) {
    logger.error('Error retrieving logs:', error);
    res.status(500).json({ error: 'Failed to retrieve logs' });
  }
});

// Receive logs from frontend or other services
app.post('/api/logs', (req, res) => {
  try {
    const { level, message, metadata } = req.body;
    
    if (!level || !message) {
      return res.status(400).json({ error: 'Level and message are required' });
    }
    
    // Store the log
    const logEntry = {
      id: Date.now() + Math.random(),
      timestamp: new Date().toISOString(),
      level: level.toUpperCase(),
      message,
      metadata: {
        ...metadata,
        receivedAt: new Date().toISOString()
      }
    };
    
    inMemoryLogs.unshift(logEntry);
    if (inMemoryLogs.length > MAX_LOGS) {
      inMemoryLogs.pop();
    }
    
    // Also log to Winston
    const logLevel = level.toLowerCase();
    if (logger[logLevel]) {
      logger[logLevel](message, metadata);
    } else {
      logger.info(message, metadata);
    }
    
    res.status(201).json({ success: true, message: 'Log received' });
  } catch (error) {
    logger.error('Error receiving log:', error);
    res.status(500).json({ error: 'Failed to store log' });
  }
});

// Get log statistics
app.get('/api/logs/stats', (req, res) => {
  try {
    const stats = {
      total: inMemoryLogs.length,
      byLevel: {},
      bySource: {},
      byService: {},
      errors: inMemoryLogs.filter(l => l.level === 'ERROR').length,
      warnings: inMemoryLogs.filter(l => l.level === 'WARN').length
    };
    
    // Count by level
    inMemoryLogs.forEach(log => {
      stats.byLevel[log.level] = (stats.byLevel[log.level] || 0) + 1;
      if (log.metadata?.source) {
        stats.bySource[log.metadata.source] = (stats.bySource[log.metadata.source] || 0) + 1;
      }
      if (log.metadata?.service) {
        stats.byService[log.metadata.service] = (stats.byService[log.metadata.service] || 0) + 1;
      }
    });
    
    res.json(stats);
  } catch (error) {
    logger.error('Error getting log stats:', error);
    res.status(500).json({ error: 'Failed to get stats' });
  }
});

// Clear logs (admin endpoint)
app.delete('/api/logs', (req, res) => {
  try {
    const count = inMemoryLogs.length;
    inMemoryLogs.length = 0;
    logger.warn(`Logs cleared: ${count} entries removed`);
    res.json({ success: true, message: `${count} logs cleared` });
  } catch (error) {
    logger.error('Error clearing logs:', error);
    res.status(500).json({ error: 'Failed to clear logs' });
  }
});

// ==================== CORE BANKING ENDPOINTS ====================
app.post('/api/customers', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.coreBanking}/customers`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.get('/api/customers/:id', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.coreBanking}/customers/${req.params.id}`);
  res.status(result.success ? 200 : 404).json(result.data || result);
});

app.get('/api/customers', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.coreBanking}/customers`, 'GET', null, req.query);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.put('/api/customers/:id', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.coreBanking}/customers/${req.params.id}`, 'PUT', req.body);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

// ==================== ACCOUNT MANAGEMENT ENDPOINTS ====================
app.post('/api/accounts', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.accountManagement}/accounts`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.get('/api/accounts/:id', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.accountManagement}/accounts/${req.params.id}`);
  res.status(result.success ? 200 : 404).json(result.data || result);
});

app.get('/api/accounts/customer/:customerId', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.accountManagement}/accounts/customer/${req.params.customerId}`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.post('/api/accounts/:id/deposit', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.accountManagement}/accounts/${req.params.id}/deposit`, 'POST', req.body);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.post('/api/accounts/:id/withdraw', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.accountManagement}/accounts/${req.params.id}/withdraw`, 'POST', req.body);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

// ==================== TRANSACTION PROCESSING ENDPOINTS ====================
app.post('/api/transactions/transfer', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.transactionProcessing}/transactions/transfer`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.get('/api/transactions/:id', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.transactionProcessing}/transactions/${req.params.id}`);
  res.status(result.success ? 200 : 404).json(result.data || result);
});

app.get('/api/transactions/account/:accountId', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.transactionProcessing}/transactions/account/${req.params.accountId}`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

// ==================== LOAN ORIGINATION ENDPOINTS ====================
app.post('/api/loans/applications', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.loanOrigination}/loan-applications`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.get('/api/loans/applications/:id', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.loanOrigination}/loan-applications/${req.params.id}`);
  res.status(result.success ? 200 : 404).json(result.data || result);
});

app.post('/api/loans/applications/:id/approve', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.loanOrigination}/loan-applications/${req.params.id}/approve`, 'POST', req.body);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

// ==================== LOAN SERVICING ENDPOINTS ====================
app.post('/api/loans', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.loanServicing}/loans`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.get('/api/loans/:id', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.loanServicing}/loans/${req.params.id}`);
  res.status(result.success ? 200 : 404).json(result.data || result);
});

app.post('/api/loans/:id/payments', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.loanServicing}/loans/${req.params.id}/payments`, 'POST', req.body);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/loans/:id/payments', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.loanServicing}/loans/${req.params.id}/payments`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

// ==================== CARD MANAGEMENT ENDPOINTS ====================
app.post('/api/cards', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.cardManagement}/cards`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.get('/api/cards/:id', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.cardManagement}/cards/${req.params.id}`);
  res.status(result.success ? 200 : 404).json(result.data || result);
});

app.post('/api/cards/:id/block', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.cardManagement}/cards/${req.params.id}/block`, 'POST');
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.post('/api/cards/:id/unblock', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.cardManagement}/cards/${req.params.id}/unblock`, 'POST');
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.post('/api/cards/:id/transactions', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.cardManagement}/cards/${req.params.id}/transactions`, 'POST', req.body);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/cards/:id/transactions', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.cardManagement}/cards/${req.params.id}/transactions`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

// ==================== BILL PAYMENT ENDPOINTS ====================
app.post('/api/bills/pay', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.billPayment}/bills/pay`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.post('/api/bills/schedule', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.billPayment}/bills/schedule`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.get('/api/bills/history/:customerId', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.billPayment}/bills/history/${req.params.customerId}`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/bills/recurring/:customerId', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.billPayment}/bills/recurring/${req.params.customerId}`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/billers', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.billPayment}/billers`, 'GET', null, req.query);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

// ==================== CUSTOMER SERVICE ENDPOINTS ====================
app.post('/api/tickets', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.customerService}/tickets`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.get('/api/tickets/:id', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.customerService}/tickets/${req.params.id}`);
  res.status(result.success ? 200 : 404).json(result.data || result);
});

app.get('/api/tickets/customer/:customerId', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.customerService}/tickets/customer/${req.params.customerId}`, 'GET', null, req.query);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.put('/api/tickets/:id', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.customerService}/tickets/${req.params.id}`, 'PUT', req.body);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.post('/api/tickets/:id/comments', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.customerService}/tickets/${req.params.id}/comments`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.get('/api/tickets/:id/comments', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.customerService}/tickets/${req.params.id}/comments`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

// ==================== REPORTING & ANALYTICS ENDPOINTS ====================
app.get('/api/reports/dashboard', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.reporting}/reports/dashboard`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/reports/accounts/summary', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.reporting}/reports/accounts/summary`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/reports/transactions/summary', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.reporting}/reports/transactions/summary`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/reports/loans/summary', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.reporting}/reports/loans/summary`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/reports/customers/growth', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.reporting}/reports/customers/growth`, 'GET', null, req.query);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/reports/transactions/trends', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.reporting}/reports/transactions/trends`, 'GET', null, req.query);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/reports/revenue', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.reporting}/reports/revenue`, 'GET', null, req.query);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/reports/customers/top', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.reporting}/reports/customers/top`, 'GET', null, req.query);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

// ==================== COMPLIANCE & AML ENDPOINTS ====================
app.post('/api/compliance/sar', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.compliance}/compliance/sar`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.get('/api/compliance/sar', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.compliance}/compliance/sar`, 'GET', null, req.query);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.put('/api/compliance/sar/:id', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.compliance}/compliance/sar/${req.params.id}`, 'PUT', req.body);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.post('/api/compliance/checks', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.compliance}/compliance/checks`, 'POST', req.body);
  res.status(result.success ? 201 : 500).json(result.data || result);
});

app.get('/api/compliance/checks/:customerId', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.compliance}/compliance/checks/${req.params.customerId}`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/compliance/monitor', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.compliance}/compliance/monitor`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/compliance/alerts', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.compliance}/compliance/alerts`, 'GET', null, req.query);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

app.get('/api/compliance/risk-score/:customerId', async (req, res) => {
  const result = await proxyRequest(`${SERVICES.compliance}/compliance/risk-score/${req.params.customerId}`);
  res.status(result.success ? 200 : 500).json(result.data || result);
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  logger.info(`🚀 BankCore Backend API Gateway running on port ${PORT}`);
  logger.info('Service endpoints configured:');
  Object.entries(SERVICES).forEach(([name, url]) => {
    logger.info(`  - ${name}: ${url}`);
  });
});

module.exports = app;

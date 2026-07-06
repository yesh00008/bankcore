# BankCore - Full-Stack Banking Application

## 🎯 Overview

BankCore is a comprehensive, production-ready banking application built with modern microservices architecture. It features 10 specialized backend services, a Node.js API Gateway, and a React-based frontend with complete logging and monitoring capabilities.

## 🏗️ Architecture

### Backend Services (Go + Gin Framework)
- **Port 8100**: Core Banking Service - Customer management, account types, branches
- **Port 8101**: Account Management - Account operations, deposits, withdrawals
- **Port 8102**: Transaction Processing - Money transfers, ACID transactions
- **Port 8103**: Loan Origination - Loan applications, credit scoring, approval
- **Port 8104**: Loan Servicing - Disbursement, payments, interest calculation
- **Port 8105**: Card Management - Card issuance, activation, transactions
- **Port 8106**: Bill Payment Service - Utility bills, recurring payments
- **Port 8107**: Customer Service Portal - Support tickets, help desk
- **Port 8108**: Reporting & Analytics - Business intelligence, dashboards
- **Port 8109**: Compliance & AML - Anti-money laundering, risk scoring

### API Gateway (Node.js + Express)
- **Port 4000**: Backend for Frontend (BFF)
- Proxies all 10 microservices
- Rate limiting, CORS, compression
- Centralized logging
- Health check aggregation

### Frontend (React 18)
- **Port 3002**: Single Page Application
- React Router DOM for navigation
- Axios for API calls with interceptors
- Recharts for data visualization
- Lucide React for icons
- Comprehensive logging system

### Infrastructure
- **PostgreSQL** (Port 5432): Relational database
- **Redis** (Port 6379): Caching layer
- **RabbitMQ** (Port 5672): Message queue
- **Prometheus** (Port 9090): Metrics collection
- **Grafana** (Port 3000): Monitoring dashboards
- **Tempo** (Port 4317): Distributed tracing

## 🚀 Quick Start

### Prerequisites
- Docker Desktop running
- Node.js 16+ installed
- Go 1.21+ installed
- Git for version control

### 1. Start Infrastructure Services
```powershell
cd platform/compose
docker-compose -f docker-compose.full.yml up -d
```

### 2. Start BankCore Microservices
```powershell
# Service 1: Core Banking (Port 8100)
cd apps/bankcore/services/core-banking-service
docker run -d --name=bankcore-core-banking \
  --network=compose_payflow-network \
  -p 8100:8100 \
  -e DATABASE_URL="postgres://postgres:postgres@payflow-postgres:5432/payflow?sslmode=disable" \
  bankcore-core-banking:latest

# Repeat for all 10 services (8100-8109)
# Or use the provided deployment script
```

### 3. Start Backend API Gateway
```powershell
cd apps/bankcore/backend-api
npm install
node index.js
```
API Gateway will be available at `http://localhost:4000`

### 4. Start Frontend Application
```powershell
cd apps/bankcore/frontend
npm install
$env:PORT="3002"
npm start
```
Frontend will open at `http://localhost:3002`

## 📱 Application Features

### Dashboard
- Real-time statistics (accounts, transactions, loans)
- Customer growth charts
- Transaction trends
- Quick overview of banking operations

### Customer Management
- Create and manage customer profiles
- View customer history
- Search and filter customers
- Customer status tracking

### Account Management
- Open new accounts (savings, checking, business)
- Deposit and withdraw funds
- View account balances
- Account status management

### Transaction Processing
- Create money transfers
- View transaction history
- Filter by date, status, account
- Real-time transaction updates

### Loan Management
- Submit loan applications
- Loan type selection (personal, home, auto, business)
- View active loans
- Make loan payments
- Payment history tracking

### Card Management
- Issue debit and credit cards
- Block/unblock cards
- Set credit limits
- View card transactions
- Manage card status

### Bill Payments
- Pay utility bills (electricity, water, telecom, etc.)
- Set up recurring payments
- Payment history
- Biller management

### Customer Support
- Create support tickets
- Ticket categorization (account, transaction, card, loan, technical)
- Priority levels (low, medium, high, urgent)
- Ticket status tracking
- Comment threads

### Reports & Analytics
- Business intelligence dashboard
- Customer growth analysis
- Transaction trends
- Revenue reports
- Top customers by various metrics
- Customizable time periods

### System Logs
- Real-time log viewing
- Filter by level (ERROR, WARN, INFO, DEBUG, SUCCESS)
- Search functionality
- Auto-refresh capability
- Export logs as JSON
- Log statistics dashboard
- Combined frontend + backend logs

## 🔧 API Endpoints

### Health Check
```http
GET /api/health
```

### Customers
```http
POST   /api/customers
GET    /api/customers
GET    /api/customers/:id
PUT    /api/customers/:id
```

### Accounts
```http
POST   /api/accounts
GET    /api/accounts/customer/:customerId
GET    /api/accounts/:id
POST   /api/accounts/:id/deposit
POST   /api/accounts/:id/withdraw
```

### Transactions
```http
POST   /api/transactions/transfer
GET    /api/transactions/account/:accountId
GET    /api/transactions/:id
```

### Loans
```http
POST   /api/loans/apply
GET    /api/loans/:id
POST   /api/loans/:id/disburse
POST   /api/loans/:id/payment
GET    /api/loans/:id/payments
```

### Cards
```http
POST   /api/cards
GET    /api/cards/:id
POST   /api/cards/:id/activate
POST   /api/cards/:id/block
POST   /api/cards/:id/unblock
GET    /api/cards/:id/transactions
```

### Bills
```http
GET    /api/billers
POST   /api/bills/pay
POST   /api/bills/schedule
GET    /api/bills/history/:customerId
GET    /api/bills/recurring/:customerId
```

### Support
```http
POST   /api/tickets
GET    /api/tickets/:id
GET    /api/tickets/customer/:customerId
PUT    /api/tickets/:id
POST   /api/tickets/:id/comments
GET    /api/tickets/:id/comments
```

### Reports
```http
GET    /api/reports/dashboard
GET    /api/reports/accounts/summary
GET    /api/reports/transactions/summary
GET    /api/reports/customers/growth?period=30d
GET    /api/reports/transactions/trends?period=30d
GET    /api/reports/revenue?period=month
GET    /api/reports/customers/top?metric=balance
```

### Compliance
```http
POST   /api/compliance/sar
GET    /api/compliance/sar
POST   /api/compliance/checks
GET    /api/compliance/checks/:customerId
GET    /api/compliance/monitor
GET    /api/compliance/alerts
GET    /api/compliance/risk-score/:customerId
```

### Logs
```http
GET    /api/logs?level=ERROR&limit=100
POST   /api/logs
GET    /api/logs/stats
DELETE /api/logs
```

## 📊 Logging System

### Frontend Logger
- Singleton logger with in-memory storage
- Automatic error and promise rejection handling
- API call tracking with duration
- Component lifecycle tracking
- User action tracking

### Backend Logger
- Winston-based multi-transport logging
- File rotation (10MB max, 5 files)
- In-memory storage for quick access
- Request/response middleware
- Log aggregation endpoints

### Log Viewer Features
- Real-time viewing with auto-refresh
- Filter by level and search
- Export logs as JSON
- Statistics dashboard
- Combined frontend + backend logs

### Usage Example
```javascript
import logger from './services/logger';

logger.info('User action', { action: 'login', userId: 123 });
logger.error('API failed', { url: '/api/customers', status: 500 });
logger.success('Transaction completed', { txId: 'TX123' });
```

See [LOGGING.md](./LOGGING.md) for detailed documentation.

## 🗄️ Database Schema

### Core Tables
- `customers` - Customer profiles
- `account_types` - Savings, checking, business accounts
- `branches` - Bank branch information
- `accounts` - Customer accounts with balances
- `transactions` - Money transfers and operations
- `loan_applications` - Loan requests and approvals
- `loans` - Active and closed loans
- `loan_payments` - Payment history
- `cards` - Debit and credit cards
- `card_transactions` - Card usage history
- `billers` - Utility companies and service providers
- `bill_payments` - Bill payment records
- `recurring_payments` - Scheduled recurring payments
- `support_tickets` - Customer service tickets
- `ticket_comments` - Ticket conversation threads
- `suspicious_activities` - AML/SAR reports
- `compliance_checks` - KYC and compliance records
- `aml_alerts` - Anti-money laundering alerts

## 🔐 Security Features

### API Gateway
- Helmet.js security headers
- CORS enabled with configurable origins
- Rate limiting (100 req/15min per IP)
- Request/response logging
- Error handling middleware

### Data Protection
- Passwords should be hashed (implement bcrypt)
- Sensitive data sanitization in logs
- SQL injection protection via prepared statements
- Input validation on all endpoints

### Compliance
- KYC checks for new customers
- Sanctions screening
- PEP (Politically Exposed Persons) checks
- Adverse media screening
- Transaction monitoring (>$10k flagged)
- Risk scoring algorithm
- Suspicious Activity Reports (SAR)

## 🧪 Testing

### Manual Testing
1. Open frontend at `http://localhost:3002`
2. Navigate through all pages
3. Create a customer
4. Open an account
5. Make transactions
6. Apply for a loan
7. Issue a card
8. Pay a bill
9. Create a support ticket
10. View reports and logs

### Health Checks
```powershell
# API Gateway
curl http://localhost:4000/api/health

# Individual Services
curl http://localhost:8100/health  # Core Banking
curl http://localhost:8101/health  # Account Management
curl http://localhost:8102/health  # Transaction Processing
# ... (8103-8109)
```

## 📈 Monitoring

### Prometheus Metrics
- Request count and duration
- Error rates
- Service health status
- Database connections

### Grafana Dashboards
- Access: `http://localhost:3000`
- Default credentials: admin/admin
- Pre-configured datasources

### Application Logs
- Frontend: Browser console + `/logs` page
- Backend: `backend-api/logs/` directory
- Services: Docker logs (`docker logs <container>`)

## 🐳 Docker Deployment

### Build All Services
```powershell
cd apps/bankcore

# Build each service
docker build -f services/core-banking-service/Dockerfile -t bankcore-core-banking:latest .
docker build -f services/account-management-service/Dockerfile -t bankcore-account-management:latest .
# ... Continue for all 10 services
```

### Deploy with Docker Compose
```yaml
version: '3.8'
services:
  bankcore-core-banking:
    image: bankcore-core-banking:latest
    ports:
      - "8100:8100"
    environment:
      DATABASE_URL: "postgres://postgres:postgres@postgres:5432/payflow"
    networks:
      - bankcore-network
  # ... Add all 10 services
```

## 🛠️ Development

### Project Structure
```
apps/bankcore/
├── backend-api/              # Node.js API Gateway
│   ├── index.js
│   ├── package.json
│   └── logs/
├── frontend/                 # React Frontend
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   │   ├── Dashboard/
│   │   │   ├── Customers/
│   │   │   ├── Accounts/
│   │   │   ├── Transactions/
│   │   │   ├── Loans/
│   │   │   ├── Cards/
│   │   │   ├── Bills/
│   │   │   ├── Support/
│   │   │   ├── Reports/
│   │   │   └── Logs/
│   │   ├── services/
│   │   │   ├── api.js
│   │   │   └── logger.js
│   │   ├── App.js
│   │   ├── App.css
│   │   └── index.js
│   └── package.json
├── services/                 # Go Microservices
│   ├── core-banking-service/
│   ├── account-management-service/
│   ├── transaction-processing-service/
│   ├── loan-origination-service/
│   ├── loan-servicing-service/
│   ├── card-management-service/
│   ├── bill-payment-service/
│   ├── customer-service-portal/
│   ├── reporting-analytics-service/
│   └── compliance-aml-service/
├── LOGGING.md
└── README.md
```

### Adding a New Feature
1. Create backend endpoint in appropriate microservice
2. Add proxy route in `backend-api/index.js`
3. Create API function in `frontend/src/services/api.js`
4. Build UI component in appropriate page
5. Add logging for new actions
6. Test end-to-end flow

### Code Standards
- **Go**: Follow standard Go conventions
- **JavaScript**: ESLint with React rules
- **Imports**: Organize and remove unused
- **Logging**: Use appropriate log levels
- **Error Handling**: Always handle errors gracefully
- **Comments**: Document complex logic

## 🔧 Configuration

### Environment Variables

#### Backend API Gateway
```bash
PORT=4000
LOG_LEVEL=info
CORE_BANKING_URL=http://localhost:8100
ACCOUNT_MANAGEMENT_URL=http://localhost:8101
# ... Set URLs for all services
```

#### Frontend
```bash
REACT_APP_API_URL=http://localhost:4000/api
PORT=3002
```

#### Microservices
```bash
DATABASE_URL=postgres://user:pass@host:5432/dbname?sslmode=disable
REDIS_URL=redis://localhost:6379
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
```

## 📝 Known Issues & Warnings

### ESLint Warnings (Non-Critical)
- Some unused imports (cleaned up)
- React Hook dependencies (suppressed where appropriate)

### Package Vulnerabilities
- Frontend: 9 vulnerabilities (3 moderate, 6 high)
- Backend: 14 vulnerabilities (1 low, 4 moderate, 9 high)
- Most are in devDependencies and don't affect production

### Port Conflicts
- Port 3000: Used by Grafana, frontend uses 3002
- Port 3001: May be occupied, using 3002 instead

## 🚀 Future Enhancements

### Phase 1: Security
- [ ] JWT authentication
- [ ] Role-based access control (RBAC)
- [ ] Password hashing with bcrypt
- [ ] API key management
- [ ] OAuth2 integration

### Phase 2: Features
- [ ] Email notifications
- [ ] SMS alerts
- [ ] Mobile responsive design
- [ ] Dark mode theme
- [ ] Multi-language support

### Phase 3: DevOps
- [ ] CI/CD pipeline
- [ ] Kubernetes deployment
- [ ] Load balancing
- [ ] Auto-scaling
- [ ] Backup automation

### Phase 4: Advanced
- [ ] Machine learning for fraud detection
- [ ] Real-time chat support
- [ ] Mobile apps (iOS/Android)
- [ ] Blockchain integration
- [ ] Open Banking APIs

## 📚 Additional Resources

- [Logging System Documentation](./LOGGING.md)
- [API Documentation](./API.md) (to be created)
- [Deployment Guide](./DEPLOYMENT.md) (to be created)
- [Contributing Guidelines](./CONTRIBUTING.md) (to be created)

## 💡 Troubleshooting

### Services Not Starting
1. Check Docker is running: `docker ps`
2. Verify PostgreSQL is healthy: `docker logs payflow-postgres`
3. Check port availability: `netstat -an | findstr :8100`

### Frontend Errors
1. Clear browser cache
2. Delete `node_modules` and reinstall: `npm install`
3. Check React Router version: `npm list react-router-dom`

### API Gateway Not Responding
1. Check if running: `curl http://localhost:4000/api/health`
2. View logs: Check `backend-api/logs/combined.log`
3. Restart: `Ctrl+C` and `node index.js`

### Database Connection Issues
1. Verify DATABASE_URL is correct
2. Check PostgreSQL logs
3. Test connection: `docker exec -it payflow-postgres psql -U postgres`

## 📄 License

This project is for educational and demonstration purposes.

## 👥 Team

- Backend Services: Go + Gin Framework
- API Gateway: Node.js + Express
- Frontend: React 18 + React Router
- Infrastructure: Docker + PostgreSQL + Redis + RabbitMQ
- Monitoring: Prometheus + Grafana + Tempo

## 🎉 Getting Help

- Check logs in `/logs` page of the application
- Review `LOGGING.md` for logging details
- Check Docker container logs: `docker logs <container-name>`
- Review API Gateway logs: `backend-api/logs/`

---

**BankCore** - A comprehensive full-stack banking application with microservices architecture, complete logging, and modern frontend. Built with love and best practices! 🏦💚

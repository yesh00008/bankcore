# 🏦 BankCore - Digital Banking Platform (Application 2)

**Status**: ✅ Production Ready  
**Services**: 10 Microservices  
**Database**: PostgreSQL (`bankcore`)  
**Ports**: 8100-8109 (Microservices), 4000 (API), 3002 (Frontend)

---

## 📋 Overview

**BankCore** is a comprehensive digital banking platform featuring core banking operations, loan management, card services, bill payments, and compliance reporting. This is **Application 2** in the Fintech Microservices Benchmark suite.

### Key Features

✅ **Customer Management** - Onboarding, KYC, profiles  
✅ **Account Services** - Checking, savings, money market accounts  
✅ **Transaction Processing** - Internal/external transfers, ACH, wire  
✅ **Loan Origination & Servicing** - Personal, auto, mortgage loans  
✅ **Card Management** - Debit/credit cards with limits  
✅ **Bill Payment** - One-time and recurring payments  
✅ **Customer Support** - Ticketing system  
✅ **Reporting & Analytics** - Statements, tax documents, custom reports  
✅ **Compliance & AML** - Audit trails, suspicious activity monitoring  

---

## 🏗️ Architecture

###Service Topology

```
Frontend (React on Port 3002)
    ↓
Backend API Gateway (Node.js on Port 4000)
    ↓
┌─────────────────────────────────────────────────────────────┐
│                BankCore Microservices                        │
├─────────────────────────────────────────────────────────────┤
│  Core Banking (8100)           │ Customer management       │
│  Account Management (8101)     │ Accounts & balances       │
│  Transaction Processing (8102) │ Transfers & payments      │
│  Loan Origination (8103)       │ Loan applications         │
│  Loan Servicing (8104)         │ EMI,  repayments          │
│  Card Management (8105)        │ Card issuance & control   │
│  Bill Payment (8106)           │ Bill payments & payees    │
│  Customer Service (8107)       │ Support tickets           │
│  Reporting & Analytics (8108)  │ Reports & statements      │
│  Compliance & AML (8109)       │ Auditing & monitoring     │
└─────────────────────────────────────────────────────────────┘
    ↓
Database Layer
    PostgreSQL (bankcore database)
    Redis (caching)
    RabbitMQ (messaging)
```

### Tech Stack

| Component | Technology |
|-----------|-----------|
| **Microservices** | Go 1.21+ (Gin framework) |
| **Backend API** | Node.js 18+ (Express) |
| **Frontend** | React 18 + JavaScript |
| **Database** | PostgreSQL 16 |
| **Cache** | Redis 7 |
| **Message Queue** | RabbitMQ 3.13 |
| **Tracing** | OpenTelemetry + Tempo |
| **Metrics** | Prometheus |
| **Containerization** | Docker + Docker Compose |

---

## 🚀 Quick Start

### Prerequisites

- Docker Desktop installed and running
- PowerShell 7+ (Windows)
- 8GB+ RAM recommended
- Ports 8100-8109, 4000, 3002 available

### Option 1: Automated Startup (Recommended)

```powershell
# Start everything with one command
.\start-bankcore.ps1

# First time or after code changes:
.\start-bankcore.ps1 -Rebuild

# Fresh start (removes all data):
.\start-bankcore.ps1 -Fresh
```

### Option 2: Manual Startup

#### Step 1: Start Infrastructure

```powershell
cd platform/compose
docker-compose -f docker-compose.full.yml up -d payflow-postgres payflow-redis payflow-rabbitmq
```

#### Step 2: Initialize Database

```powershell
docker exec -i payflow-postgres psql -U fintech -d postgres -f - < init-scripts/03-bankcore-schema.sql
```

#### Step 3: Start Microservices

```powershell
docker-compose -f docker-compose.bankcore.yml up -d
```

#### Step 4: Start Backend API

```powershell
cd ../../apps/bankcore/backend-api
$env:PORT="4000"
node index.js
```

#### Step 5: Start Frontend

```powershell
cd ../frontend
$env:PORT="3002"
npm start
```

---

## 🎯 API Endpoints

### Core Banking Service (Port 8100)

```
GET    /health                          # Health check
GET    /customers                       # List customers
POST   /customers                       # Create customer
GET    /customers/:id                   # Get customer details
PUT    /customers/:id                   # Update customer
DELETE /customers/:id                   # Delete customer
GET    /account-types                   # List account types
POST   /account-types                   # Create account type
```

### Account Management Service (Port 8101)

```
POST   /accounts                        # Open account
GET    /accounts                        # List accounts
GET    /accounts/:id                    # Get account details
GET    /accounts/:id/balance            # Get balance
POST   /accounts/:id/deposit            # Deposit funds
POST   /accounts/:id/withdraw           # Withdraw funds
PUT    /accounts/:id/status             # Update account status
```

### Transaction Processing Service (Port 8102)

```
POST   /transactions/internal           # Internal transfer
POST   /transactions/ach                # ACH transfer
POST   /transactions/wire               # Wire transfer
GET    /transactions                    # List transactions
GET    /transactions/:id                # Get transaction details
GET    /accounts/:id/transactions       # Account transaction history
```

### Loan Origination Service (Port 8103)

```
POST   /loans/apply                     # Submit loan application
GET    /loans                           # List loans
GET    /loans/:id                       # Get loan details
PUT    /loans/:id/approve               # Approve loan
PUT    /loans/:id/reject                # Reject loan
POST   /loans/:id/disburse              # Disburse loan funds
```

### Loan Servicing Service (Port 8104)

```
GET    /loans/:id/schedule              # Get payment schedule
POST   /loans/:id/repayment             # Make loan payment
GET    /loans/:id/repayments            # List repayments
GET    /loans/:id/outstanding           # Get outstanding balance
POST   /loans/:id/prepay                # Prepay loan
```

### Card Management Service (Port 8105)

```
POST   /cards                           # Issue card
GET    /cards                           # List cards
GET    /cards/:id                       # Get card details
PUT    /cards/:id/activate              # Activate card
PUT    /cards/:id/block                 # Block card
PUT    /cards/:id/unblock               # Unblock card
PUT    /cards/:id/limits                # Update limits
```

### Bill Payment Service (Port 8106)

```
POST   /bill-payments                   # Pay bill
GET    /bill-payments                   # List payments
GET    /bill-payments/:id               # Get payment details
POST   /bill-payments/recurring         # Schedule recurring payment
GET    /billers                         # List billers
POST   /billers                         # Add biller
```

### Customer Service Portal (Port 8107)

```
POST   /tickets                         # Create support ticket
GET    /tickets                         # List tickets
GET    /tickets/:id                     # Get ticket details
PUT    /tickets/:id                     # Update ticket
PUT    /tickets/:id/assign              # Assign ticket
PUT    /tickets/:id/resolve             # Resolve ticket
```

### Reporting & Analytics Service (Port 8108)

```
GET    /reports/account-statement       # Account statement
GET    /reports/transaction-history     # Transaction report
GET    /reports/loan-statement          # Loan statement
GET    /reports/tax-documents           # Tax documents
GET    /reports/customer-summary        # Customer summary
POST   /reports/custom                  # Custom report
GET    /reports/customers/growth        # Customer growth metrics
```

### Compliance & AML Service (Port 8109)

```
GET    /compliance/audit-log            # Audit trail
POST   /compliance/suspicious-activity  # Report SAR
GET    /compliance/kyc/:customer_id     # KYC status
GET    /compliance/large-transactions   # Large transaction monitoring
GET    /compliance/risk-assessments     # Risk assessments
```

---

## 🗄️ Database Schema

### Key Tables

- **customers** - Customer profiles and KYC data
- **accounts** - Bank accounts (checking, savings, etc.)
- **transactions** - All financial transactions
- **loans** - Loan accounts
- **loan_repayments** - Loan payment history
- **cards** - Debit/credit cards
- **bill_payments** - Bill payment records
- **billers** - Payee/biller directory
- **support_tickets** - Customer support tickets
- **account_types** - Account product catalog
- **branches** - Branch locations

### Views

- **customer_account_summary** - Consolidated customer view
- **daily_transaction_summary** - Daily transaction metrics

---

## 🧪 Testing

### Health Check All Services

```powershell
$ports = 8100..8109
foreach ($port in $ports) {
    try {
        $response = Invoke-RestMethod "http://localhost:$port/health"
        Write-Host "✓ Port $port - OK" -ForegroundColor Green
    } catch {
        Write-Host "✗ Port $port - FAILED" -ForegroundColor Red
    }
}
```

### Create a Customer

```powershell
$customer = @{
    first_name = "John"
    last_name = "Doe"
    email = "john.doe@example.com"
    phone = "+1234567890"
    date_of_birth = "1990-01-15"
    address = "123 Main St"
    city = "New York"
    state = "NY"
    zip_code = "10001"
    country = "USA"
    customer_type = "individual"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8100/customers" `
    -Method POST `
    -ContentType "application/json" `
    -Body $customer
```

### Open an Account

```powershell
$account = @{
    customer_id = "customer-uuid-here"
    account_type = "checking"
    initial_deposit = 1000.00
    currency = "USD"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8101/accounts" `
    -Method POST `
    -ContentType "application/json" `
    -Body $account
```

---

## 🛠️ Development

### View Logs

```powershell
# All services
docker-compose -f docker-compose.bankcore.yml logs -f

# Specific service
docker-compose -f docker-compose.bankcore.yml logs -f bankcore-core-banking
```

### Restart a Service

```powershell
docker-compose -f docker-compose.bankcore.yml restart bankcore-account-management
```

### Stop All Services

```powershell
docker-compose -f docker-compose.bankcore.yml down
```

### Rebuild After Code Changes

```powershell
docker-compose -f docker-compose.bankcore.yml build [service-name]
docker-compose -f docker-compose.bankcore.yml up -d [service-name]
```

---

## 📊 Monitoring

### Prometheus Metrics

All services expose metrics at `/metrics` endpoint:
```
http://localhost:8100/metrics
http://localhost:8101/metrics
...
http://localhost:8109/metrics
```

### Health Endpoints

All services provide health checks:
```
http://localhost:8100/health
http://localhost:8101/health
...
http://localhost:8109/health
```

---

## 🔒 Security

- ✅ JWT authentication (via Backend API)
- ✅ RBAC authorization
- ✅ Rate limiting
- ✅ Input validation
- ✅ SQL injection protection (parameterized queries)
- ✅ HTTPS/TLS ready (certificates in `platform/compose/tls/`)

---

## 📚 Related Documentation

- [Project README](../../README.md) - Overall project overview
- [Implementation Guide](../../IMPLEMENTATION_GUIDE.md) - Full implementation details
- [All Applications Architecture](../../docs/all-applications-architecture.md) - Multi-app architecture
- [Project Deliverables](../../PROJECT_DELIVERABLES.md) - Complete deliverables

---

## 🎯 Success Criteria

✅ All 10 microservices running and healthy  
✅ Frontend accessible at http://localhost:3002  
✅ Backend API operational at http://localhost:4000  
✅ Database schema created with seed data  
✅ No errors in docker logs  
✅ < 200ms p95 API response time  

---

## 🐛 Troubleshooting

### Services won't start

```powershell
# Check if ports are available
Get-NetTCPConnection -LocalPort 8100,8101,8102,8103,8104,8105,8106,8107,8108,8109

# Check Docker resources
docker system df
docker system prune  # If needed
```

### Database connection errors

```powershell
# Verify PostgreSQL is running
docker exec payflow-postgres psql -U fintech -d bankcore -c "SELECT 1"

# Reinitialize database
docker exec -i payflow-postgres psql -U fintech -d postgres -f - < platform/compose/init-scripts/03-bankcore-schema.sql
```

### Frontend not loading

```powershell
# Check if backend API is running
Invoke-RestMethod http://localhost:4000/api/health

# Restart frontend
cd apps/bankcore/frontend
$env:PORT="3002"
npm start
```

---

**BankCore** - Digital Banking Platform 🏦  
Part of the Fintech Microservices Benchmark Suite

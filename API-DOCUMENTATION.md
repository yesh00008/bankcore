# BankCore API Documentation

**Version:** 2.0  
**Base URL:** `http://localhost:4000/api` (via API Gateway)  
**Direct Service Access:** `http://localhost:8100-8109`

## Table of Contents
- [Authentication](#authentication)
- [Service 1: Core Banking (8100)](#service-1-core-banking-8100)
- [Service 2: Account Management (8101)](#service-2-account-management-8101)
- [Service 3: Transaction Processing (8102)](#service-3-transaction-processing-8102)
- [Service 4: Loan Origination (8103)](#service-4-loan-origination-8103)
- [Service 5: Loan Servicing (8104)](#service-5-loan-servicing-8104)
- [Service 6: Card Management (8105)](#service-6-card-management-8105)
- [Service 7: Bill Payment (8106)](#service-7-bill-payment-8106)
- [Service 8: Customer Service (8107)](#service-8-customer-service-8107)
- [Service 9: Reporting & Analytics (8108)](#service-9-reporting--analytics-8108)
- [Service 10: Compliance & AML (8109)](#service-10-compliance--aml-8109)
- [Error Codes](#error-codes)
- [Rate Limiting](#rate-limiting)

---

## Authentication

All API endpoints require Bearer token authentication (except health checks).

```http
Authorization: Bearer <token>
```

### Get Auth Token
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600,
  "user": {
    "id": "123",
    "email": "user@example.com",
    "role": "customer"
  }
}
```

---

## Service 1: Core Banking (8100)

Manages customers, branches, and account types.

### Customers

#### Create Customer
```http
POST /api/v1/customers
Content-Type: application/json

{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone": "+1-555-0100",
  "date_of_birth": "1990-01-15",
  "address": "123 Main St",
  "city": "New York",
  "state": "NY",
  "zip_code": "10001",
  "country": "USA"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "customer_id": "CUST1708790400",
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone": "+1-555-0100",
  "kyc_status": "pending",
  "status": "active",
  "created_at": "2026-02-24T10:00:00Z"
}
```

#### List Customers
```http
GET /api/v1/customers
```

**Query Parameters:**
- `limit` (optional): Number of records (default: 100)
- `offset` (optional): Pagination offset
- `status` (optional): Filter by status (active, inactive, deleted)
- `kyc_status` (optional): Filter by KYC status (pending, approved, rejected)

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "customer_id": "CUST1708790400",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "+1-555-0100",
    "kyc_status": "approved",
    "status": "active",
    "created_at": "2026-02-24T10:00:00Z"
  }
]
```

#### Get Customer
```http
GET /api/v1/customers/:id
```

**Response (200 OK):**
```json
{
  "id": 1,
  "customer_id": "CUST1708790400",
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone": "+1-555-0100",
  "date_of_birth": "1990-01-15",
  "address": "123 Main St",
  "city": "New York",
  "state": "NY",
  "zip_code": "10001",
  "country": "USA",
  "kyc_status": "approved",
  "status": "active",
  "created_at": "2026-02-24T10:00:00Z",
  "updated_at": "2026-02-24T10:00:00Z"
}
```

#### Update Customer
```http
PUT /api/v1/customers/:id
Content-Type: application/json

{
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1-555-0199",
  "address": "456 Oak Ave",
  "city": "Brooklyn",
  "state": "NY",
  "zip_code": "11201"
}
```

**Response (200 OK):**
```json
{
  "message": "Customer updated successfully"
}
```

#### Delete Customer (Soft Delete)
```http
DELETE /api/v1/customers/:id
```

**Response (200 OK):**
```json
{
  "message": "Customer deleted successfully"
}
```

#### Update KYC Status
```http
POST /api/v1/customers/:id/kyc
Content-Type: application/json

{
  "status": "approved"
}
```

**Valid KYC Statuses:** `pending`, `approved`, `rejected`, `under_review`

**Response (200 OK):**
```json
{
  "message": "KYC status updated"
}
```

### Branches

#### Create Branch
```http
POST /api/v1/branches
Content-Type: application/json

{
  "branch_code": "BR003",
  "branch_name": "Brooklyn Heights Branch",
  "address": "100 Montague St",
  "city": "Brooklyn",
  "state": "NY",
  "zip_code": "11201",
  "phone": "+1-555-0300",
  "manager": "Sarah Johnson"
}
```

**Response (201 Created):**
```json
{
  "id": 3,
  "branch_code": "BR003",
  "branch_name": "Brooklyn Heights Branch",
  "address": "100 Montague St",
  "city": "Brooklyn",
  "state": "NY",
  "zip_code": "11201",
  "phone": "+1-555-0300",
  "manager": "Sarah Johnson",
  "is_active": true,
  "created_at": "2026-02-24T10:00:00Z"
}
```

#### List Branches
```http
GET /api/v1/branches
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "branch_code": "BR001",
    "branch_name": "Main Street Branch",
    "city": "New York",
    "phone": "+1-555-0100",
    "manager": "John Smith",
    "is_active": true
  }
]
```

#### Get Branch
```http
GET /api/v1/branches/:id
```

### Account Types

#### Create Account Type
```http
POST /api/v1/account-types
Content-Type: application/json

{
  "account_type_name": "Student Savings",
  "description": "Savings account for students with no fees",
  "min_balance": 25.00,
  "interest_rate": 0.0200,
  "monthly_fee": 0.00
}
```

**Response (201 Created):**
```json
{
  "id": 4,
  "account_type_name": "Student Savings",
  "description": "Savings account for students with no fees",
  "min_balance": 25.00,
  "interest_rate": 0.0200,
  "monthly_fee": 0.00,
  "is_active": true
}
```

#### List Account Types
```http
GET /api/v1/account-types
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "account_type_name": "Savings",
    "description": "Standard savings account",
    "min_balance": 500.00,
    "interest_rate": 0.0250,
    "monthly_fee": 0.00,
    "is_active": true
  },
  {
    "id": 2,
    "account_type_name": "Checking",
    "description": "Standard checking account",
    "min_balance": 100.00,
    "interest_rate": 0.0010,
    "monthly_fee": 5.00,
    "is_active": true
  }
]
```

#### Get Account Type
```http
GET /api/v1/account-types/:id
```

---

## Service 2: Account Management (8101)

Manages account operations, deposits, withdrawals, and balances.

### Health Check
```http
GET /health
```

**Response (200 OK):**
```json
{
  "status": "UP",
  "service": "account-management-service",
  "port": "8101",
  "database": "UP",
  "redis": "UP",
  "time": "2026-02-24T10:00:00Z"
}
```

### Service Info  
```http
GET /api/v1/ping
```

**Response (200 OK):**
```json
{
  "service": "account-management-service",
  "port": "8101",
  "description": "Account operations, deposits, withdrawals",
  "status": "online",
  "timestamp": "2026-02-24T10:00:00Z"
}
```

---

## Service 3: Transaction Processing (8102)

Handles money transfers and ACID transactions.

### Health Check
```http
GET /health
```

### Service Info
```http
GET /api/v1/ping
```

**Advanced Features:**
- ACID transaction guarantees
- Idempotency keys for duplicate prevention
- Two-phase commit for distributed transactions
- Transaction rollback support
- Real-time transaction notifications via RabbitMQ

---

## Service 4: Loan Origination (8103)

Manages loan applications and credit scoring.

### Health Check
```http
GET /health
```

### Service Info
```http
GET /api/v1/ping
```

**Key Features:**
- Automated credit scoring
- Document upload and verification
- Multi-step approval workflow
- Credit report integration
- Risk assessment engine

---

## Service 5: Loan Servicing (8104)

Handles loan disbursement and payment processing.

### Health Check
```http
GET /health
```

### Service Info
```http
GET /api/v1/ping
```

**Key Features:**
- Loan disbursement tracking
- Payment schedule generation
- Interest calculation (simple & compound)
- Late payment handling
- Prepayment and refinancing support

---

## Service 6: Card Management (8105)

Manages card issuance, activation, and transactions.

### Health Check
```http
GET /health
```

### Service Info
```http
GET /api/v1/ping
```

**Card Features:**
- Instant virtual card issuance
- Physical card ordering
- Card activation and PIN management
- Transaction limits and controls
- Fraud detection integration
- Contactless payment support

---

## Service 7: Bill Payment (8106)

Handles utility bills and recurring payments.

### Health Check
```http
GET /health
```

### Service Info
```http
GET /api/v1/ping
```

**Payment Features:**
- Multiple biller support (utilities, telecom, credit cards)
- Scheduled and recurring payments
- Payment history tracking
- Auto-pay setup
- Email/SMS notifications

---

## Service 8: Customer Service (8107)

Customer support portal and ticket management.

### Health Check
```http
GET /health
```

### Service Info
```http
GET /api/v1/ping
```

**Support Features:**
- Ticket creation and tracking
- Live chat integration
- FAQ and help center
- Call logging
- SLA tracking
- Agent assignment

---

## Service 9: Reporting & Analytics (8108)

Business intelligence and data analytics.

### Health Check
```http
GET /health
```

### Service Info
```http
GET /api/v1/ping
```

**Reporting Capabilities:**
- Transaction volume reports
- Customer growth analytics
- Loan portfolio analysis
- Revenue and fee reports
- Custom dashboard builder
- Data export (CSV, Excel, PDF)
- Scheduled report delivery

---

## Service 10: Compliance & AML (8109)

Anti-money laundering and regulatory compliance.

### Health Check
```http
GET /health
```

### Service Info
```http
GET /api/v1/ping
```

**Compliance Features:**
- AML transaction monitoring
- Suspicious activity reporting (SAR)
- Customer risk scoring
- Regulatory report generation
- Watchlist screening
- Transaction pattern analysis
- KYC documentation management

---

## Error Codes

| Code | Description |
|------|-------------|
| 200  | Success |
| 201  | Created |
| 400  | Bad Request |
| 401  | Unauthorized |
| 403  | Forbidden |
| 404  | Not Found |
| 409  | Conflict |
| 422  | Unprocessable Entity |
| 429  | Too Many Requests |
| 500  | Internal Server Error |
| 503  | Service Unavailable |

### Error Response Format
```json
{
  "error": "Invalid request",
  "message": "Email address is already registered",
  "code": "EMAIL_EXISTS",
  "timestamp": "2026-02-24T10:00:00Z"
}
```

---

## Rate Limiting

**Limits:**
- Anonymous: 100 requests/hour
- Authenticated: 1000 requests/hour
- Premium: 10,000 requests/hour

**Headers:**
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 995
X-RateLimit-Reset: 1708794000
```

**Rate Limit Exceeded Response (429):**
```json
{
  "error": "Rate limit exceeded",
  "message": "You have exceeded the rate limit. Please try again later.",
  "retry_after": 3600
}
```

---

## Monitoring & Metrics

All services expose Prometheus metrics at `/metrics`:

```http
GET /metrics
```

**Key Metrics:**
- `<service>_requests_total` - Total request count
- `<service>_request_duration_seconds` - Request latency histogram
- `database_connections_active` - Active database connections
- `cache_hit_ratio` - Redis cache hit rate

---

## Versioning

API follows semantic versioning (v1, v2, etc.). Version is specified in the URL:

```
/api/v1/customers
/api/v2/customers
```

Current stable version: **v1**

---

## Support

For API support, contact:
- **Email:** api-support@bankcore.example.com
- **Docs:** https://docs.bankcore.example.com
- **Status Page:** https://status.bankcore.example.com

---

*Generated: February 24, 2026*  
*BankCore API v2.0*

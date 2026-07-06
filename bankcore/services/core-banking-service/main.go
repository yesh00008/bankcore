package main


  
import (
 	"context" 	"database/sql" 	"encoding/json" 	"fmt" 	"log" 	"net/http" 	"os" 	"os/signal" 	"syscall" 	"time"  	"github.com/gin-gonic/gin" 	"github.com/go-redis/redis/v8" 	_ "github.com/lib/pq" 	"github.com/prometheus/client_golang/prometheus" 	"github.com/prometheus/client_golang/prometheus/promhttp" 	"github.com/streadway/amqp"
)
 
var (
 	db          *sql.DB 	redisClient *redis.Client 	rabbitConn  *amqp.Connection 	rabbitCh    *amqp.Channel 	ctx         = context.Background()  	// Prometheus metrics 	requestsTotal = prometheus.NewCounterVec( 		prometheus.CounterOpts{ 			Name: "core_banking_requests_total", 			Help: "Total number of requests", 		}, 		[]string{"method", "endpoint", "status"}, 	)  	requestDuration = prometheus.NewHistogramVec( 		prometheus.HistogramOpts{ 			Name:    "core_banking_request_duration_seconds", 			Help:    "Request duration in seconds", 			Buckets: prometheus.DefBuckets, 		}, 		[]string{"method", "endpoint"}, 	)
)
 
func init() {
	prometheus.MustRegister(requestsTotal) 	prometheus.MustRegister(requestDuration)
}
  type Customer struct {
	ID          int       `json:"id"` 	CustomerID  string    `json:"customer_id"` 	FirstName   string    `json:"first_name"` 	LastName    string    `json:"last_name"` 	Email       string    `json:"email"` 	Phone       string    `json:"phone"` 	DateOfBirth string    `json:"date_of_birth"` 	Address     string    `json:"address"` 	City        string    `json:"city"` 	State       string    `json:"state"` 	ZipCode     string    `json:"zip_code"` 	Country     string    `json:"country"` 	KYCStatus   string    `json:"kyc_status"` 	Status      string    `json:"status"` 	CreatedAt   time.Time `json:"created_at"` 	UpdatedAt   time.Time `json:"updated_at"`
}
  type Branch struct {
	ID         int       `json:"id"` 	BranchCode string    `json:"branch_code"` 	BranchName string    `json:"branch_name"` 	Address    string    `json:"address"` 	City       string    `json:"city"` 	State      string    `json:"state"` 	ZipCode    string    `json:"zip_code"` 	Phone      string    `json:"phone"` 	Manager    string    `json:"manager"` 	IsActive   bool      `json:"is_active"` 	CreatedAt  time.Time `json:"created_at"`
}
  type AccountType struct {
	ID              int     `json:"id"` 	AccountTypeName string  `json:"account_type_name"` 	Description     string  `json:"description"` 	MinBalance      float64 `json:"min_balance"` 	InterestRate    float64 `json:"interest_rate"` 	MonthlyFee      float64 `json:"monthly_fee"` 	IsActive        bool    `json:"is_active"`
}
  
func main() {
	// Database connection 	var err error 	dbURL := getEnv("DATABASE_URL", "postgres://fintech:fintech123@localhost:5432/bankcore?sslmode=disable") 	db, err = sql.Open("postgres", dbURL) 	if err != nil {
		log.Fatal("Failed to connect to database:", err) 	} 	defer db.Close()  	if err = db.Ping(); err != nil {
		log.Fatal("Failed to ping database:", err) 	} 	log.Println("✓ Database connected")  	// Redis connection 	redisClient = redis.NewClient(&redis.Options{ 		Addr:     getEnv("REDIS_URL", "localhost:6379"), 		Password: "", 		DB:       0, 	}) 	if err := redisClient.Ping(ctx).Err(); err != nil {
		log.Println("⚠ Redis not available:", err) 	} else {
		log.Println("✓ Redis connected") 	}  	// RabbitMQ connection 	rabbitURL := getEnv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/") 	rabbitConn, err = amqp.Dial(rabbitURL) 	if err != nil {
		log.Println("⚠ RabbitMQ not available:", err) 	} else {
		rabbitCh, err = rabbitConn.Channel() 		if err != nil {
			log.Println("⚠ RabbitMQ channel error:", err) 		} else {
			log.Println("✓ RabbitMQ connected") 			defer rabbitConn.Close() 			defer rabbitCh.Close()  			// Declare queue 			_, err = rabbitCh.QueueDeclare( 				"customer_events", 				true, 				false, 				false, 				false, 				nil, 			) 			if err != nil {
				log.Println("⚠ Failed to declare queue:", err) 			} 		} 	}  	// Initialize tables 	initializeTables()  	// Setup Gin router 	gin.SetMode(gin.ReleaseMode) 	router := gin.Default()  	// Middleware 	router.Use(prometheusMiddleware()) 	router.Use(loggingMiddleware())  	// Health check 	router.GET("/health", healthCheck) 	router.GET("/metrics", gin.WrapH(promhttp.Handler()))  	// Customer routes 	router.POST("/api/v1/customers", createCustomer) 	router.GET("/api/v1/customers", listCustomers) 	router.GET("/api/v1/customers/:id", getCustomer) 	router.PUT("/api/v1/customers/:id", updateCustomer) 	router.DELETE("/api/v1/customers/:id", deleteCustomer) 	router.POST("/api/v1/customers/:id/kyc", updateKYCStatus)  	// Branch routes 	router.POST("/api/v1/branches", createBranch) 	router.GET("/api/v1/branches", listBranches) 	router.GET("/api/v1/branches/:id", getBranch)  	// Account Type routes 	router.POST("/api/v1/account_types", createAccountType) 	router.GET("/api/v1/account_types", listAccountTypes) 	router.GET("/api/v1/account_types/:id", getAccountType)  	// Start server 	port := getEnv("PORT", "8100") 	srv := &http.Server{ 		Addr:    ":" + port, 		Handler: router, 	}  	go
func() {
		log.Printf("🚀 Core Banking Service running on port %s\n", port) 		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server error: %v", err) 		} 	}()  	// Graceful shutdown 	quit := make(chan os.Signal, 1) 	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM) 	<_quit 	log.Println("Shutting down server...")  	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second) 	defer cancel() 	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err) 	} 	log.Println("Server exited")
}
 
func initializeTables() {
	queries := []string{ 		`CREATE TABLE IF NOT EXISTS customers ( 			id SERIAL PRIMARY KEY, 			customer_id
varCHAR(50) UNIQUE NOT NULL, 			first_name
varCHAR(100) NOT NULL, 			last_name
varCHAR(100) NOT NULL, 			email
varCHAR(255) UNIQUE NOT NULL, 			phone
varCHAR(20), 			date_of_birth DATE, 			address TEXT, 			city
varCHAR(100), 			state
varCHAR(100), 			zip_code
varCHAR(20), 			country
varCHAR(100) DEFAULT 'USA', 			kyc_status
varCHAR(20) DEFAULT 'pending', 			status
varCHAR(20) DEFAULT 'active', 			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 		)`, 		`CREATE TABLE IF NOT EXISTS branches ( 			id SERIAL PRIMARY KEY, 			branch_code
varCHAR(20) UNIQUE NOT NULL, 			branch_name
varCHAR(200) NOT NULL, 			address TEXT, 			city
varCHAR(100), 			state
varCHAR(100), 			zip_code
varCHAR(20), 			phone
varCHAR(20), 			manager
varCHAR(100), 			is_active BOOLEAN DEFAULT true, 			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 		)`, 		`CREATE TABLE IF NOT EXISTS account_types ( 			id SERIAL PRIMARY KEY, 			account_type_name
varCHAR(100) UNIQUE NOT NULL, 			description TEXT, 			min_balance DECIMAL(15,2) DEFAULT 0, 			interest_rate DECIMAL(5,4) DEFAULT 0, 			monthly_fee DECIMAL(10,2) DEFAULT 0, 			is_active BOOLEAN DEFAULT true 		)`, 	}  	for _, query := range queries {
		if _, err := db.Exec(query); err != nil {
			log.Printf("Error creating table: %v", err) 		} 	} 	log.Println("✓ Tables initialized")  	// Insert default data 	seedData()
}
 
func seedData() {
	// Seed account types 	db.Exec(`INSERT INTO account_types (account_type_name, description, min_balance, interest_rate, monthly_fee)  		VALUES ('Savings', 'Standard savings account', 500.00, 0.0250, 0.00) ON CONFLICT DO NOTHING`) 	db.Exec(`INSERT INTO account_types (account_type_name, description, min_balance, interest_rate, monthly_fee)  		VALUES ('Checking', 'Standard checking account', 100.00, 0.0010, 5.00) ON CONFLICT DO NOTHING`) 	db.Exec(`INSERT INTO account_types (account_type_name, description, min_balance, interest_rate, monthly_fee)  		VALUES ('Premium', 'Premium account with benefits', 5000.00, 0.0400, 0.00) ON CONFLICT DO NOTHING`)  	// Seed branches 	db.Exec(`INSERT INTO branches (branch_code, branch_name, address, city, state, zip_code, phone, manager)  		VALUES ('BR001', 'Main Street Branch', '123 Main St', 'New York', 'NY', '10001', '555_0100', 'John Smith') ON CONFLICT DO NOTHING`) 	db.Exec(`INSERT INTO branches (branch_code, branch_name, address, city, state, zip_code, phone, manager)  		VALUES ('BR002', 'Downtown Branch', '456 Market St', 'San Francisco', 'CA', '94102', '555_0200', 'Jane Doe') ON CONFLICT DO NOTHING`)
}
 
func healthCheck(c *gin.Context) {
	health := gin.H{ 		"status":  "UP", 		"service": "core_banking_service", 		"time":    time.Now().Format(time.RFC3339), 	}  	// Check database 	if err := db.Ping(); err != nil {
		health["database"] = "DOWN" 		health["status"] = "DEGRADED" 	} else {
		health["database"] = "UP" 	}  	// Check Redis 	if err := redisClient.Ping(ctx).Err(); err != nil {
		health["redis"] = "DOWN" 	} else {
		health["redis"] = "UP" 	}  	c.JSON(http.StatusOK, health)
}
  // Customer handlers
func createCustomer(c *gin.Context) {
	var customer Customer 	if err := c.ShouldBindJSON(&customer); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()}) 		return 	}  	// Generate customer ID 	customer.CustomerID = fmt.Sprintf("CUST%d", time.Now().Unix())  	query := `INSERT INTO customers (customer_id, first_name, last_name, email, phone, date_of_birth,  		address, city, state, zip_code, country)  		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id, created_at`  	err := db.QueryRow(query, customer.CustomerID, customer.FirstName, customer.LastName, customer.Email, 		customer.Phone, customer.DateOfBirth, customer.Address, customer.City, customer.State, 		customer.ZipCode, customer.Country).Scan(&customer.ID, &customer.CreatedAt)  	if err != nil {
		log.Printf("Error creating customer: %v", err) 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create customer"}) 		return 	}  	// Publish event to RabbitMQ 	publishEvent("customer.created", customer)  	// Invalidate cache 	redisClient.Del(ctx, "customers:list")  	c.JSON(http.StatusCreated, customer)
}
 
func listCustomers(c *gin.Context) {
	// Try cache first 	cached, err := redisClient.Get(ctx, "customers:list").Result() 	if err == nil {
		var customers []Customer 		json.Unmarshal([]byte(cached), &customers) 		c.JSON(http.StatusOK, customers) 		return 	}  	rows, err := db.Query(`SELECT id, customer_id, first_name, last_name, email, phone,  		kyc_status, status, created_at FROM customers ORDER BY created_at DESC LIMIT 100`) 	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch customers"}) 		return 	} 	defer rows.Close()  	customers := []Customer{} 	for rows.Next() {
		var customer Customer 		err := rows.Scan(&customer.ID, &customer.CustomerID, &customer.FirstName, &customer.LastName, 			&customer.Email, &customer.Phone, &customer.KYCStatus, &customer.Status, &customer.CreatedAt) 		if err != nil {
			continue 		} 		customers = append(customers, customer) 	}  	// Cache the result 	data, _ := json.Marshal(customers) 	redisClient.Set(ctx, "customers:list", data, 5*time.Minute)  	c.JSON(http.StatusOK, customers)
}
 
func getCustomer(c *gin.Context) {
	id := c.Param("id")  	var customer Customer 	query := `SELECT id, customer_id, first_name, last_name, email, phone, date_of_birth,  		address, city, state, zip_code, country, kyc_status, status, created_at, updated_at  		FROM customers WHERE id = $1`  	err := db.QueryRow(query, id).Scan(&customer.ID, &customer.CustomerID, &customer.FirstName, 		&customer.LastName, &customer.Email, &customer.Phone, &customer.DateOfBirth, &customer.Address, 		&customer.City, &customer.State, &customer.ZipCode, &customer.Country, &customer.KYCStatus, 		&customer.Status, &customer.CreatedAt, &customer.UpdatedAt)  	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Customer not found"}) 		return 	} 	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch customer"}) 		return 	}  	c.JSON(http.StatusOK, customer)
}
 
func updateCustomer(c *gin.Context) {
	id := c.Param("id") 	var customer Customer 	if err := c.ShouldBindJSON(&customer); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()}) 		return 	}  	query := `UPDATE customers SET first_name=$1, last_name=$2, phone=$3, address=$4,  		city=$5, state=$6, zip_code=$7, updated_at=CURRENT_TIMESTAMP WHERE id=$8`  	_, err := db.Exec(query, customer.FirstName, customer.LastName, customer.Phone, 		customer.Address, customer.City, customer.State, customer.ZipCode, id)  	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update customer"}) 		return 	}  	// Invalidate cache 	redisClient.Del(ctx, "customers:list") 	publishEvent("customer.updated", customer)  	c.JSON(http.StatusOK, gin.H{"message": "Customer updated successfully"})
}
 
func deleteCustomer(c *gin.Context) {
	id := c.Param("id")  	_, err := db.Exec("UPDATE customers SET status='deleted', updated_at=CURRENT_TIMESTAMP WHERE id=$1", id) 	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete customer"}) 		return 	}  	redisClient.Del(ctx, "customers:list") 	publishEvent("customer.deleted", gin.H{"customer_id": id})  	c.JSON(http.StatusOK, gin.H{"message": "Customer deleted successfully"})
}
 
func updateKYCStatus(c *gin.Context) {
	id := c.Param("id") 	var data struct {
		Status string `json:"status"` 	}  	if err := c.ShouldBindJSON(&data); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()}) 		return 	}  	_, err := db.Exec("UPDATE customers SET kyc_status=$1, updated_at=CURRENT_TIMESTAMP WHERE id=$2", data.Status, id) 	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update KYC status"}) 		return 	}  	publishEvent("customer.kyc_updated", gin.H{"customer_id": id, "kyc_status": data.Status}) 	c.JSON(http.StatusOK, gin.H{"message": "KYC status updated"})
}
  // Branch handlers
func createBranch(c *gin.Context) {
	var branch Branch 	if err := c.ShouldBindJSON(&branch); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()}) 		return 	}  	query := `INSERT INTO branches (branch_code, branch_name, address, city, state, zip_code, phone, manager)  		VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id, created_at`  	err := db.QueryRow(query, branch.BranchCode, branch.BranchName, branch.Address, branch.City, 		branch.State, branch.ZipCode, branch.Phone, branch.Manager).Scan(&branch.ID, &branch.CreatedAt)  	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create branch"}) 		return 	}  	c.JSON(http.StatusCreated, branch)
}
 
func listBranches(c *gin.Context) {
	rows, err := db.Query(`SELECT id, branch_code, branch_name, address, city, state, zip_code,  		phone, manager, is_active, created_at FROM branches WHERE is_active=true ORDER BY branch_name`) 	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch branches"}) 		return 	} 	defer rows.Close()  	branches := []Branch{} 	for rows.Next() {
		var branch Branch 		rows.Scan(&branch.ID, &branch.BranchCode, &branch.BranchName, &branch.Address, &branch.City, 			&branch.State, &branch.ZipCode, &branch.Phone, &branch.Manager, &branch.IsActive, &branch.CreatedAt) 		branches = append(branches, branch) 	}  	c.JSON(http.StatusOK, branches)
}
 
func getBranch(c *gin.Context) {
	id := c.Param("id") 	var branch Branch  	err := db.QueryRow(`SELECT id, branch_code, branch_name, address, city, state, zip_code,  		phone, manager, is_active, created_at FROM branches WHERE id=$1`, id).Scan( 		&branch.ID, &branch.BranchCode, &branch.BranchName, &branch.Address, &branch.City, 		&branch.State, &branch.ZipCode, &branch.Phone, &branch.Manager, &branch.IsActive, &branch.CreatedAt)  	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Branch not found"}) 		return 	} 	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch branch"}) 		return 	}  	c.JSON(http.StatusOK, branch)
}
  // Account Type handlers
func createAccountType(c *gin.Context) {
	var accountType AccountType 	if err := c.ShouldBindJSON(&accountType); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()}) 		return 	}  	query := `INSERT INTO account_types (account_type_name, description, min_balance, interest_rate, monthly_fee)  		VALUES ($1, $2, $3, $4, $5) RETURNING id`  	err := db.QueryRow(query, accountType.AccountTypeName, accountType.Description, accountType.MinBalance, 		accountType.InterestRate, accountType.MonthlyFee).Scan(&accountType.ID)  	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create account type"}) 		return 	}  	c.JSON(http.StatusCreated, accountType)
}
 
func listAccountTypes(c *gin.Context) {
	rows, err := db.Query(`SELECT id, account_type_name, description, min_balance, interest_rate,  		monthly_fee, is_active FROM account_types WHERE is_active=true`) 	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch account types"}) 		return 	} 	defer rows.Close()  	types := []AccountType{} 	for rows.Next() {
		var at AccountType 		rows.Scan(&at.ID, &at.AccountTypeName, &at.Description, &at.MinBalance, &at.InterestRate, 			&at.MonthlyFee, &at.IsActive) 		types = append(types, at) 	}  	c.JSON(http.StatusOK, types)
}
 
func getAccountType(c *gin.Context) {
	id := c.Param("id") 	var accountType AccountType  	err := db.QueryRow(`SELECT id, account_type_name, description, min_balance, interest_rate,  		monthly_fee, is_active FROM account_types WHERE id=$1`, id).Scan( 		&accountType.ID, &accountType.AccountTypeName, &accountType.Description, &accountType.MinBalance, 		&accountType.InterestRate, &accountType.MonthlyFee, &accountType.IsActive)  	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Account type not found"}) 		return 	} 	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch account type"}) 		return 	}  	c.JSON(http.StatusOK, accountType)
}
  // Helper
functions
func publishEvent(eventType string, data interface{}) {
	if rabbitCh == nil {
		return 	}  	body, _ := json.Marshal(gin.H{ 		"event_type": eventType, 		"data":       data, 		"timestamp":  time.Now(), 	})  	rabbitCh.Publish( 		"", 		"customer_events", 		false, 		false, 		amqp.Publishing{ 			ContentType: "application/json", 			Body:        body, 		}, 	)
}
 
func prometheusMiddleware() gin.HandlerFunc {
	return
func(c *gin.Context) {
		start := time.Now() 		c.Next() 		duration := time.Since(start).Seconds()  		requestsTotal.WithLabelValues(c.Request.Method, c.FullPath(), fmt.Sprintf("%d", c.Writer.Status())).Inc() 		requestDuration.WithLabelValues(c.Request.Method, c.FullPath()).Observe(duration) 	}
}
 
func loggingMiddleware() gin.HandlerFunc {
	return
func(c *gin.Context) {
		start := time.Now() 		c.Next() 		duration := time.Since(start)  		log.Printf("[%s] %s %s _ %d (%v)", 			c.Request.Method, 			c.Request.URL.Path, 			c.ClientIP(), 			c.Writer.Status(), 			duration, 		) 	}
}
 
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value 	} 	return defaultValue
}



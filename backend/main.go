package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	_ "github.com/lib/pq"
)

// User represents a user in our database
type User struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

var db *sql.DB

func main() {
	// Get database connection info from environment variables
	// 👇 These come from our Secret and ConfigMap!
	dbHost := os.Getenv("DB_HOST")
	dbUser := os.Getenv("POSTGRES_USER")
	dbPassword := os.Getenv("POSTGRES_PASSWORD")
	dbName := os.Getenv("POSTGRES_DB")

	// Build connection string
	connStr := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=5432 sslmode=disable",
		dbHost, dbUser, dbPassword, dbName)

	// Connect to database
	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// Test the connection
	err = db.Ping()
	if err != nil {
		log.Fatal("Failed to ping database:", err)
	}
	log.Println("✅ Connected to database successfully!")

	// Initialize database (create table and sample data)
	initDatabase()

	// Set up HTTP routes
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/api/test-db", testDBHandler)
	http.HandleFunc("/api/users", usersHandler)

	// Start server
	port := ":3000"
	log.Printf("🚀 Backend API listening on port %s\n", port)
	log.Fatal(http.ListenAndServe(port, nil))
}

// healthHandler returns a simple health check
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
}

// testDBHandler tests the database connection
func testDBHandler(w http.ResponseWriter, r *http.Request) {
	var now time.Time
	err := db.QueryRow("SELECT NOW()").Scan(&now)

	w.Header().Set("Content-Type", "application/json")

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"message": "Database connection failed",
			"error":   err.Error(),
		})
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"message":   "Database connection successful!",
		"timestamp": now,
	})
}

// usersHandler returns all users from the database
func usersHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT id, name, created_at FROM users ORDER BY id")
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}
	defer rows.Close()

	// Collect all users
	var users []User
	for rows.Next() {
		var u User
		if err := rows.Scan(&u.ID, &u.Name, &u.CreatedAt); err != nil {
			log.Println("Error scanning row:", err)
			continue
		}
		users = append(users, u)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// initDatabase creates the table and inserts sample data
func initDatabase() {
	// Create table if it doesn't exist
	createTableSQL := `
	CREATE TABLE IF NOT EXISTS users (
		id SERIAL PRIMARY KEY,
		name VARCHAR(100) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	_, err := db.Exec(createTableSQL)
	if err != nil {
		log.Fatal("Failed to create table:", err)
	}

	// Check if we need to insert sample data
	var count int
	err = db.QueryRow("SELECT COUNT(*) FROM users").Scan(&count)
	if err != nil {
		log.Fatal("Failed to count users:", err)
	}

	if count == 0 {
		insertSQL := `
		INSERT INTO users (name) VALUES
			('Jabril'),
			('Platform Engineer'),
			('Go Developer'),
			('Kubernetes Master')`

		_, err = db.Exec(insertSQL)
		if err != nil {
			log.Fatal("Failed to insert sample data:", err)
		}
		log.Println("✅ Sample data inserted!")
	}

	log.Println("✅ Database initialized successfully!")
}

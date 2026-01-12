-- ============================================================================
-- PostgreSQL Database Schema
-- LiveCode Server RPC API Template
-- ============================================================================
--
-- This schema is optimized for PostgreSQL 9.5+
-- Encoding: UTF8 (supports full Unicode)
--
-- Usage:
--   psql -U postgres < schema-postgresql.sql
--
-- Or from psql command line:
--   \i /path/to/schema-postgresql.sql
--
-- ============================================================================

-- Create database
CREATE DATABASE myapp_api
  ENCODING 'UTF8'
  LC_COLLATE = 'en_US.UTF-8'
  LC_CTYPE = 'en_US.UTF-8';

\c myapp_api

-- ============================================================================
-- USERS TABLE
-- ============================================================================
-- Stores user authentication data with enhanced password security
--
-- Password Security Features:
--   - password_hash: SHA256 hash (64 hex characters)
--   - password_salt: Random 32-character hex salt (NULL for legacy unsalted)
--   - password_iterations: Iteration count for PBKDF2-like hashing (NULL for legacy)
--
-- The API supports automatic migration:
--   Unsalted (legacy) → Salted → Enhanced (with iterations)
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(64) NOT NULL, -- SHA256 hash (64 hex chars)
  password_salt VARCHAR(32) DEFAULT NULL, -- Random salt (NULL for legacy unsalted)
  password_iterations INTEGER DEFAULT NULL, -- Hash iterations (NULL for legacy, default: 1000)
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  is_active SMALLINT DEFAULT 1, -- 1=active, 0=inactive
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_username ON users(username);
CREATE INDEX idx_active ON users(is_active);

-- ============================================================================
-- PRODUCTS TABLE
-- ============================================================================
-- Example resource table for CRUD operations
-- Use this as a template for your own resources
-- ============================================================================

CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
  created_by VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_created_by ON products(created_by);
CREATE INDEX IF NOT EXISTS idx_created_at ON products(created_at);

-- ============================================================================
-- AUDIT TABLE
-- ============================================================================
-- Tracks all database changes for compliance and debugging
-- Records who changed what and when
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit (
  id SERIAL PRIMARY KEY,
  audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  audit_user VARCHAR(255),
  audit_table VARCHAR(255),
  audit_primarykey INTEGER,
  action VARCHAR(10) CHECK (action IN ('create', 'update', 'delete')),
  old_values TEXT,
  new_values TEXT
);

CREATE INDEX IF NOT EXISTS idx_timestamp ON audit(audit_timestamp);
CREATE INDEX IF NOT EXISTS idx_table ON audit(audit_table);
CREATE INDEX IF NOT EXISTS idx_user ON audit(audit_user);
CREATE INDEX IF NOT EXISTS idx_action ON audit(action);

-- ============================================================================
-- TRIGGERS FOR AUTO-UPDATING TIMESTAMPS
-- ============================================================================
-- PostgreSQL doesn't support ON UPDATE CURRENT_TIMESTAMP like MySQL
-- We need to create a trigger function and apply it to tables
-- ============================================================================

-- Create function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to users table
CREATE TRIGGER users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Apply trigger to products table
CREATE TRIGGER products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- ============================================================================
-- SAMPLE DATA (OPTIONAL)
-- ============================================================================
-- Uncomment to create a default admin user
-- Default password: "password123" (change this immediately!)
--
-- Note: This uses unsalted password for simplicity
-- The API will automatically upgrade to salted+iterations on first login
-- ============================================================================

-- INSERT INTO users (username, password_hash, name, email, is_active) VALUES
-- ('admin', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Administrator', 'admin@example.com', 1);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify your database setup:
--
-- \dt                          -- List all tables
-- \d users                     -- Describe users table
-- \d products                  -- Describe products table
-- \d audit                     -- Describe audit table
-- SELECT COUNT(*) FROM users;  -- Count users
--
-- ============================================================================

-- ============================================================================
-- MySQL Database Schema
-- LiveCode Server RPC API Template
-- ============================================================================
--
-- This schema is optimized for MySQL 5.7+
-- Character set: utf8mb4 (supports full Unicode including emojis)
--
-- Usage:
--   mysql -u root -p < schema-mysql.sql
--
-- Or from MySQL command line:
--   source /path/to/schema-mysql.sql
--
-- ============================================================================

-- Create database
CREATE DATABASE IF NOT EXISTS myapp_api
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE myapp_api;

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
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(64) NOT NULL COMMENT 'SHA256 hash (64 hex chars)',
  password_salt VARCHAR(32) DEFAULT NULL COMMENT 'Random salt (NULL for legacy unsalted)',
  password_iterations INT DEFAULT NULL COMMENT 'Hash iterations (NULL for legacy, default: 1000)',
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  is_active TINYINT(1) DEFAULT 1 COMMENT '1=active, 0=inactive',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_username (username),
  INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PRODUCTS TABLE
-- ============================================================================
-- Example resource table for CRUD operations
-- Use this as a template for your own resources
-- ============================================================================

CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status ENUM('active', 'inactive', 'pending') DEFAULT 'active',
  created_by VARCHAR(255) COMMENT 'Username of creator',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_status (status),
  INDEX idx_created_by (created_by),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- AUDIT TABLE
-- ============================================================================
-- Tracks all database changes for compliance and debugging
-- Records who changed what and when
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit (
  id INT AUTO_INCREMENT PRIMARY KEY,
  audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  audit_user VARCHAR(255) COMMENT 'Username who made the change',
  audit_table VARCHAR(255) COMMENT 'Table that was modified',
  audit_primarykey INT COMMENT 'Primary key of modified record',
  action ENUM('create', 'update', 'delete'),
  old_values TEXT COMMENT 'JSON of old values (for update/delete)',
  new_values TEXT COMMENT 'JSON of new values (for create/update)',

  INDEX idx_timestamp (audit_timestamp),
  INDEX idx_table (audit_table),
  INDEX idx_user (audit_user),
  INDEX idx_action (action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- To create a properly salted password from the start, use the API's create-user.lc script instead

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify your database setup:
--
-- SHOW TABLES;
-- DESCRIBE users;
-- DESCRIBE products;
-- DESCRIBE audit;
-- SELECT COUNT(*) FROM users;
--
-- ============================================================================

-- ============================================================================
-- Microsoft SQL Server Database Schema
-- LiveCode Server RPC API Template (via ODBC)
-- ============================================================================
--
-- This schema is optimized for Microsoft SQL Server 2012+
--
-- Usage:
--   sqlcmd -S localhost -U sa -P password -i schema-sqlserver.sql
--
-- Or from SQL Server Management Studio:
--   Open file and execute (F5)
--
-- Prerequisites:
--   - SQL Server installed and running
--   - ODBC driver installed (see ODBC-SETUP.md)
--   - DSN configured in ODBC Data Source Administrator
--
-- ============================================================================

-- Create database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'myapp_api')
BEGIN
  CREATE DATABASE myapp_api;
END
GO

USE myapp_api;
GO

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

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'users') AND type = 'U')
BEGIN
  CREATE TABLE users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(64) NOT NULL, -- SHA256 hash (64 hex chars)
    password_salt VARCHAR(32) NULL, -- Random salt (NULL for legacy unsalted)
    password_iterations INT NULL, -- Hash iterations (NULL for legacy, default: 1000)
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    is_active BIT DEFAULT 1, -- 1=active, 0=inactive
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
  );

  CREATE INDEX idx_username ON users(username);
  CREATE INDEX idx_active ON users(is_active);
END
GO

-- ============================================================================
-- PRODUCTS TABLE
-- ============================================================================
-- Example resource table for CRUD operations
-- Use this as a template for your own resources
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'products') AND type = 'U')
BEGIN
  CREATE TABLE products (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    created_by VARCHAR(255),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
  );

  CREATE INDEX idx_status ON products(status);
  CREATE INDEX idx_created_by ON products(created_by);
  CREATE INDEX idx_created_at ON products(created_at);
END
GO

-- ============================================================================
-- AUDIT TABLE
-- ============================================================================
-- Tracks all database changes for compliance and debugging
-- Records who changed what and when
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'audit') AND type = 'U')
BEGIN
  CREATE TABLE audit (
    id INT IDENTITY(1,1) PRIMARY KEY,
    audit_timestamp DATETIME2 DEFAULT GETDATE(),
    audit_user VARCHAR(255),
    audit_table VARCHAR(255),
    audit_primarykey INT,
    action VARCHAR(10) CHECK (action IN ('create', 'update', 'delete')),
    old_values TEXT,
    new_values TEXT
  );

  CREATE INDEX idx_timestamp ON audit(audit_timestamp);
  CREATE INDEX idx_table ON audit(audit_table);
  CREATE INDEX idx_user ON audit(audit_user);
  CREATE INDEX idx_action ON audit(action);
END
GO

-- ============================================================================
-- TRIGGERS FOR AUTO-UPDATING TIMESTAMPS
-- ============================================================================
-- SQL Server uses triggers to auto-update timestamp columns
-- ============================================================================

-- Update timestamp trigger for users table
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'users_updated_at')
BEGIN
  EXEC('
  CREATE TRIGGER users_updated_at
  ON users
  AFTER UPDATE
  AS
  BEGIN
    SET NOCOUNT ON;
    UPDATE users
    SET updated_at = GETDATE()
    WHERE id IN (SELECT DISTINCT id FROM inserted);
  END
  ');
END
GO

-- Update timestamp trigger for products table
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'products_updated_at')
BEGIN
  EXEC('
  CREATE TRIGGER products_updated_at
  ON products
  AFTER UPDATE
  AS
  BEGIN
    SET NOCOUNT ON;
    UPDATE products
    SET updated_at = GETDATE()
    WHERE id IN (SELECT DISTINCT id FROM inserted);
  END
  ');
END
GO

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
-- GO

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify your database setup:
--
-- SELECT name FROM sys.tables;              -- List all tables
-- EXEC sp_help 'users';                     -- Describe users table
-- EXEC sp_help 'products';                  -- Describe products table
-- EXEC sp_help 'audit';                     -- Describe audit table
-- SELECT COUNT(*) FROM users;               -- Count users
--
-- ============================================================================

-- ============================================================================
-- SQL SERVER-SPECIFIC NOTES
-- ============================================================================
--
-- 1. Getting Last Inserted ID:
--    In SQL Server, use SCOPE_IDENTITY():
--
--    LiveCode example:
--    revExecuteSQL tConnID, tInsertSQL
--    put revDataFromQuery(,,tConnID,"SELECT SCOPE_IDENTITY()") into tNewID
--
-- 2. Data Types:
--    - IDENTITY(1,1) replaces AUTO_INCREMENT
--    - BIT replaces TINYINT for booleans
--    - DATETIME2 replaces TIMESTAMP (more precision)
--    - TEXT is supported but VARCHAR(MAX) is recommended
--
-- 3. Boolean Values:
--    Use BIT type with 0 and 1 for false/true
--
-- 4. String Concatenation:
--    Use + operator instead of CONCAT():
--    SELECT firstname + ' ' + lastname AS fullname FROM users;
--
-- 5. Limit/Offset:
--    SQL Server 2012+ uses OFFSET/FETCH:
--    SELECT * FROM products ORDER BY id OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
--    (Skip 10 rows, get next 20)
--
-- 6. Authentication:
--    SQL Server supports both:
--    - Windows Authentication (integrated security)
--    - SQL Server Authentication (username/password)
--
--    For ODBC, use SQL Server Authentication for web apps
--
-- 7. Connection String Examples:
--
--    Using DSN:
--    DSN=MyDatabase;UID=sa;PWD=password
--
--    DSN-less:
--    DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost;DATABASE=myapp_api;UID=sa;PWD=password
--
--    With encryption:
--    DSN=MyDatabase;UID=sa;PWD=password;Encrypt=yes;TrustServerCertificate=yes
--
-- ============================================================================

-- ============================================================================
-- SQLite Database Schema
-- LiveCode Server RPC API Template
-- ============================================================================
--
-- This schema is optimized for SQLite 3.x
-- Encoding: UTF-8 (default)
--
-- Usage:
--   sqlite3 myapp.db < schema-sqlite.sql
--
-- Or from sqlite3 command line:
--   .read /path/to/schema-sqlite.sql
--
-- Note: SQLite creates the database file automatically on first connection
-- ============================================================================

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
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL, -- SHA256 hash (64 hex chars)
  password_salt TEXT DEFAULT NULL, -- Random salt (NULL for legacy unsalted)
  password_iterations INTEGER DEFAULT NULL, -- Hash iterations (NULL for legacy, default: 1000)
  name TEXT NOT NULL,
  email TEXT,
  is_active INTEGER DEFAULT 1, -- 1=active, 0=inactive
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_active ON users(is_active);

-- ============================================================================
-- PRODUCTS TABLE
-- ============================================================================
-- Example resource table for CRUD operations
-- Use this as a template for your own resources
-- ============================================================================

CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
  created_by TEXT,
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
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  audit_user TEXT,
  audit_table TEXT,
  audit_primarykey INTEGER,
  action TEXT CHECK (action IN ('create', 'update', 'delete')),
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
-- SQLite requires triggers for auto-updating timestamps
-- ============================================================================

-- Update timestamp trigger for users table
CREATE TRIGGER IF NOT EXISTS users_updated_at
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
  UPDATE users
  SET updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.id;
END;

-- Update timestamp trigger for products table
CREATE TRIGGER IF NOT EXISTS products_updated_at
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
  UPDATE products
  SET updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.id;
END;

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
-- .tables                      -- List all tables
-- .schema users                -- Show users table schema
-- .schema products             -- Show products table schema
-- .schema audit                -- Show audit table schema
-- SELECT COUNT(*) FROM users;  -- Count users
--
-- ============================================================================

-- ============================================================================
-- SQLITE-SPECIFIC NOTES
-- ============================================================================
--
-- 1. Getting Last Inserted ID:
--    In LiveCode: revDataFromQuery(,,tConnID,"SELECT last_insert_rowid()")
--
-- 2. Data Types:
--    SQLite uses TEXT for all string types (no VARCHAR)
--    INTEGER is used for all integer types and booleans
--
-- 3. Boolean Values:
--    Use 0 and 1 for false/true (stored as INTEGER)
--
-- 4. File Location:
--    The database is a single file (e.g., /var/www/api/data/myapp.db)
--    Make sure the directory is writable by the web server
--
-- 5. Permissions:
--    chmod 755 /var/www/api/data
--    chmod 644 /var/www/api/data/myapp.db
--    chown www-data:www-data /var/www/api/data/myapp.db
--
-- ============================================================================

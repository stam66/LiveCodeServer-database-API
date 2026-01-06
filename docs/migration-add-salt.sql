-- ============================================================================
-- MIGRATION: Add Password Salt Support
-- ============================================================================
--
-- This migration adds the password_salt column to the users table for
-- secure salted password hashing.
--
-- IMPORTANT: This migration is backward compatible. Users with unsalted
-- passwords will be automatically upgraded to salted passwords on their
-- next successful login.
--
-- Usage:
--   MySQL:      mysql -u username -p database_name < migration-add-salt.sql
--   PostgreSQL: psql -U username -d database_name -f migration-add-salt.sql
--   SQLite:     sqlite3 database.db < migration-add-salt.sql
--
-- ============================================================================

-- Add password_salt column if it doesn't exist
-- MySQL
ALTER TABLE users ADD COLUMN password_salt VARCHAR(32) DEFAULT NULL AFTER password_hash;

-- PostgreSQL (comment out MySQL above, uncomment below)
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS password_salt VARCHAR(32) DEFAULT NULL;

-- SQLite (comment out MySQL above, uncomment below)
-- ALTER TABLE users ADD COLUMN password_salt TEXT;


-- ============================================================================
-- NOTES FOR NEW INSTALLATIONS
-- ============================================================================
--
-- For new installations, include the password_salt column in your CREATE TABLE:
--
-- CREATE TABLE users (
--   id INTEGER PRIMARY KEY AUTO_INCREMENT,
--   username VARCHAR(100) NOT NULL UNIQUE,
--   password_hash VARCHAR(64) NOT NULL,
--   password_salt VARCHAR(32) DEFAULT NULL,
--   name VARCHAR(255) NOT NULL,
--   email VARCHAR(255),
--   is_active BOOLEAN DEFAULT 1,
--   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--   updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
-- );


-- ============================================================================
-- MIGRATION STRATEGY
-- ============================================================================
--
-- This migration allows for a graceful transition:
--
-- 1. Existing users with unsalted passwords (password_salt = NULL) will continue
--    to authenticate using their old passwords
--
-- 2. On successful login, the auth.lc script automatically:
--    - Generates a new random salt
--    - Re-hashes the password with the salt
--    - Updates the database with the new hash and salt
--
-- 3. New users created via the API will automatically use salted passwords
--
-- This zero-downtime migration ensures no user lockouts during deployment.
--

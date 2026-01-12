# Database Setup Guide

This guide contains database schema information and setup instructions for all supported databases.

## Quick Start

**Choose your database and use the corresponding SQL file:**

| Database | SQL File | Documentation |
|----------|----------|---------------|
| MySQL | [`sql/schema-mysql.sql`](../sql/schema-mysql.sql) | See below |
| PostgreSQL | [`sql/schema-postgresql.sql`](../sql/schema-postgresql.sql) | See below |
| SQLite | [`sql/schema-sqlite.sql`](../sql/schema-sqlite.sql) | See below |
| ODBC (SQL Server, Oracle, etc.) | [`sql/schema-sqlserver.sql`](../sql/schema-sqlserver.sql) | [`sql/ODBC-SETUP.md`](../sql/ODBC-SETUP.md) |

**After creating your database:**
1. Run the appropriate SQL file for your database
2. Configure `API/lib/db-functions.lc` (see Configuration section below)
3. Create your first user (see "Creating Your First User" section)

## Configuration

Edit `API/lib/db-functions.lc` and update these functions (around line 29):

```livecode
-- Choose your database type
function getDBType
  return "mysql"  -- Options: "mysql", "postgresql", "sqlite", "odbc"
end getDBType

-- Set your database credentials
function getDBHost
  return "localhost"
end getDBHost

function getDBName
  return "myapp_api"  -- For SQLite: "/var/www/api/data/myapp.db"
end getDBName

function getDBUser
  return "db_user"
end getDBUser

function getDBPassword
  return "db_password"
end getDBPassword
```

**For ODBC connections, also configure:**
```livecode
function getODBCDSN
  return "MyODBCDSN"  -- Your ODBC DSN name
end getODBCDSN
```

## Security Features

All schemas include enhanced password security:

- **password_hash**: SHA256 hash (64 hex characters)
- **password_salt**: Random 32-character hex salt (NULL for legacy unsalted)
- **password_iterations**: Iteration count for PBKDF2-like hashing (NULL for legacy, default: 1000)

The API supports automatic migration on login:
```
Unsalted (legacy) → Salted → Enhanced (with iterations)
```

**Important:** All password hashing is done in LiveCode (not in SQL), making the code 100% portable across all database types.

## Schemas Included in This Document

The sections below contain inline schemas for reference. **We recommend using the dedicated SQL files in the [`sql/`](../sql/) directory instead**, as they include additional comments, sample data, and verification queries.

---

## MySQL

```sql
-- Create database
CREATE DATABASE myapp_api 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;

USE myapp_api;

-- Create products table
CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status ENUM('active', 'inactive', 'pending') DEFAULT 'active',
  created_by VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_status (status)
);

-- Create audit table
CREATE TABLE audit (
  id INT AUTO_INCREMENT PRIMARY KEY,
  audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  audit_user VARCHAR(255),
  audit_table VARCHAR(255),
  audit_primarykey INT,
  action ENUM('create', 'update', 'delete'),
  old_values TEXT,
  new_values TEXT,
  
  INDEX idx_timestamp (audit_timestamp),
  INDEX idx_table (audit_table)
);

-- Create users table with salted password support
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(64) NOT NULL,
  password_salt VARCHAR(32) DEFAULT NULL,
  password_iterations INT DEFAULT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## PostgreSQL

```sql
-- Create database
CREATE DATABASE myapp_api 
  ENCODING 'UTF8';

\c myapp_api

-- Create products table
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
  created_by VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_status ON products(status);

-- Create update trigger for updated_at
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Create audit table
CREATE TABLE audit (
  id SERIAL PRIMARY KEY,
  audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  audit_user VARCHAR(255),
  audit_table VARCHAR(255),
  audit_primarykey INTEGER,
  action VARCHAR(10) CHECK (action IN ('create', 'update', 'delete')),
  old_values TEXT,
  new_values TEXT
);

CREATE INDEX idx_timestamp ON audit(audit_timestamp);
CREATE INDEX idx_table ON audit(audit_table);

-- Create users table with salted password support
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(64) NOT NULL,
  password_salt VARCHAR(32) DEFAULT NULL,
  password_iterations INTEGER DEFAULT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  is_active SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();
```

**PostgreSQL Notes:**
- Uses `SERIAL` instead of `AUTO_INCREMENT`
- Uses triggers for `updated_at` instead of `ON UPDATE CURRENT_TIMESTAMP`
- Uses `VARCHAR(10)` with CHECK constraints instead of ENUM
- When getting last inserted ID, use: `INSERT INTO ... RETURNING id`

---

## SQLite

```sql
-- SQLite creates the database file automatically when you connect

-- Create products table
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
  created_by TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_status ON products(status);

-- Create update trigger for updated_at
CREATE TRIGGER products_updated_at
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
  UPDATE products 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = NEW.id;
END;

-- Create audit table
CREATE TABLE audit (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  audit_user TEXT,
  audit_table TEXT,
  audit_primarykey INTEGER,
  action TEXT CHECK (action IN ('create', 'update', 'delete')),
  old_values TEXT,
  new_values TEXT
);

CREATE INDEX idx_timestamp ON audit(audit_timestamp);
CREATE INDEX idx_table ON audit(audit_table);

-- Create users table with salted password support
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  password_salt TEXT DEFAULT NULL,
  password_iterations INTEGER DEFAULT NULL,
  name TEXT NOT NULL,
  email TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER users_updated_at
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
  UPDATE users
  SET updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.id;
END;
```

**SQLite Notes:**
- Uses `INTEGER PRIMARY KEY AUTOINCREMENT` instead of `AUTO_INCREMENT`
- Uses `TEXT` instead of `VARCHAR`
- Uses triggers for `updated_at` 
- Uses `INTEGER` for boolean values (0/1)
- When getting last inserted ID, use: `revDataFromQuery(,,,"SELECT last_insert_rowid()")`

---

## Creating Your First User

Since we use LiveCode's `messageDigest()` function for password hashing (not database-specific functions), this code works with **any database**:

Create `/var/www/api/create-user.lc`:

```livecode
<?lc
include "lib/db-functions.lc"

put "admin" into tUsername
put "password123" into tPassword
put "Administrator" into tName

-- Hash password using LiveCode (works with MySQL, PostgreSQL, SQLite, ODBC)
put messageDigest(tPassword, "SHA256") into tPasswordHash

put dbConnect() into tConnID
if tConnID begins with "ERROR:" then
  put tConnID
  exit to top
end if

put "INSERT INTO users (username, password_hash, name, email)" into tSQL
put " VALUES ('" & sqlEscape(tUsername) & "'," after tSQL
put " '" & tPasswordHash & "'," after tSQL
put " '" & sqlEscape(tName) & "'," after tSQL
put " 'admin@example.com')" after tSQL

revExecuteSQL tConnID, tSQL

if the result is empty then
  put "User created:" && tUsername
else
  put "Error:" && the result
end if

revCloseDatabase tConnID
?>
```

Run it once to create the admin user:
```bash
curl "http://localhost/api/create-user.lc"
```

Then delete it for security:
```bash
rm /var/www/api/create-user.lc
```

---

## Database-Specific Code Adjustments

If you use PostgreSQL or SQLite, you may need to adjust a few SQL queries in your resource endpoints:

### Getting Last Inserted ID

**MySQL:**
```livecode
revExecuteSQL tConnID, tInsertSQL
put revDataFromQuery(,,tConnID,"SELECT LAST_INSERT_ID()") into tNewID
```

**PostgreSQL:**
```livecode
put tInsertSQL & " RETURNING id" into tInsertSQL
put revDataFromQuery(,,tConnID, tInsertSQL) into tNewID
```

**SQLite:**
```livecode
revExecuteSQL tConnID, tInsertSQL
put revDataFromQuery(,,tConnID,"SELECT last_insert_rowid()") into tNewID
```

### ENUM vs CHECK Constraints

**MySQL** uses `ENUM('active','inactive')` in table definition.

**PostgreSQL/SQLite** use `VARCHAR/TEXT` with `CHECK` constraints, but queries are identical.

Both allow: `WHERE status = 'active'`

### SQL Server (ODBC)

**Getting Last Inserted ID:**
```livecode
revExecuteSQL tConnID, tInsertSQL
put revDataFromQuery(,,tConnID,"SELECT SCOPE_IDENTITY()") into tNewID
```

**For more information on using ODBC with SQL Server, Oracle, and other databases:**
See [`sql/ODBC-SETUP.md`](../sql/ODBC-SETUP.md) for complete setup instructions.

---

## Supported Databases

| Database | Driver Type | Status | Notes |
|----------|------------|--------|-------|
| MySQL | Direct | ✅ Fully Supported | Recommended for web applications |
| PostgreSQL | Direct | ✅ Fully Supported | Advanced features, excellent for complex queries |
| SQLite | Direct | ✅ Fully Supported | Perfect for development, single-file database |
| SQL Server | ODBC | ✅ Fully Supported | Enterprise database, Windows/Linux |
| Oracle | ODBC | ✅ Supported | Requires Oracle ODBC driver |
| IBM DB2 | ODBC | ✅ Supported | Requires DB2 ODBC driver |
| Microsoft Access | ODBC | ✅ Supported | Windows only, legacy databases |
| Any ODBC-compatible | ODBC | ✅ Supported | See ODBC-SETUP.md |

**Recommendation:** Use direct drivers (MySQL, PostgreSQL, SQLite) when possible for better performance. Use ODBC for databases without direct LiveCode support (SQL Server, Oracle, etc.).

---

## Additional Resources

- **SQL Files:** [`sql/`](../sql/) directory contains ready-to-use schema files
- **ODBC Setup:** [`sql/ODBC-SETUP.md`](../sql/ODBC-SETUP.md) - Complete guide for ODBC connections
- **Function Reference:** [`FUNCTION-REFERENCE.md`](FUNCTION-REFERENCE.md) - All database functions
- **Quick Start:** [`QUICK-START.md`](QUICK-START.md) - Step-by-step setup guide

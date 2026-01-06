# Database Setup Examples

This file contains database schema examples for MySQL, PostgreSQL, and SQLite.

**Note:** All three schemas are functionally equivalent. Password hashing is done in LiveCode (not in SQL), making the code portable across all database types.

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

-- Create users table
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
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

-- Create users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
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

-- Create users table
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
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

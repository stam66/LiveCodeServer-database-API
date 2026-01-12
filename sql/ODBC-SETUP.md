# ODBC Setup Guide

ODBC (Open Database Connectivity) is a standard API for accessing database systems. It allows you to connect to various databases using a unified interface. This guide explains how to set up ODBC with LiveCode Server.

## What is ODBC?

ODBC acts as a translator between your application and the database. Instead of using database-specific drivers (MySQL, PostgreSQL, etc.), you use ODBC drivers that provide a consistent interface.

**Benefits:**
- Connect to databases not directly supported by LiveCode
- Use the same code for multiple database types
- Access legacy databases (Microsoft Access, dBase, FoxPro, etc.)
- Enterprise databases (Oracle, SQL Server, DB2, etc.)

**When to use ODBC:**
- You need to connect to Microsoft SQL Server, Oracle, or IBM DB2
- You're working with legacy database formats
- You need cross-platform database abstraction
- Direct drivers (mysql, postgresql, sqlite) aren't available for your database

**When NOT to use ODBC:**
- You're using MySQL, PostgreSQL, or SQLite (use direct drivers for better performance)
- You need maximum performance (direct drivers are faster)

## Supported Databases via ODBC

ODBC can connect to virtually any database, including:

- **Microsoft SQL Server** (Windows/Linux)
- **Oracle Database**
- **IBM DB2**
- **Microsoft Access** (.mdb, .accdb files)
- **MySQL** (via ODBC driver)
- **PostgreSQL** (via ODBC driver)
- **SQLite** (via ODBC driver)
- **Sybase**
- **Informix**
- **FoxPro/dBase**
- **Excel spreadsheets** (read-only)
- And many more...

## Platform-Specific Setup

### Linux Setup

1. **Install ODBC Manager (unixODBC):**
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install unixodbc unixodbc-dev

   # CentOS/RHEL
   sudo yum install unixODBC unixODBC-devel
   ```

2. **Install Database-Specific ODBC Driver:**

   **For MySQL:**
   ```bash
   sudo apt-get install libmyodbc
   ```

   **For PostgreSQL:**
   ```bash
   sudo apt-get install odbc-postgresql
   ```

   **For Microsoft SQL Server:**
   ```bash
   curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
   curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
   sudo apt-get update
   sudo ACCEPT_EULA=Y apt-get install msodbcsql17
   ```

3. **Configure DSN (Data Source Name):**

   Edit `/etc/odbc.ini` (system-wide) or `~/.odbc.ini` (user-specific):

   ```ini
   [MyMySQLDatabase]
   Description = MySQL Database via ODBC
   Driver = MySQL
   Server = localhost
   Port = 3306
   Database = myapp_api
   User = db_user
   Password = db_password
   Option = 3

   [MyPostgreSQLDatabase]
   Description = PostgreSQL Database via ODBC
   Driver = PostgreSQL
   Server = localhost
   Port = 5432
   Database = myapp_api
   UserName = db_user
   Password = db_password

   [MySQLServerDatabase]
   Description = Microsoft SQL Server via ODBC
   Driver = ODBC Driver 17 for SQL Server
   Server = localhost
   Port = 1433
   Database = myapp_api
   UID = db_user
   PWD = db_password
   TrustServerCertificate = yes
   ```

4. **Test ODBC Connection:**
   ```bash
   # List configured DSNs
   odbcinst -q -s

   # Test connection
   isql -v MyMySQLDatabase
   ```

### macOS Setup

1. **Install ODBC Manager:**
   ```bash
   # Using Homebrew
   brew install unixodbc
   ```

2. **Install Database Drivers:**
   ```bash
   # MySQL
   brew install mysql-connector-odbc

   # PostgreSQL
   brew install psqlodbc
   ```

3. **Configure DSN:**

   Edit `/usr/local/etc/odbc.ini`:
   ```ini
   [MyDatabase]
   Driver = MySQL ODBC 8.0 Driver
   Server = localhost
   Database = myapp_api
   User = db_user
   Password = db_password
   Port = 3306
   ```

4. **Test Connection:**
   ```bash
   iodbctest "DSN=MyDatabase"
   ```

### Windows Setup

1. **ODBC Data Source Administrator:**
   - Press Win+R, type `odbcad32`, press Enter
   - Or: Control Panel → Administrative Tools → ODBC Data Sources

2. **Add New DSN:**
   - Click "Add" under User DSN or System DSN tab
   - Select your database driver (MySQL ODBC Driver, PostgreSQL ODBC, SQL Server, etc.)
   - Click "Finish"

3. **Configure Connection:**
   - Enter DSN name (e.g., "MyDatabase")
   - Enter server, database, username, password
   - Test connection
   - Click OK to save

4. **Common Windows Drivers:**
   - **MySQL:** Download from [MySQL Connector/ODBC](https://dev.mysql.com/downloads/connector/odbc/)
   - **PostgreSQL:** Download from [PostgreSQL ODBC](https://www.postgresql.org/ftp/odbc/versions/)
   - **SQL Server:** Built-in (SQL Server Native Client)
   - **Access:** Built-in (Microsoft Access Driver)

## LiveCode Configuration

Once you have ODBC set up, configure your API to use it:

**In `API/lib/db-functions.lc`:**

```livecode
-- Get database type
function getDBType
  return "odbc"
end getDBType

-- Get ODBC DSN
function getODBCDSN
  return "MyDatabase"  -- Replace with your DSN name
end getODBCDSN

-- Get database username (if not in DSN)
function getDBUser
  return "db_user"
end getDBUser

-- Get database password (if not in DSN)
function getDBPassword
  return "db_password"
end getDBPassword
```

The `dbConnect()` function will automatically use ODBC when `getDBType()` returns "odbc".

## Connection Methods

There are two ways to connect via ODBC:

### Method 1: Using DSN (Recommended)

```livecode
put revOpenDatabase("odbc", "DSN=MyDatabase;UID=user;PWD=password") into tConnectionID
```

**Advantages:**
- Centralized configuration
- Easy to change connection settings without modifying code
- Supports connection pooling
- Better security (credentials can be stored in DSN)

### Method 2: DSN-less Connection

```livecode
put "DRIVER={MySQL ODBC 8.0 Driver};SERVER=localhost;DATABASE=myapp;UID=user;PWD=password" into tConnectionString
put revOpenDatabase("odbc", tConnectionString) into tConnectionID
```

**Advantages:**
- No DSN configuration needed
- Portable across systems
- Good for testing

## Database Schema for ODBC

The SQL schema you use depends on the underlying database:

- **For MySQL via ODBC:** Use `schema-mysql.sql`
- **For PostgreSQL via ODBC:** Use `schema-postgresql.sql`
- **For SQL Server:** See below
- **For Access/Other:** Adapt the schema to your database's SQL dialect

### SQL Server Schema Example

```sql
-- Microsoft SQL Server Schema
CREATE DATABASE myapp_api;
GO

USE myapp_api;
GO

CREATE TABLE users (
  id INT IDENTITY(1,1) PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(64) NOT NULL,
  password_salt VARCHAR(32) NULL,
  password_iterations INT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  is_active BIT DEFAULT 1,
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE products (
  id INT IDENTITY(1,1) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
  created_by VARCHAR(255),
  created_at DATETIME2 DEFAULT GETDATE(),
  updated_at DATETIME2 DEFAULT GETDATE()
);

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
```

## Troubleshooting

### "Data source name not found"

**Cause:** DSN is not configured or has a different name.

**Solution:**
```bash
# Linux/macOS: List DSNs
odbcinst -q -s

# Windows: Open ODBC Data Source Administrator
odbcad32
```

### "Driver not found"

**Cause:** ODBC driver for your database is not installed.

**Solution:**
- Install the appropriate ODBC driver for your database
- Check driver name in `/etc/odbcinst.ini` (Linux) or ODBC Administrator (Windows)

### "Connection failed"

**Cause:** Wrong credentials, server not accessible, or firewall blocking.

**Solution:**
1. Test direct connection to database server
2. Verify credentials
3. Check firewall rules
4. Test with `isql` (Linux/macOS) or ODBC Administrator (Windows)

### Performance Issues

**Cause:** ODBC adds an extra layer between application and database.

**Solution:**
- Use direct drivers (mysql, postgresql, sqlite) when possible
- Enable connection pooling in DSN configuration
- Optimize SQL queries
- Use indexes on frequently queried columns

## Security Best Practices

1. **Use System DSN:** Store DSN in system configuration, not in code
2. **Restrict Permissions:** Limit DSN access to web server user only
3. **Use Least Privilege:** Database user should have only necessary permissions
4. **Encrypt Connections:** Enable SSL/TLS in ODBC driver settings
5. **Secure Credentials:** Never commit passwords to version control

## Performance Considerations

**Direct Drivers vs ODBC:**

| Feature | Direct Driver | ODBC |
|---------|--------------|------|
| Speed | Faster | Slower (extra layer) |
| Setup | Simple | More complex |
| Compatibility | Database-specific | Universal |
| Features | Full database support | May have limitations |

**Recommendation:** Use direct drivers (mysql, postgresql, sqlite) when available. Use ODBC only when necessary (SQL Server, Oracle, legacy databases).

## Testing Your ODBC Connection

Create a test file `/var/www/api/test-odbc.lc`:

```livecode
<?lc
put "Testing ODBC Connection..." & return

-- Method 1: Using DSN
put revOpenDatabase("odbc", "DSN=MyDatabase;UID=user;PWD=password") into tConnID

if tConnID is a number then
  put "✓ Connection successful! ID:" && tConnID & return

  -- Test query
  put revDataFromQuery(,,tConnID,"SELECT 1 AS test") into tResult
  put "✓ Query result:" && tResult & return

  revCloseDatabase tConnID
else
  put "✗ Connection failed:" && tConnID & return
end if
?>
```

Access: `http://localhost/api/test-odbc.lc`

## Additional Resources

- [LiveCode Database Guide](http://livecode.wikia.com/wiki/Databases)
- [unixODBC Documentation](http://www.unixodbc.org/)
- [Microsoft ODBC Documentation](https://docs.microsoft.com/en-us/sql/odbc/)
- [MySQL ODBC Driver](https://dev.mysql.com/doc/connector-odbc/en/)
- [PostgreSQL ODBC Driver](https://odbc.postgresql.org/)

## Summary

ODBC provides a flexible way to connect to virtually any database, but comes with added complexity and slight performance overhead. For MySQL, PostgreSQL, and SQLite, use direct drivers. For other databases (SQL Server, Oracle, Access, etc.), ODBC is your best option.

**Quick Setup Checklist:**
- [ ] Install ODBC manager (unixODBC or use system ODBC)
- [ ] Install database-specific ODBC driver
- [ ] Configure DSN with connection details
- [ ] Test connection with `isql` or ODBC Administrator
- [ ] Update `getDBType()` to return "odbc" in db-functions.lc
- [ ] Update `getODBCDSN()` with your DSN name
- [ ] Test API connection with test-odbc.lc

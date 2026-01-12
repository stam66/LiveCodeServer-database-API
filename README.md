# LiveCode Server RPC API Template

Build secure APIs with LiveCode Server using JWT authentication. Works with MySQL, PostgreSQL, SQLite, and ODBC (SQL Server, Oracle, etc.).

## What It Is

**4 files to build a complete API:**

1. **photon-library.lc** - JSON parsing
2. **db-functions.lc** - Database, JWT, and auth functions
3. **auth.lc** - Login endpoint (issues JWT tokens)
4. **resource-template.lc** - CRUD template (adapt for each database table)

Include one library, call functions, done.

## Quick Start

```bash
# 1. Choose your database and run the SQL schema
# MySQL:
mysql -u root -p < sql/schema-mysql.sql

# PostgreSQL:
psql -U postgres < sql/schema-postgresql.sql

# SQLite:
sqlite3 /var/www/api/data/myapp.db < sql/schema-sqlite.sql

# SQL Server (ODBC):
sqlcmd -S localhost -U sa -P password -i sql/schema-sqlserver.sql

# 2. Configure database connection (edit API/lib/db-functions.lc)
# Change these functions:
#   - getDBType() - Set to "mysql", "postgresql", "sqlite", or "odbc"
#   - getDBHost() - Your database host
#   - getDBName() - Your database name
#   - getDBUser() - Your database username
#   - getDBPassword() - Your database password
# See API/lib/db-config-example.lc for complete examples

# 3. Test
curl http://localhost/api/auth.lc?action=login \
  -d '{"username":"admin","password":"password123"}'
```

**That's it.**

## Installation

**Need LiveCode Server?**
- [Official Downloads](https://livecode.com/downloads/)
- [macOS Guide](https://forums.livecode.com/viewtopic.php?f=8&t=37853&p=222987#p222987) (forum post)
- [Ubuntu/nginx Complete Setup](docs/livecode-server-installation.md) (with MySQL & SSL)

**Database Setup:**
- [Database Setup Guide](docs/database-setup.md) - Schemas for MySQL, PostgreSQL, SQLite
- [ODBC Setup Guide](sql/ODBC-SETUP.md) - Setup for SQL Server, Oracle, and other ODBC databases
- [SQL Files](sql/) - Ready-to-use schema files for all databases

**Detailed Setup:**  
[Step-by-Step Guide](docs/QUICK-START.md)

## How It Works

**Include one library:**
```livecode
include "lib/db-functions.lc"
```

**Call functions:**
```livecode
put dbConnect() into tConnectionID
put validateJWT() into tUser
return jsonSuccess(tData)
```

**API endpoints:**
```bash
POST /auth.lc?action=login          # Get token
GET  /products.lc?action=list       # Public
POST /products.lc?action=create     # Requires auth
```

## Functions

**Available functions:** [→ Function Reference](docs/FUNCTION-REFERENCE.md)

- `dbConnect()` - Connect to database
- `sqlEscape()` - Prevent SQL injection
- `jsonSuccess()` / `jsonError()` - Return JSON
- `generateJWT()` / `verifyJWT()` - JWT tokens
- `validateJWT()` - Check auth header
- `generateSalt()` / `hashPassword()` / `verifyPassword()` - Secure password hashing

**Security:** Uses salted SHA256 password hashing. Migration support for upgrading from unsalted passwords.

## Architecture

RPC-style (action-based) instead of REST:
```
GET /products.lc?action=list
GET /products.lc?action=read&id=1
POST /products.lc?action=create
```

**Why?** Fewer files, simpler for complex operations. [Read more](docs/ARCHITECTURE.md)

## Features

- ✅ JWT authentication (HMAC-SHA256)
- ✅ Password hashing with iterations (PBKDF2-like, database-portable)
- ✅ SQL injection prevention
- ✅ **Multi-database support:** MySQL, PostgreSQL, SQLite, ODBC (SQL Server, Oracle, DB2, Access, etc.)
- ✅ **Easy database switching:** Change one function to switch databases
- ✅ Ready-to-use SQL schema files for all databases
- ✅ Just 2 library files (photon + db-functions)

## Structure

```
LiveCodeServer-database-API/
├── API/
│   ├── lib/
│   │   ├── photon-library.lc       # JSON parsing
│   │   ├── db-functions.lc         # Database & auth functions
│   │   └── db-config-example.lc    # Configuration examples
│   ├── auth.lc                     # Login endpoint
│   └── resource-template.lc        # CRUD template
├── sql/
│   ├── schema-mysql.sql            # MySQL schema
│   ├── schema-postgresql.sql       # PostgreSQL schema
│   ├── schema-sqlite.sql           # SQLite schema
│   ├── schema-sqlserver.sql        # SQL Server schema
│   └── ODBC-SETUP.md              # ODBC setup guide
└── docs/
    ├── database-setup.md           # Database setup guide
    ├── QUICK-START.md              # Step-by-step guide
    └── FUNCTION-REFERENCE.md       # API documentation
```

One file per database table in the API.

## Configuration

**Database (API/lib/db-functions.lc lines 29-75):**

The API now supports easy database switching. Simply edit these functions:

```livecode
-- Choose your database type
function getDBType
  return "mysql"  -- Options: "mysql", "postgresql", "sqlite", "odbc"
end getDBType

function getDBHost
  return "localhost"
end getDBHost

function getDBName
  return "myapp_api"  -- For SQLite: "/path/to/database.db"
end getDBName

function getDBUser
  return "db_user"
end getDBUser

function getDBPassword
  return "db_password"
end getDBPassword

-- For ODBC connections only:
function getODBCDSN
  return "MyODBCDSN"
end getODBCDSN
```

**See [`API/lib/db-config-example.lc`](API/lib/db-config-example.lc) for complete configuration examples for all database types.**

**JWT Secret (db-functions.lc line 63):**
```livecode
function getJWTSecret
  return "change-this-in-production-min-32-chars"
end getJWTSecret
```

## Example

```bash
# Login
curl -X POST http://localhost/api/auth.lc?action=login \
  -d '{"username":"admin","password":"pass123"}'
# Returns: {"status":"success","data":{"token":"eyJ..."}}

# Use token
TOKEN="eyJ..."
curl -X POST http://localhost/api/products.lc?action=create \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Widget","status":"active"}'

# List (no auth needed)
curl http://localhost/api/products.lc?action=list
```

## Documentation

- [Function Reference](docs/FUNCTION-REFERENCE.md) - All functions
- [Quick Start](docs/QUICK-START.md) - Step-by-step setup
- [Database Setup](docs/database-setup.md) - Schemas
- [LC Server Installation](docs/livecode-server-installation.md) - Complete guide
- [Architecture](docs/ARCHITECTURE.md) - Design decisions

## Support

- [GitHub Issues](https://github.com/yourusername/livecode-rpc-api/issues)
- [LiveCode Forums](https://forums.livecode.com)

## License

MIT - Free for commercial use.

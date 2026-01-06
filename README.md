# LiveCode Server RPC API Template

Build secure APIs with LiveCode Server using JWT authentication. Works with MySQL, PostgreSQL, SQLite.

## What It Is

**4 files to build a complete API:**

1. **photon-library.lc** - JSON parsing
2. **db-functions.lc** - Database, JWT, and auth functions
3. **auth.lc** - Login endpoint (issues JWT tokens)
4. **resource-template.lc** - CRUD template (adapt for each database table)

Include one library, call functions, done.

## Quick Start

```bash
# 1. Copy files
cp templates/* /var/www/api/lib/
cp templates/auth.lc /var/www/api/
cp templates/resource-template.lc /var/www/api/products.lc

# 2. Customize for your table
sed -i 's/PLACEHOLDER/products/g' products.lc

# 3. Configure database (edit lib/db-functions.lc)
nano /var/www/api/lib/db-functions.lc

# 4. Test
curl http://localhost/api/products.lc?action=list
```

**That's it.**

## Installation

**Need LiveCode Server?**
- [Official Downloads](https://livecode.com/downloads/)
- [macOS Guide](https://forums.livecode.com/viewtopic.php?f=8&t=37853&p=222987#p222987) (forum post)
- [Ubuntu/nginx Complete Setup](docs/livecode-server-installation.md) (with MySQL & SSL)

**Database Setup:**  
[Database Schemas](docs/database-setup.md) for MySQL, PostgreSQL, SQLite

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
- ✅ Password hashing (database-portable)
- ✅ SQL injection prevention
- ✅ Works with MySQL, PostgreSQL, SQLite
- ✅ Just 2 library files (photon + db-functions)

## Structure

```
api/
├── lib/
│   ├── photon-library.lc
│   └── db-functions.lc
├── auth.lc
├── products.lc
└── users.lc
```

One file per database table.

## Configuration

**Database (db-functions.lc line 22):**
```livecode
put "localhost" into tHost
put "mydb" into tDatabase
put "user" into tUser
put "pass" into tPassword
```

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

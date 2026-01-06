# RPC-Style API Architecture for LiveCode Server

Complete architectural guide for building production-ready APIs with LiveCode Server.

## Table of Contents

1. [Core Concept](#core-concept)
2. [Request/Response Pattern](#requestresponse-pattern)
3. [File Structure](#file-structure)
4. [Endpoint Anatomy](#endpoint-anatomy)
5. [Database Layer](#database-layer)
6. [Authentication](#authentication)
7. [Security](#security)
8. [Best Practices](#best-practices)

## Core Concept

### What is RPC-Style?

RPC (Remote Procedure Call) style uses action parameters to specify operations instead of HTTP methods and resource paths.

**Traditional RPC:**
```
GET /products.lc?action=list
GET /products.lc?action=read&id=123
POST /products.lc?action=create
```

**vs REST:**
```
GET /products
GET /products/123
POST /products
```

### Why RPC for LiveCode Server?

1. **Simpler**: No URL rewriting or routing needed
2. **Natural fit**: Works perfectly with LiveCode's structure
3. **One file per resource**: Easy to maintain
4. **Clear intent**: Action parameter makes operations obvious
5. **Flexible**: Easy to add custom actions beyond CRUD

## Request/Response Pattern

### Request Format

**GET Requests:**
```
GET /products.lc?action=list&limit=50
GET /products.lc?action=read&id=123
GET /products.lc?action=search&keyword=test
```

**POST Requests:**
```
POST /products.lc?action=create
Content-Type: application/json
Authorization: Bearer {token}

{
  "name": "Product Name",
  "description": "Description"
}
```

### Response Format

All responses use consistent JSON structure via PhotonJSON:

**Success:**
```json
{
  "status": "success",
  "data": {
    "id": 123,
    "name": "Product"
  }
}
```

**Error:**
```json
{
  "status": "error",
  "message": "Product not found"
}
```

**List:**
```json
{
  "status": "success",
  "data": [
    {"id": 1, "name": "Product 1"},
    {"id": 2, "name": "Product 2"}
  ]
}
```

### LiveCode Response Helpers

```livecode
-- Success response
function jsonSuccess pData
  put pData into tResult["data"]
  put "success" into tResult["status"]
  return JSONStringify(tResult)
end jsonSuccess

-- Error response
function jsonError pMessage
  put pMessage into tResult["message"]
  put "error" into tResult["status"]
  return JSONStringify(tResult)
end jsonError
```

## File Structure

### Recommended Layout

```
api/
├── lib/
│   ├── photon-library.lc         # PhotonJSON for JSON handling
│   ├── db-functions.lc            # Database connection & utilities
│   ├── auth-helpers.lc            # Authentication helpers
│   └── jwt-functions.lc           # JWT token management
├── products.lc                    # Products resource endpoint
├── orders.lc                      # Orders resource endpoint
├── users.lc                       # Users resource endpoint
├── auth.lc                        # Authentication endpoint
└── search.lc                      # Cross-resource search
```

### Library Files

**photon-library.lc** - JSON parsing/generation
**db-functions.lc** - Database utilities
**auth-helpers.lc** - JWT validation
**jwt-functions.lc** - JWT creation/verification

## Endpoint Anatomy

### Complete Endpoint Structure

```livecode
<?lc
-- Products CRUD API
include "lib/db-functions.lc"
include "lib/auth-helpers.lc"

on startup
  -- Set JSON header
  put header "Content-Type: application/json"
  
  -- Get parameters
  put $_GET["action"] into tAction
  put $_GET["id"] into tID
  put $_POST_RAW into tPostData
  
  -- Database connection
  put dbConnect() into tConnectionID
  if tConnectionID begins with "ERROR:" then
    put jsonError(tConnectionID)
    exit startup
  end if
  
  -- Authentication check
  if tAction is in "create,update,delete" then
    put getAuthToken() into tToken
    put validateJWT(tToken) into tAuthResult
    
    if tAuthResult["valid"] is not true then
      put jsonError("Authentication required")
      exit startup
    end if
    
    put tAuthResult["username"] into tUsername
  end if
  
  -- Route to handler
  switch tAction
    case "list"
      put handleList(tConnectionID) into tResponse
      break
    case "create"
      put handleCreate(tConnectionID, tPostData, tUsername) into tResponse
      break
    default
      put jsonError("Invalid action") into tResponse
  end switch
  
  -- Cleanup and respond
  revCloseDatabase tConnectionID
  put tResponse
end startup

startup

-- Handler functions below...
?>
```

### Standard Actions

| Action | HTTP Method | Parameters | Description |
|--------|-------------|------------|-------------|
| list | GET | limit, offset | Get all records |
| read | GET | id | Get single record |
| create | POST | JSON body | Create record |
| update | POST | JSON body | Update record |
| delete | GET/POST | id | Delete record |

### Custom Actions

Add domain-specific operations:

```livecode
case "by_status"
  put $_GET["status"] into tStatus
  put handleByStatus(tConnectionID, tStatus) into tResponse
  break

case "search"
  put $_GET["keyword"] into tKeyword
  put handleSearch(tConnectionID, tKeyword) into tResponse
  break

case "summary"
  put handleSummary(tConnectionID) into tResponse
  break
```

## Database Layer

### Connection Management

```livecode
function dbConnect
  put "localhost" into tHost
  put "database_name" into tDatabase
  put "db_user" into tUser
  put "db_password" into tPassword
  
  put revOpenDatabase("mysql", tHost, tDatabase, tUser, tPassword) into tConnectionID
  
  if tConnectionID is a number then
    return tConnectionID
  else
    return "ERROR: Database connection failed -" && tConnectionID
  end if
end dbConnect
```

### Query Execution

```livecode
-- Get data
put "SELECT * FROM products" into tSQL
put revDataFromQuery(tab, return, tConnectionID, tSQL) into tData

-- Execute command
put "INSERT INTO products (name) VALUES ('test')" into tSQL
revExecuteSQL tConnectionID, tSQL

-- Get last insert ID
put revDatabaseColumnNumbered(tConnectionID, "SELECT LAST_INSERT_ID()") into tID

-- Close connection
revCloseDatabase tConnectionID
```

### SQL Injection Prevention

Always escape user input:

```livecode
function sqlEscape pString
  replace "\" with "\\" in pString
  replace "'" with "\'" in pString
  replace quote with "\" & quote in pString
  replace return with "\n" in pString
  replace tab with "\t" in pString
  return pString
end sqlEscape

-- Usage:
put sqlEscape(tUserInput) into tSafe
put "SELECT * FROM products WHERE name = '" & tSafe & "'" into tSQL
```

### Data Conversion

Convert tab-delimited database results to arrays:

```livecode
-- Query returns tab-delimited rows
put revDataFromQuery(tab, return, tConnectionID, tSQL) into tData

-- Convert to array
put 1 into tIndex
repeat for each line tLine in tData
  split tLine by tab
  
  put tLine[1] into tResults[tIndex]["id"]
  put tLine[2] into tResults[tIndex]["name"]
  
  add 1 to tIndex
end repeat

return jsonSuccess(tResults)
```

## Authentication

### JWT Token Flow

1. **Login** - User provides credentials
2. **Validate** - Check username/password against database
3. **Generate JWT** - Create signed token with expiration
4. **Return Token** - Client stores token
5. **Authenticated Request** - Client sends token in header
6. **Validate Token** - Verify signature and expiration
7. **Process Request** - Execute if valid

### JWT Implementation

**Create Token:**
```livecode
-- In auth.lc login handler
put tData["user_id"] into tPayload["user_id"]
put tData["username"] into tPayload["username"]
put tData["name"] into tPayload["name"]

put createJWT(tPayload) into tToken

put tToken into tResult["token"]
return jsonSuccess(tResult)
```

**Validate Token:**
```livecode
-- In protected endpoint
put getAuthToken() into tToken
put validateJWT(tToken) into tAuthResult

if tAuthResult["valid"] is not true then
  put jsonError("Authentication required")
  exit startup
end if

put tAuthResult["username"] into tUsername
```

### Token Structure

JWT tokens have three parts separated by dots:

```
header.payload.signature
```

**Header:**
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Payload:**
```json
{
  "user_id": 123,
  "username": "admin",
  "name": "Administrator",
  "iat": 1609459200,
  "exp": 1609460000
}
```

**Signature:**
HMAC-SHA256 hash of header and payload using secret key.

### Authorization Header

Clients include token in requests:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

LiveCode extracts it:

```livecode
function getAuthToken
  put $_SERVER["HTTP_AUTHORIZATION"] into tAuthHeader
  
  if tAuthHeader begins with "Bearer " then
    put char 8 to -1 of tAuthHeader into tToken
    return tToken
  end if
  
  return empty
end getAuthToken
```

## Security

### Input Validation

Always validate user input:

```livecode
function handleCreate pConnectionID, pPostData, pUsername
  put JSONParser(pPostData) into tData
  
  -- Validate required fields
  if tData["name"] is empty then
    return jsonError("Name required")
  end if
  
  -- Validate data types
  if tData["price"] is not a number then
    return jsonError("Price must be a number")
  end if
  
  -- Validate ranges
  if tData["quantity"] < 0 then
    return jsonError("Quantity must be positive")
  end if
  
  -- Continue with creation...
end handleCreate
```

### Password Security

Use SHA2 for password hashing:

```livecode
-- Hash password
put SHA2(pPassword, 256) into tHash

-- Store hash in database
put "INSERT INTO users (username, password_hash)" into tSQL
put " VALUES ('" & sqlEscape(tUsername) & "', '" & tHash & "')" after tSQL
revExecuteSQL tConnectionID, tSQL

-- Verify password
put SHA2(pSubmittedPassword, 256) into tSubmittedHash
if tSubmittedHash is tStoredHash then
  -- Password correct
end if
```

For enhanced security, use salted passwords (see ECHOindications example).

### HTTPS in Production

Always use HTTPS in production:

1. Obtain SSL certificate
2. Configure web server for HTTPS
3. Redirect HTTP to HTTPS
4. Set secure cookie flags if using sessions

### Rate Limiting

Implement basic rate limiting:

```livecode
-- Store attempts in database or file
put "SELECT COUNT(*) FROM login_attempts" into tSQL
put " WHERE ip_address = '" & $_SERVER["REMOTE_ADDR"] & "'" after tSQL
put " AND attempt_time > DATE_SUB(NOW(), INTERVAL 1 HOUR)" after tSQL

put revDatabaseColumnNumbered(tConnectionID, tSQL) into tAttempts

if tAttempts > 10 then
  return jsonError("Too many attempts. Try again later.")
end if
```

### Audit Trail

Log all database modifications:

```livecode
-- After successful update
put sqlEscape(pUsername) into tSafeUser
put sqlEscape(JSONStringify(tOldData)) into tOldJSON
put sqlEscape(JSONStringify(tNewData)) into tNewJSON

put "INSERT INTO audit (audit_user, audit_table, audit_primarykey," into tSQL
put " action, old_values, new_values)" after tSQL
put " VALUES ('" & tSafeUser & "', 'products'," && tID & "," after tSQL
put " 'update', '" & tOldJSON & "', '" & tNewJSON & "')" after tSQL

revExecuteSQL tConnectionID, tSQL
```

## Best Practices

### Error Handling

Consistent error responses:

```livecode
-- Database error
if tData begins with "revdberr" then
  return jsonError("Database error: " & tData)
end if

-- Not found
if tData is empty then
  return jsonError("Product not found")
end if

-- Validation error
if tData["name"] is empty then
  return jsonError("Name required")
end if
```

### Code Organization

One handler per operation:

```livecode
function handleList pConnectionID, pLimit
  -- Query database
  -- Convert to array
  -- Return success
end handleList

function handleCreate pConnectionID, pPostData, pUsername
  -- Parse input
  -- Validate
  -- Insert to database
  -- Log audit
  -- Return success
end handleCreate
```

### Naming Conventions

- Endpoints: lowercase, plural nouns (`products.lc`, `orders.lc`)
- Actions: lowercase, descriptive (`list`, `by_status`, `search`)
- Functions: camelCase with verb prefix (`handleList`, `validateInput`)
- Variables: camelCase with type prefix (`tConnectionID`, `pUserData`)

### Performance

**Use connection pooling** (if available in your environment)

**Limit query results:**
```livecode
put " LIMIT 100" after tSQL
```

**Use indexes:**
```sql
CREATE INDEX idx_status ON products(status);
CREATE INDEX idx_created_at ON products(created_at);
```

**Cache frequently accessed data** (implement as needed)

### Testing

Test all endpoints:

```bash
# List
curl "http://localhost/api/products.lc?action=list"

# Read
curl "http://localhost/api/products.lc?action=read&id=1"

# Create
curl -X POST "http://localhost/api/products.lc?action=create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test"}'
```

### Documentation

Document your endpoints:

```livecode
-- Products CRUD API
-- 
-- Actions:
--   list: Get all products
--   read: Get single product by ID
--   create: Create new product (requires auth)
--   update: Update existing product (requires auth)
--   delete: Delete product (requires auth)
--   search: Search products by keyword
--   by_status: Filter by status (active, inactive, pending)
```

## Advanced Patterns

### Pagination

```livecode
put $_GET["limit"] into tLimit
put $_GET["offset"] into tOffset
if tLimit is empty then put 50 into tLimit
if tOffset is empty then put 0 into tOffset

put "SELECT * FROM products" into tSQL
put " ORDER BY created_at DESC" after tSQL
put " LIMIT" && tLimit && "OFFSET" && tOffset after tSQL
```

### Filtering

```livecode
put "SELECT * FROM products WHERE 1=1" into tSQL

if tStatus is not empty then
  put " AND status = '" & sqlEscape(tStatus) & "'" after tSQL
end if

if tCategory is not empty then
  put " AND category = '" & sqlEscape(tCategory) & "'" after tSQL
end if
```

### Sorting

```livecode
put $_GET["sort"] into tSort
put $_GET["order"] into tOrder

if tSort is empty then put "id" into tSort
if tOrder is empty then put "DESC" into tOrder

-- Whitelist allowed sort fields
if tSort is not in "id,name,created_at,updated_at" then
  put "id" into tSort
end if

-- Validate order
if tOrder is not in "ASC,DESC" then
  put "DESC" into tOrder
end if

put " ORDER BY" && tSort && tOrder after tSQL
```

## Next Steps

- Review [Quick Start Guide](QUICK-START.md) for setup
- Check [examples/](../examples/) for complete implementations
- Read [Security Guide](SECURITY.md) for best practices
- Explore PhotonJSON documentation for JSON handling

## Resources

- LiveCode Server Documentation: https://livecode.com/resources/documentation/
- LiveCode Forums: https://forums.livecode.com
- PhotonJSON: https://github.com/Ferruslogic/PhotonJSON/
- MySQL Documentation: https://dev.mysql.com/doc/

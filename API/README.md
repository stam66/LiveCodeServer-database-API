# Generic RPC API Endpoint Template

This template provides a reusable foundation for creating secure RPC (Remote Procedure Call) API endpoints with LiveCode Server. It includes authentication, security headers, rate limiting, and common CRUD operations.

## 🔄 RPC vs REST

This is an **RPC-style API**, not REST:
- **Action-based**: Uses `?action=` parameter to specify operations
- **Procedure-oriented**: Calls specific procedures/functions
- **Single endpoint per resource**: Each `.lc` file handles multiple actions
- **Query parameters**: Operations defined in URL params, not HTTP methods

**Example:**
```
/API/products.lc?action=list
/API/products.lc?action=read&id=5
/API/products.lc?action=create
```

**Benefits of RPC approach:**
- Natural fit for LiveCode Server
- Clear, explicit action names
- Easy to add custom actions beyond CRUD
- Simple testing (can use browser for GET requests)

## 📡 HTTP Methods in RPC APIs

### When to Use GET vs POST

**Use GET for:**
- **Read operations** (list, read, search)
- **Idempotent actions** (multiple calls produce same result)
- **Cacheable requests**
- **No sensitive data in request**

```bash
# GET examples
GET /API/products.lc?action=list
GET /API/products.lc?action=read&id=5
GET /API/products.lc?action=search&keyword=laptop
```

**Use POST for:**
- **Write operations** (create, update, delete)
- **Authentication** (credentials in body)
- **Non-idempotent actions** (each call may produce different results)
- **Sensitive data** (passwords, tokens, personal info)
- **Large payloads** (JSON body instead of URL params)

```bash
# POST examples
POST /API/products.lc?action=create
POST /API/products.lc?action=update
POST /API/auth.lc?action=login
```

**Why?**
- GET requests appear in browser history and server logs
- GET has URL length limits (usually 2048 chars)
- POST keeps data in request body (more secure, unlimited size)

## 📁 Template Files

- **`PLACEHOLDER.lc.example`** - Generic CRUD endpoint template
- **`audit.lc.example`** - Audit trail endpoint (optional but recommended)
- **`database/PLACEHOLDER_schema.sql.example`** - Database table schema template
- **`database/audit_schema.sql.example`** - Audit table schema (for audit logging)
- **Core library files** (no modification needed):
  - `lib/db-functions.lc` - Database, security, JWT, and rate limiting functions
  - `lib/photon-library.lc` - JSON parsing and serialization
  - `lib/settings.lc` - Database and JWT configuration (excluded from git)
  - `auth.lc` - Authentication endpoint with rate limiting

## 🚀 Quick Start

### 1. Set Up Database

```bash
# Copy and customize the schema template
cp API/database/PLACEHOLDER_schema.sql.example API/database/products_schema.sql

# Edit products_schema.sql:
# - Replace "placeholder_table" with "products"
# - Customize fields for your needs
# - Add indexes, foreign keys, etc.

# Run the schema
mysql -u your_user -p your_database < API/database/products_schema.sql
```

### 2. Create API Endpoint

```bash
# Copy the endpoint template
cp API/PLACEHOLDER.lc.example API/products.lc

# Edit products.lc:
# 1. Replace all "PLACEHOLDER" with "products"
# 2. Replace all "placeholder_table" with "products"
# 3. Update SQL SELECT columns to match your schema
# 4. Customize field mappings in each function
# 5. Remove unused actions (optional)
```

### 3. Configure Security

In your new endpoint file, choose your security model:

**Option A: All Actions Protected**
```livecode
on startup
  setSecurityHeaders
  put header "Content-Type: application/json"

  -- Require auth for ALL actions
  put requireAuth() into tAuthPayload

  -- ... rest of startup
end startup
```

**Option B: Selective Protection** (default in template)
```livecode
switch tAction
  case "list"
    -- PUBLIC
    put handleListProducts(tConnectionID) into tResponse
    break
  case "create"
    -- PROTECTED
    put requireAuth() into tAuthPayload
    put handleCreateProducts(tConnectionID, tPostData, tAuthPayload) into tResponse
    break
end switch
```

### 4. Test Your Endpoint

```bash
# Test GET endpoint (list - no auth needed)
curl -X GET https://your-domain.com/API/products.lc?action=list

# Test GET endpoint (read specific record)
curl -X GET https://your-domain.com/API/products.lc?action=read&id=5

# Test GET endpoint (search)
curl -X GET "https://your-domain.com/API/products.lc?action=search&keyword=laptop"

# Test POST endpoint (create - requires auth)
curl -X POST https://your-domain.com/API/products.lc?action=create \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"New Product","description":"Test","status":"active"}'

# Test POST endpoint (update - requires auth)
curl -X POST https://your-domain.com/API/products.lc?action=update \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id":5,"name":"Updated Product","status":"inactive"}'

# Test POST endpoint (delete - requires auth)
curl -X POST https://your-domain.com/API/products.lc?action=delete&id=5 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 📝 Customization Guide

### Common Modifications

#### 1. **Change Field Names**

In SQL queries, replace column names:
```livecode
-- Before (template):
put "SELECT id, name, description, status FROM placeholder_table" into tSQL

-- After (your table):
put "SELECT id, product_name, product_desc, inventory_status FROM products" into tSQL
```

Update field mappings:
```livecode
-- Before:
put tLine[2] into tRecords[tIndex]["name"]

-- After:
put tLine[2] into tRecords[tIndex]["product_name"]
```

#### 2. **Add Relationships (JOINs)**

```livecode
put "SELECT p.id, p.name, c.name as category_name" into tSQL
put " FROM products p" after tSQL
put " LEFT JOIN categories c ON p.category_id = c.id" after tSQL
put " WHERE p.is_active = 1" after tSQL
```

#### 3. **Add Custom Validation**

```livecode
function handleCreateProducts pConnectionID, pPostData, pAuthPayload
  -- ... existing validation ...

  -- Custom validation
  if tPrice < 0 then
    return jsonError("Price cannot be negative")
  end if

  if tQuantity is not a number then
    return jsonError("Quantity must be a number")
  end if

  -- ... rest of function
end handleCreateProducts
```

#### 4. **Add Custom Actions**

```livecode
switch tAction
  -- ... existing actions ...

  case "featured"
    -- Custom action: Get featured products
    put handleFeaturedProducts(tConnectionID) into tResponse
    break

  case "by_category"
    put $_GET["category_id"] into tCategoryID
    put handleProductsByCategory(tConnectionID, tCategoryID) into tResponse
    break
end switch

-- Add the handler functions
function handleFeaturedProducts pConnectionID
  put "SELECT * FROM products WHERE is_featured = 1 AND is_active = 1" into tSQL
  -- ... rest of function
end handleFeaturedProducts
```

#### 5. **Add Rate Limiting**

For sensitive actions:
```livecode
case "create"
  put requireAuth() into tAuthPayload

  -- Rate limit: 10 creations per minute
  put getClientIP() into tClientIP
  put checkRateLimit(tConnectionID, tClientIP, "product_create", 10, 60) into tRateLimitError

  if tRateLimitError is not empty then
    revCloseDatabase tConnectionID
    put header "Status: 429 Too Many Requests"
    return jsonError(tRateLimitError)
  end if

  put handleCreateProducts(tConnectionID, tPostData, tAuthPayload) into tResponse
  break
```

#### 6. **Add Audit Logging** (Recommended)

Track all data changes for compliance and debugging:

```bash
# 1. Set up audit table
cp API/database/audit_schema.sql.example API/database/audit_schema.sql
mysql -u your_user -p your_database < API/database/audit_schema.sql

# 2. Set up audit endpoint
cp API/audit.lc.example API/audit.lc
# No changes needed - it works as-is!

# 3. Integrate into your endpoints (after CREATE/UPDATE/DELETE)
```

**Example: Log after creating a product**
```livecode
function handleCreateProducts pConnectionID, pPostData, pAuthPayload
  -- ... create product code ...

  -- Log to audit table
  put "INSERT INTO audit (audit_user, audit_table, audit_primarykey, action, changed_fields)" into tAuditSQL
  put " VALUES ('" & sqlEscape(pAuthPayload["username"]) & "', 'products', " & tNewID & ", 'INSERT', 'name,description,price')" after tAuditSQL
  revExecuteSQL pConnectionID, tAuditSQL

  return jsonSuccess(tResult)
end handleCreateProducts
```

**Example: Log after updating**
```livecode
  -- Log to audit table
  put "INSERT INTO audit (audit_user, audit_table, audit_primarykey, action, changed_fields)" into tAuditSQL
  put " VALUES ('" & sqlEscape(tUsername) & "', 'products', " & tID & ", 'UPDATE', 'price,quantity')" after tAuditSQL
  revExecuteSQL pConnectionID, tAuditSQL
```

**Query audit logs:**
```bash
# Get recent activity
curl -X GET https://your-domain.com/API/audit.lc?action=recent&limit=50 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Get history for specific record
curl -X GET "https://your-domain.com/API/audit.lc?action=by_record&table=products&record_id=123" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Get all changes by user
curl -X GET "https://your-domain.com/API/audit.lc?action=by_user&username=admin&limit=100" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 🔐 Security Features (Built-in)

All endpoints include:

### ✅ Security Headers
- **X-Content-Type-Options**: Prevents MIME-sniffing
- **X-Frame-Options**: Prevents clickjacking
- **X-XSS-Protection**: Enables browser XSS protection
- **CORS**: Cross-origin resource sharing configured
- **CSP**: Content Security Policy

### ✅ SQL Injection Prevention
- `validateNumericID()` - Validates and sanitizes numeric IDs
- `sqlEscape()` - Escapes SQL special characters

### ✅ Authentication
- JWT-based authentication with HMAC-SHA256
- Constant-time password comparison (timing attack protection)
- Token expiration (default: 30 minutes)
- Salted password hashing with PBKDF2-like approach

### ✅ Rate Limiting
- IP-based rate limiting (configured per endpoint)
- Automatic cleanup of expired limits
- Proxy/load balancer support (X-Forwarded-For)

## 📚 API Response Format

### Success Response
```json
{
  "status": "success",
  "data": {
    "id": 123,
    "name": "Example",
    "created_at": "2026-01-12 10:30:00"
  }
}
```

### Error Response
```json
{
  "status": "error",
  "message": "Record not found"
}
```

### List Response
```json
{
  "status": "success",
  "data": [
    {"id": 1, "name": "Item 1"},
    {"id": 2, "name": "Item 2"}
  ]
}
```

## 🔧 Available Helper Functions

From `lib/db-functions.lc`:

### Database
- `dbConnect()` - Open database connection
- `revCloseDatabase(connectionID)` - Close connection

### Security
- `setSecurityHeaders()` - Set all security headers
- `requireAuth()` - Require JWT authentication
- `validateNumericID(id)` - Validate numeric ID
- `sqlEscape(string)` - Escape SQL strings

### Passwords
- `hashPassword(password, salt)` - Hash password with salt
- `verifyPassword(password, storedHash)` - Verify password (constant-time)
- `generateSalt()` - Generate random salt

### JWT
- `generateJWT(userID, username, name, [expiration])` - Create JWT token
- `verifyJWT(token)` - Verify and decode JWT
- `getJWTExpiration()` - Get token expiration time

### Rate Limiting
- `checkRateLimit(connID, ip, endpoint, maxAttempts, windowSeconds)` - Check rate limit
- `resetRateLimit(connID, ip, endpoint)` - Reset rate limit
- `getClientIP()` - Get client IP (handles proxies)

### JSON
- `jsonSuccess(data)` - Create success response
- `jsonError(message)` - Create error response
- `JSONParser(jsonString)` - Parse JSON (from photon-library)
- `JSONStringify(array)` - Convert to JSON (from photon-library)

## 📊 Example Projects

### Blog API
```bash
# Tables: posts, categories, comments
cp API/PLACEHOLDER.lc.example API/posts.lc
cp API/PLACEHOLDER.lc.example API/categories.lc
cp API/PLACEHOLDER.lc.example API/comments.lc

# Customize each endpoint for its specific fields
```

### E-commerce API
```bash
# Tables: products, orders, customers, cart
cp API/PLACEHOLDER.lc.example API/products.lc
cp API/PLACEHOLDER.lc.example API/orders.lc
cp API/PLACEHOLDER.lc.example API/customers.lc
```

### Task Management API
```bash
# Tables: tasks, projects, teams
cp API/PLACEHOLDER.lc.example API/tasks.lc
cp API/PLACEHOLDER.lc.example API/projects.lc
cp API/PLACEHOLDER.lc.example API/teams.lc
```

## 🌐 Deployment Checklist

Before deploying to production:

- [ ] Change `Access-Control-Allow-Origin: *` to specific domain
- [ ] Uncomment HSTS header if using HTTPS
- [ ] Set strong JWT secret (64+ chars)
- [ ] Configure rate limits per endpoint
- [ ] Test all CRUD operations
- [ ] Verify authentication works
- [ ] Check SQL injection protection
- [ ] Test with invalid inputs
- [ ] Enable audit logging (optional)
- [ ] Set up database backups
- [ ] Monitor rate_limit table size

## 📖 Additional Resources

- **LiveCode Server Docs**: https://livecode.com/resources/documentation/
- **MySQL Documentation**: https://dev.mysql.com/doc/
- **OWASP API Security**: https://owasp.org/www-project-api-security/
- **JWT Best Practices**: https://tools.ietf.org/html/rfc8725

## 🤝 Contributing

To improve this template:
1. Keep core library files generic and reusable
2. Add comments explaining customization points
3. Follow existing code style and patterns
4. Test with different database schemas
5. Document any new features in this README

## 📄 License

This template follows the same license as the ECHOindications-API project.

---

**Questions?** Open an issue or refer to the example implementations in the main project (indications.lc, users.lc, etc.).

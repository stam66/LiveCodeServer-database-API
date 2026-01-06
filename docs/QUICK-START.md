# Quick Start Guide - LiveCode Server RPC API

Get your LiveCode Server API running in minutes.

## Prerequisites

- LiveCode Server 9.0 or later installed
- MySQL database
- Web server (Apache/nginx) with LiveCode Server configured
- Command line access
- Text editor

## Step-by-Step Setup

### Step 1: Install LiveCode Server

**Prerequisites:**
- LiveCode Server installed and configured on your web server
- Web server configured to process .lc files through LiveCode Server

**Note:** LiveCode Server installation and web server configuration varies by platform. Refer to the official LiveCode Server documentation for detailed setup instructions specific to your environment.

### Step 2: Create Database

Choose your database type and run the appropriate SQL from `database-setup.md`:

- **MySQL** - Most common, good for production
- **PostgreSQL** - Advanced features, good for complex queries
- **SQLite** - Serverless, good for development/small deployments

**Quick MySQL Setup:**
```bash
mysql -u root -p < database-setup.md  # (copy MySQL section)
```

**Important:** The template uses LiveCode's `messageDigest()` for password hashing, not database-specific functions like `SHA2()`. This makes your code portable across all database types.

See `database-setup.md` for complete schema examples for all three databases.
```

### Step 3: Create Project Structure

Choose your API URL structure:

**Option 1: Subdomain** (e.g., `api.example.com`)
```bash
mkdir -p /var/www/api.example.com
cd /var/www/api.example.com
mkdir -p lib
```

**Option 2: Directory** (e.g., `example.com/api`)
```bash
mkdir -p /var/www/example.com/api
cd /var/www/example.com/api
mkdir -p lib
```

**Note:** If you're running other web applications on the same domain (like Xojo Web Apps), a subdomain approach may be cleaner to avoid routing conflicts.

Your structure should look like:
```
/var/www/api/  (or /var/www/api.example.com/)
├── lib/
│   ├── photon-library.lc
│   ├── db-functions.lc
│   ├── auth-helpers.lc
│   └── jwt-functions.lc
├── products.lc
└── auth.lc
```

### Step 4: Install Library Files

Copy the template files:

```bash
# Clone this repository
git clone https://github.com/stam66/LiveCodeServer-Database-API.git
cd livecode-rpc-api

# Copy library files (just 2 files!)
cp templates/photon-library.lc /var/www/api/lib/
cp templates/db-functions.lc /var/www/api/lib/

# Copy resource template
cp templates/resource-template.lc /var/www/api/products.lc

# Copy auth endpoint
cp templates/auth.lc /var/www/api/auth.lc
```

**Note:** `db-functions.lc` contains everything - database, JSON, JWT, and auth functions. No need for separate files!

### Step 5: Configure Database Connection

Edit `/var/www/api/lib/db-functions.lc`:

```livecode
function dbConnect
  put "localhost" into tHost
  put "myapp_api" into tDatabase       -- Your database name
  put "your_user" into tUser           -- Your database user
  put "your_password" into tPassword   -- Your database password
  
  -- Default: MySQL (uncomment the database you're using)
  put revOpenDatabase("mysql", tHost, tDatabase, tUser, tPassword) into tConnectionID
  -- put revOpenDatabase("postgresql", tHost, tDatabase, tUser, tPassword) into tConnectionID
  -- put revOpenDatabase("sqlite", tDatabase) into tConnectionID
  
  if tConnectionID is a number then
    return tConnectionID
  else
    return "ERROR: Database connection failed -" && tConnectionID
  end if
end dbConnect
```

**Note:** Template is configured for MySQL. To use PostgreSQL or SQLite, comment out MySQL line and uncomment your database.

### Step 6: Customize Products Endpoint

The template file contains the word `PLACEHOLDER` throughout as a placeholder for your actual table/resource name.

**Why PLACEHOLDER?** It makes it obvious what needs to be replaced. When you see `SELECT * FROM PLACEHOLDER`, you know to change it to your table name.

Edit `/var/www/api/products.lc` and replace `PLACEHOLDER` with `products`:

```bash
# Using sed (automatic replacement)
cd /var/www/api
sed -i 's/PLACEHOLDER/products/g' products.lc

# Or manually in your editor:
# Find: PLACEHOLDER
# Replace with: products
```

**What this does:**
- Changes `SELECT * FROM PLACEHOLDER` to `SELECT * FROM products`
- Changes `PLACEHOLDER created successfully` to `Product created successfully`
- Changes audit table references from `PLACEHOLDER` to `products`

### Step 7: Set File Permissions

```bash
# Make files readable by web server
chmod 644 /var/www/api/*.lc
chmod 644 /var/www/api/lib/*.lc

# Ensure directories are executable
chmod 755 /var/www/api
chmod 755 /var/www/api/lib
```

### Step 8: Test Database Connection

Create a test file `/var/www/api/test.lc`:

```livecode
<?lc
include "lib/db-functions.lc"

put header "Content-Type: text/plain"

put dbConnect() into tConnID

if tConnID begins with "ERROR:" then
  put "FAILED:" && tConnID
else
  put "SUCCESS: Connected with ID" && tConnID
  revCloseDatabase tConnID
end if
?>
```

Test it:
```bash
curl "http://localhost/api/test.lc"
```

Expected output:
```
SUCCESS: Connected with ID 1
```

If you get an error, check:
- Database credentials in db-functions.lc
- MySQL service is running
- User has proper permissions
- LiveCode Server can access MySQL

### Step 9: Test Products Endpoint

```bash
# List products (should be empty initially)
curl "http://localhost/api/products.lc?action=list"
```

Expected response:
```json
{
  "status": "success",
  "data": []
}
```

### Step 10: Create Your First Product

For testing, temporarily disable authentication in `products.lc`:

```livecode
-- Comment out the authentication check:
-- if tAction is in "create,update,delete" then
--   put getAuthToken() into tToken
--   ...
-- else
  put "admin" into tUsername
-- end if
```

Now create a product:

```bash
curl -X POST "http://localhost/api/products.lc?action=create" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "description": "My first product",
    "status": "active"
  }'
```

Expected response:
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "message": "Product created successfully"
  }
}
```

Verify it was created:
```bash
curl "http://localhost/api/products.lc?action=list"
```

### Step 11: Test Other Operations

**Read:**
```bash
curl "http://localhost/api/products.lc?action=read&id=1"
```

**Update:**
```bash
curl -X POST "http://localhost/api/products.lc?action=update" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "name": "Updated Product",
    "description": "Updated description",
    "status": "active"
  }'
```

**Search:**
```bash
curl "http://localhost/api/products.lc?action=search&keyword=test"
```

**Filter by status:**
```bash
curl "http://localhost/api/products.lc?action=by_status&status=active"
```

**Delete:**
```bash
curl "http://localhost/api/products.lc?action=delete&id=1"
```

## Adding Authentication

### Step 1: Create Authentication Endpoint

Copy the `auth.lc` file to your API directory:

```bash
cp auth.lc /var/www/api/auth.lc
chmod 644 /var/www/api/auth.lc
```

This endpoint handles login and JWT token generation.

### Step 1a: Create First User

Before testing login, create an admin user. Create a temporary script `/var/www/api/create-user.lc`:

```livecode
<?lc
include "lib/db-functions.lc"

put "admin" into tUsername
put "password123" into tPassword
put "Administrator" into tName

-- Hash password using LiveCode (works with any database)
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
  put "User created successfully"
else
  put "Error:" && the result
end if

revCloseDatabase tConnID
?>
```

Run it once:
```bash
curl "http://localhost/api/create-user.lc"
```

Delete it immediately for security:
```bash
rm /var/www/api/create-user.lc
```

### Step 2: Test Login

```bash
curl -X POST "http://localhost/api/auth.lc?action=login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "password123"
  }'
```

Expected response:
```json
{
  "status": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "username": "admin",
    "name": "Administrator"
  }
}
```

### Step 3: Enable Authentication in Products

Uncomment the authentication check in `products.lc`:

```livecode
if tAction is in "create,update,delete" then
  put getAuthToken() into tToken
  put validateJWT(tToken) into tAuthResult
  
  if tAuthResult["valid"] is not true then
    put jsonError("Authentication required")
    exit startup
  end if
  
  put tAuthResult["username"] into tUsername
else
  put empty into tUsername
end if
```

### Step 4: Test Authenticated Request

```bash
# Get token first
TOKEN=$(curl -X POST "http://localhost/api/auth.lc?action=login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password123"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Use token to create product
curl -X POST "http://localhost/api/products.lc?action=create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Authenticated Product"}'
```

## Common Issues

### "Database connection failed"

Check:
```bash
# MySQL is running
systemctl status mysql

# User has permissions
mysql -u your_user -p
SHOW GRANTS;

# Credentials in db-functions.lc are correct
```

### "File not found" or 404

Check:
```bash
# File exists
ls -l /var/www/api/products.lc

# Web server can access it
# Permissions are correct (644)

# LiveCode Server is configured
# Check Apache/nginx configuration
```

### "Invalid JSON"

Check:
```bash
# Content-Type header is set
# JSON is valid (use jsonlint.com)
# POST data is in request body, not query string
```

### "Token expired" or "Invalid signature"

Check:
```bash
# JWT secret key is same in jwt-functions.lc
# Token hasn't expired (default 30 minutes)
# Token is passed in Authorization header
```

## Next Steps

### Add More Resources

1. Copy resource template
2. Customize for your needs
3. Create database table
4. Test endpoints

```bash
cp templates/resource-template.lc /var/www/api/orders.lc
sed -i 's/RESOURCE/orders/g' /var/www/api/orders.lc
```

### Add Custom Actions

Edit your resource file and add cases:

```livecode
case "by_category"
  put $_GET["category"] into tCategory
  put handleByCategory(tConnectionID, tCategory) into tResponse
  break
```

### Implement Pagination

Add to `handleList`:

```livecode
put $_GET["offset"] into tOffset
if tOffset is empty then put 0 into tOffset

put " LIMIT" && pLimit && "OFFSET" && tOffset after tSQL
```

## Production Checklist

Before going live:

- [ ] Change JWT secret in jwt-functions.lc
- [ ] Move database credentials to secure config file
- [ ] Enable HTTPS (SSL certificate)
- [ ] Remove test.lc file
- [ ] Set proper file permissions (644)
- [ ] Enable authentication on all protected endpoints
- [ ] Test all endpoints thoroughly
- [ ] Set up error logging
- [ ] Configure backup procedures
- [ ] Set up monitoring
- [ ] Review audit trail implementation
- [ ] Test with production data
- [ ] Document your API endpoints
- [ ] Create user documentation

## Getting Help

- Check server error logs: `/var/log/apache2/error.log`
- Test with curl -v for verbose output
- Verify LiveCode Server is processing .lc files
- Review [Architecture Guide](ARCHITECTURE.md)
- Visit LiveCode Forums: https://forums.livecode.com

## What's Next?

- Read the [Architecture Guide](ARCHITECTURE.md) for deep understanding
- Review the [Security Guide](SECURITY.md) for best practices
- Check the [examples/](../examples/) directory for more complex implementations
- Explore advanced features like pagination, filtering, and search

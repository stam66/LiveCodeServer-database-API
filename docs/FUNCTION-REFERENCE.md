# Function Reference

Quick reference for all functions in the LiveCode Server RPC API Template.

## Database Functions

### dbConnect()
Connect to database.
```livecode
put dbConnect() into tConnectionID
if tConnectionID begins with "ERROR:" then
  return jsonError(tConnectionID)
end if
```
**Returns:** Connection ID or error string  
**Configure:** Edit database credentials in function

### sqlEscape(pString)
Escape string for SQL queries (prevents injection).
```livecode
put "O'Brien" into tName
put sqlEscape(tName) into tSafeName
-- Result: O\'Brien
```
**Parameters:** `pString` (String) - String to escape  
**Returns:** Escaped string

---

## JSON Response Functions

### jsonSuccess(pData)
Return success response with data.
```livecode
put "admin" into tUser["username"]
return jsonSuccess(tUser)
-- Returns: {"status":"success","data":{"username":"admin"}}
```
**Parameters:** `pData` (Any) - Data to return  
**Returns:** JSON string

### jsonError(pMessage)
Return error response.
```livecode
return jsonError("User not found")
-- Returns: {"status":"error","message":"User not found"}
```
**Parameters:** `pMessage` (String) - Error message  
**Returns:** JSON string

---

## JWT Functions

### generateJWT(pUserID, pUsername, pName, pExpiry)
Generate JWT token with user data (recommended).
```livecode
-- Simple usage with default 30-minute expiry
put generateJWT(123, "admin", "John Doe", 1800) into tToken

-- Custom expiry (in seconds)
put generateJWT(123, "admin", "John Doe", 3600) into tToken  -- 1 hour
```
**Parameters:**
- `pUserID` (Number) - User ID
- `pUsername` (String) - Username
- `pName` (String) - User's full name
- `pExpiry` (Number) - Optional: seconds until expiration (default: 1800)

**Returns:** JWT token string  
**Use:** Auth login endpoints (see `auth.lc`)

### createJWT(pPayload)
Create JWT token from payload array (advanced).
```livecode
put 123 into tPayload["user_id"]
put "admin" into tPayload["username"]
put "extra" into tPayload["custom_field"]
put createJWT(tPayload) into tToken
```
**Parameters:** `pPayload` (Array) - User data  
**Returns:** JWT token string  
**Note:** For custom payloads. Use `generateJWT()` for standard auth.

### verifyJWT(pToken)
Verify token signature and expiration.
```livecode
put verifyJWT(tToken) into tResult
if tResult begins with "ERROR:" then
  return jsonError(tResult)
end if
put tResult["user_id"] into tUserID
```
**Parameters:** `pToken` (String) - Token to verify  
**Returns:** Payload array or error string

---

## Authentication Functions

### validateJWT()
Validate token from Authorization header.
```livecode
put validateJWT() into tUser
if tUser begins with "ERROR:" then
  return jsonError(tUser)
end if
-- Token is valid, proceed
```
**Returns:** User data array or error string  
**Use:** Call at start of protected endpoints

### getAuthToken()
Extract token from Authorization header.
```livecode
put getAuthToken() into tToken
if tToken is empty then
  return jsonError("Authorization required")
end if
```
**Returns:** Token string or empty

---

## Configuration Functions

### getJWTSecret()
Get JWT signing secret.
```livecode
function getJWTSecret
  return "your-production-secret-min-32-chars"
end getJWTSecret
```
**Returns:** Secret string  
**⚠️ CRITICAL:** Change default in production!

### getJWTExpiration()
Get token lifetime in seconds.
```livecode
function getJWTExpiration
  return 1800  -- 30 minutes
end getJWTExpiration
```
**Returns:** Number of seconds

---

## Internal Functions

These are used internally by other functions:

### createSignature(pData, pSecret)
Create HMAC-SHA256 signature.  
**Used by:** `createJWT()`, `verifyJWT()`

### base64URLEncode(pData)
Base64URL encode data (URL-safe).  
**Used by:** `createJWT()`

### base64URLDecode(pData)
Base64URL decode data.  
**Used by:** `verifyJWT()`

---

## Usage Patterns

### Protected Endpoint Pattern
```livecode
include "lib/db-functions.lc"

on startup
  put header "Content-Type: application/json"
  
  -- Validate authentication
  put validateJWT() into tUser
  if tUser begins with "ERROR:" then
    put jsonError(tUser)
    exit startup
  end if
  
  -- User is authenticated, proceed
  put dbConnect() into tConnectionID
  -- ... do work ...
  put jsonSuccess(tData)
end startup
```

### Public Endpoint Pattern
```livecode
include "lib/db-functions.lc"

on startup
  put header "Content-Type: application/json"
  
  put dbConnect() into tConnectionID
  -- ... do work ...
  put jsonSuccess(tData)
end startup
```

### Error Handling Pattern
```livecode
put dbConnect() into tConnectionID
if tConnectionID begins with "ERROR:" then
  put jsonError(tConnectionID)
  exit startup
end if

put revDataFromQuery(tab, return, tConnectionID, tSQL) into tData
if tData begins with "revdberr" then
  revCloseDatabase tConnectionID
  put jsonError(tData)
  exit startup
end if

revCloseDatabase tConnectionID
return jsonSuccess(tResult)
```

---

## PhotonJSON Functions

External library for JSON parsing. See [GitHub](https://github.com/Ferruslogic/PhotonJSON/).

### JSONParser(pJsonString)
Parse JSON to LiveCode array.
```livecode
put $_POST_RAW into tJSON
put JSONParser(tJSON) into tData
put tData["username"] into tUsername
```
**Aliases:** `JSONToArray`, `arrayFromJson`

### JSONStringify(pArray)
Convert array to JSON.
```livecode
put "value" into tArray["key"]
put JSONStringify(tArray) into tJSON
-- Returns: {"key":"value"}
```
**Aliases:** `ArrayToJSON`, `jsonFromArray`

---

## LiveCode Server Database Functions

Built-in LiveCode functions for database access.

### revOpenDatabase(type, host, database, user, password)
```livecode
put revOpenDatabase("mysql", "localhost", "mydb", "user", "pass") into tID
```
**Types:** mysql, postgresql, sqlite, odbc

### revDataFromQuery(colDelim, rowDelim, connectionID, sql)
```livecode
put revDataFromQuery(tab, return, tConnectionID, tSQL) into tData
```
**Returns:** Delimited data or error string

### revExecuteSQL(connectionID, sql)
```livecode
revExecuteSQL tConnectionID, "INSERT INTO users ..."
```
**Returns:** Empty on success, error on failure

### revCloseDatabase(connectionID)
```livecode
revCloseDatabase tConnectionID
```

---

## Password Hashing Functions

### generateSalt()
Generate cryptographic random salt (32 hex characters).
```livecode
put generateSalt() into tSalt
-- Returns: "a3f9c82d1e5b7f..."
```
**Use:** Creating new user accounts

### hashPassword(pPassword, pSalt)
Hash password with salt using SHA256.
```livecode
put generateSalt() into tSalt
put hashPassword("mypassword", tSalt) into tHash
-- Store both tHash and tSalt in database
```
**Returns:** 64 character hex hash

### verifyPassword(pPassword, pStoredHash, pStoredSalt)
Verify password against stored hash and salt.
```livecode
if verifyPassword(tPassword, tStoredHash, tStoredSalt) then
  -- Password correct
end if
```
**Returns:** Boolean (true/false)

**Security:** Always use salted passwords. The `auth.lc` template handles automatic migration from unsalted to salted passwords on successful login.

---

## Input Validation Functions

### validateInteger(pValue)
Validate positive integer input (prevents SQL injection).
```livecode
put validateInteger($_GET["id"]) into tSafeID
if tSafeID is empty then
  return jsonError("Invalid ID")
end if

-- Safe to use in SQL
put "WHERE id = " & tSafeID after tSQL
```
**Returns:** Integer if valid, empty if invalid  
**Use:** All numeric IDs from user input

**Security:** ALWAYS validate integers before using in SQL queries, even if "supposed" to be numbers.

---

## Complete Example

```livecode
<?lc
include "lib/db-functions.lc"

on startup
  put header "Content-Type: application/json"
  
  -- Validate auth
  put validateJWT() into tUser
  if tUser begins with "ERROR:" then
    put jsonError(tUser)
    exit startup
  end if
  
  -- Connect to database
  put dbConnect() into tConnectionID
  if tConnectionID begins with "ERROR:" then
    put jsonError(tConnectionID)
    exit startup
  end if
  
  -- Query database
  put "SELECT * FROM products" into tSQL
  put revDataFromQuery(tab, return, tConnectionID, tSQL) into tData
  
  if tData begins with "revdberr" then
    revCloseDatabase tConnectionID
    put jsonError(tData)
    exit startup
  end if
  
  -- Parse results into array
  put 1 into tIndex
  repeat for each line tLine in tData
    split tLine by tab
    put tLine[1] into tProducts[tIndex]["id"]
    put tLine[2] into tProducts[tIndex]["name"]
    add 1 to tIndex
  end repeat
  
  -- Return success
  revCloseDatabase tConnectionID
  put jsonSuccess(tProducts)
end startup

startup
?>
```

---

## HTTP Variables

Built-in LiveCode Server variables:

- `$_GET["param"]` - URL query parameters
- `$_POST_RAW` - Raw POST body (for JSON)
- `$_SERVER["HTTP_AUTHORIZATION"]` - Authorization header
- `$_SERVER["REQUEST_METHOD"]` - HTTP method

---

## Quick Reference

| Function | Purpose | Returns |
|----------|---------|---------|
| `dbConnect()` | Connect to database | Connection ID or error |
| `sqlEscape(str)` | Escape SQL string | Escaped string |
| `validateInteger(val)` | Validate positive integer | Integer or empty |
| `jsonSuccess(data)` | Success response | JSON string |
| `jsonError(msg)` | Error response | JSON string |
| `generateJWT(id, username, name, expiry)` | Create token | JWT string |
| `verifyJWT(token)` | Validate token | Payload or error |
| `validateJWT()` | Check header | User data or error |
| `getAuthToken()` | Extract token | Token or empty |
| `generateSalt()` | Create random salt | 32 hex chars |
| `hashPassword(pass, salt)` | Hash with salt | 64 hex chars |
| `verifyPassword(pass, hash, salt)` | Check password | Boolean |

---

**Need more details?** See the inline comments in `db-functions.lc` - every function is documented.

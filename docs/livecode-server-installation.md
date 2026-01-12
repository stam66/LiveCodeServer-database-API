# LiveCode Server API Setup on DigitalOcean Ubuntu with Nginx
## Complete Guide with MySQL Integration

## Prerequisites
- Ubuntu droplet with Nginx installed (tested on Ubuntu 24.04, Nginx 1.24.0)
- Existing domain with SSL (example: echoindications.org managed by Lifeboat)
- MySQL/MariaDB installed and running
- Root/sudo access
- SFTP client (Cyberduck, FileZilla, or command line)
- Optional but recommended: Commercial software - Lifeboat. Designed for Xojo web apps, but also sets up domains/SSL/database (MySQL or PostresSQL) without having to pay for this as an optional extra. Works very well with DigitalOcean droplets, and any other VPS.

---

## Part 1: SSL Certificate for API Subdomain

### Step 1: Add DNS Record
In your DNS provider, create an A record:
- **Type**: A
- **Name**: api
- **Value**: [your-droplet-ip]
- **TTL**: 300 (or automatic)

Wait 2-5 minutes for DNS propagation, then verify:
```bash
nslookup api.yourdomain.com
```

### Step 2: Expand SSL Certificate
```bash
sudo certbot --expand -d yourdomain.com -d www.yourdomain.com -d api.yourdomain.com
```

This adds the subdomain to your existing Let's Encrypt certificate.

Certbot will confirm:
```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/yourdomain.com/fullchain.pem
```

### Step 3: Remove Certbot's Auto-Added Configuration
**CRITICAL**: Certbot automatically adds `api.yourdomain.com` server blocks to your main site config. These must be removed to avoid conflicts.

Edit the main configuration:
```bash
# If using Lifeboat:
sudo nano /etc/nginx/lifeboat.d/yourdomain.com.vhost

# Or if standard setup:
sudo nano /etc/nginx/sites-available/yourdomain.com
```

Delete any server blocks that contain `server_name api.yourdomain.com` (there will be two: one for HTTP port 80, one for HTTPS port 443).

Keep only the original yourdomain.com and www.yourdomain.com blocks.

Save, test, and reload Nginx:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## Part 2: Install LiveCode Server

### Step 1:  
**Download LiveCode Server**
The last open source version of LiveCode Server was 9.6.3:
Linux: https://archive.org/download/live-code-community-server-for-linux-all-versions/Linux%2064-Bit/LiveCodeCommunityServer-9_6_3-Linux-x86_64.zip  
Windows: https://archive.org/download/livecode_20210906/Windows%2064-Bit/LiveCodeCommunityServer-9_6_3-Windows-x86_64.zip  
MacOS: https://archive.org/download/livecode_20210906_1814/LiveCodeCommunityServer-9_6_3-Mac.zip  

If you have a current subscription to LiveCode Create, download this from your login page.

Unzip the downloaded file locally to get a folder like `LiveCodeCreateServer` or `LiveCodeCommunityServer-9_6_3-Linux-x64`.

### Step 2: Upload to Server via SFTP

**Using Cyberduck (or other FTP client that can provide SFTP):**
1. Connect to your droplet via SFTP
   - Protocol: SFTP
   - Server: your-droplet-ip
   - Username: root
   - Password: (your password) or use SSH key
2. Navigate to `/tmp/`
3. Upload the entire unzipped LiveCode folder to `/tmp/`

**Using command line:**
```bash
scp -r /path/to/LiveCodeCreateServer root@your-droplet-ip:/tmp/
```

### Step 3: Install LiveCode Server
```bash
# Create installation directory
sudo mkdir -p /opt/livecode

# Copy all files to installation directory
sudo cp -r /tmp/LiveCodeCreateServer/* /opt/livecode/

# Make the server executable (filename may vary - check your version)
sudo chmod +x /opt/livecode/livecode-server
```

Verify installation:
```bash
ls -lh /opt/livecode/livecode-server
```

Should show: `-rwxr-xr-x 1 root root 20M` (executable permissions and ~20MB size)

### Step 4: Make Database Drivers and Externals Executable

**CRITICAL STEP** - Without this, MySQL connections will fail!

LiveCode Server requires all drivers and external libraries to be executable:

```bash
# Make directories executable
sudo chmod 755 /opt/livecode/drivers
sudo chmod 755 /opt/livecode/externals

# Make all database drivers executable
sudo chmod 755 /opt/livecode/drivers/dbmysql.so
sudo chmod 755 /opt/livecode/drivers/dbodbc.so
sudo chmod 755 /opt/livecode/drivers/dbpostgresql.so
sudo chmod 755 /opt/livecode/drivers/dbsqlite.so

# Make all externals executable (revdb.so is critical for database access!)
sudo chmod 755 /opt/livecode/externals/revdb.so
sudo chmod 755 /opt/livecode/externals/mergJSON.so
sudo chmod 755 /opt/livecode/externals/mergMarkdown.so
sudo chmod 755 /opt/livecode/externals/revxml.so
sudo chmod 755 /opt/livecode/externals/revzip.so

# Make PDF printer executable
sudo chmod 755 /opt/livecode/revpdfprinter.so
```

Verify all files are executable:
```bash
ls -la /opt/livecode/drivers/
ls -la /opt/livecode/externals/
```

All `.so` files should show `-rwxr-xr-x`.

---

## Part 3: Install and Configure fcgiwrap

### Step 1: Install fcgiwrap
```bash
sudo apt install fcgiwrap -y
```

Verify it's running:
```bash
sudo systemctl status fcgiwrap.socket
```

Should show: `active (listening)`

Verify socket file exists:
```bash
ls -la /var/run/fcgiwrap.socket
```

Should show: `srw-rw---- 1 www-data www-data`

### Step 2: Create LiveCode CGI Wrapper Script
```bash
sudo nano /usr/local/bin/livecode-cgi-wrapper
```

Add this content:
```bash
#!/bin/bash
if [ -n "$PATH_TRANSLATED" ] && [ -f "$PATH_TRANSLATED" ]; then
    exec /opt/livecode/livecode-server "$PATH_TRANSLATED"
else
    echo "Error: Script file not found"
    exit 1
fi
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/livecode-cgi-wrapper
```

---

## Part 4: Configure Nginx for API Subdomain

### Step 1: Determine Which Directory Nginx Includes

**IMPORTANT**: Check your nginx.conf to see which directories are included:
```bash
sudo cat /etc/nginx/nginx.conf | grep include
```

Common configurations:
- **Lifeboat**: Includes `/etc/nginx/conf.d/*` and `/etc/nginx/lifeboat.d/*.vhost`
- **Standard Ubuntu**: Includes `/etc/nginx/sites-enabled/*`

**You must place your configuration in a directory that nginx.conf actually includes!**

For Lifeboat setups, use `/etc/nginx/conf.d/`.

### Step 2: Create API Directory
```bash
sudo mkdir -p /var/www/api
sudo mkdir -p /var/log/nginx/api.yourdomain.com
```

### Step 3: Create Nginx Configuration

**If nginx includes `/etc/nginx/conf.d/*` (Lifeboat and others):**
```bash
sudo nano /etc/nginx/conf.d/api.yourdomain.com.conf
```

**If nginx includes `/etc/nginx/sites-enabled/*` (Standard):**
```bash
sudo nano /etc/nginx/sites-available/api.yourdomain.com
sudo ln -s /etc/nginx/sites-available/api.yourdomain.com /etc/nginx/sites-enabled/
```

Add this content (adjust domain names):
```nginx
server {
    server_name api.yourdomain.com;
    listen 80;
    listen 443 ssl http2;
    
    # SSL certificate (same as main site)
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Document root for API files
    root /var/www/api;
    
    # Log files
    access_log /var/log/nginx/api.yourdomain.com/access.log;
    error_log /var/log/nginx/api.yourdomain.com/error.log;
    
    # Handle .lc and .irev files through fcgiwrap
    location ~ \.(lc|irev)$ {
        gzip off;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /usr/local/bin/livecode-cgi-wrapper;
        fastcgi_param PATH_TRANSLATED $document_root$fastcgi_script_name;
        fastcgi_pass unix:/var/run/fcgiwrap.socket;
    }
    
    # Default location
    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Step 4: Test and Reload Nginx
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## Part 5: Test LiveCode Server Installation

### Step 1: Create Simple Test Script
```bash
sudo nano /var/www/api/test.lc
```

Add this content:
```livecode
<?lc
put "{" & quote & "status" & quote & ":" & quote & "success" & quote & "," & quote & "message" & quote & ":" & quote & "LiveCode API is working!" & quote & "}"
?>
```

### Step 2: Test in Browser and Command Line

**Command line test:**
```bash
curl -i https://api.yourdomain.com/test.lc
```

Should return:
```
HTTP/2 200 
server: nginx/1.24.0 (Ubuntu)
content-type: text/html; charset=iso-8859-1

{"status":"success","message":"LiveCode API is working!"}
```

**Browser test:**
Visit `https://api.yourdomain.com/test.lc` - you should see the JSON.

### Important Note on Content-Type Header
The response will show `content-type: text/html` instead of `application/json`. This is a limitation of the fcgiwrap setup, but **does not affect functionality**. Xojo and LiveCode apps will parse the JSON correctly regardless of this header.

---

## Part 6: MySQL Database Connection

### Step 1: Verify MySQL is Running
```bash
sudo systemctl status mysql
# OR
sudo systemctl status mariadb
```

### Step 2: Find MySQL Socket Path (For Reference)

Although we'll use TCP connection, it's useful to know where the socket is:
```bash
mysqladmin -u your_username -p variables | grep socket
```

Typical location on Ubuntu: `/run/mysqld/mysqld.sock`

### Step 3: Verify MySQL TCP Port is Open
```bash
sudo netstat -tulpn | grep 3306
# OR
sudo ss -tulpn | grep 3306
```

Should show something like: `tcp  0  0  0.0.0.0:3306  0.0.0.0:*  LISTEN`

If not installed:
```bash
sudo apt install net-tools -y
```

### Step 4: Create Database Configuration File

**IMPORTANT**: Use TCP connection (IP address) instead of socket path for better compatibility.

```bash
sudo nano /var/www/api/db-config.lc
```

```livecode
<?lc
-- Database configuration via TCP
global gDBHost, gDBName, gDBUser, gDBPass

put "127.0.0.1" into gDBHost
put "your_database_name" into gDBName
put "your_mysql_username" into gDBUser
put "your_mysql_password" into gDBPass
?>
```

**Why TCP instead of socket?**
- More portable across different systems
- Avoids socket path variations between Linux distributions
- Works consistently with LiveCode Server's MySQL driver

### Step 5: Create Database Helper Functions

```bash
sudo nano /var/www/api/db-functions.lc
```

```livecode
<?lc
-- Database helper functions

-- Function to connect to database
function dbConnect
  -- Connection parameters directly in function
  put "127.0.0.1" into tHost
  put "your_database_name" into tDBName
  put "your_mysql_username" into tUser
  put "your_mysql_password" into tPass
  
  put revOpenDatabase("mysql", tHost, tDBName, tUser, tPass) into tConnectionID
  
  if tConnectionID is not a number then
    return "ERROR:" & tConnectionID
  end if
  
  return tConnectionID
end dbConnect

-- Function to return JSON error
function jsonError pMessage
  put "{" & quote & "status" & quote & ":" & quote & "error" & quote & "," into tJSON
  put quote & "message" & quote & ":" & quote & pMessage & quote & "}" after tJSON
  return tJSON
end jsonError

-- Function to return JSON success
function jsonSuccess pData
  put "{" & quote & "status" & quote & ":" & quote & "success" & quote & "," into tJSON
  put quote & "data" & quote & ":" & pData & "}" after tJSON
  return tJSON
end jsonSuccess

-- Function to escape SQL string (basic protection)
function sqlEscape pString
  replace "'" with "''" in pString
  replace "\" with "\\" in pString
  return pString
end sqlEscape
?>
```

### Step 6: Create Database Connection Test

```bash
sudo nano /var/www/api/db-test.lc
```

```livecode
<?lc
-- Include database functions
include "db-functions.lc"

-- Set JSON header
put "Content-Type: application/json" & return & return

-- Attempt database connection
try
  put dbConnect() into tConnectionID
  
  if tConnectionID begins with "ERROR:" then
    put jsonError(tConnectionID)
  else if tConnectionID is a number then
    -- Connection successful
    put "{" & quote & "status" & quote & ":" & quote & "success" & quote & "," into tResponse
    put quote & "message" & quote & ":" & quote & "MySQL connected successfully via TCP" & quote & "," after tResponse
    put quote & "connectionID" & quote & ":" & tConnectionID & "}" after tResponse
    put tResponse
    
    revCloseDatabase tConnectionID
  else
    put jsonError("Unexpected connection result")
  end if
  
catch tError
  put jsonError(tError)
end try
?>
```

### Step 7: Test MySQL Connection

```bash
curl -i https://api.yourdomain.com/db-test.lc
```

Expected successful response:
```json
{"status":"success","message":"MySQL connected successfully via TCP","connectionID":1}
```

If you get an error about socket path, verify:
1. Database drivers are executable (Part 2, Step 4)
2. Using TCP connection `127.0.0.1` not `localhost` (Part 6, Step 4)
3. MySQL is running and listening on port 3306 (Part 6, Step 3)

---

## Part 7: Create CRUD API Example (Users Table)

### Complete Working Example

```bash
sudo nano /var/www/api/users.lc
```

```livecode
<?lc
-- Users CRUD API

-- Include helper functions
include "db-functions.lc"

-- Main execution
on startup
  -- Set JSON header
  put "Content-Type: application/json" & return & return
  
  -- Get request parameters
  put $_GET["action"] into tAction
  put $_GET["id"] into tID
  put $_POST_RAW into tPostData
  
  -- Connect to database
  put dbConnect() into tConnectionID
  if tConnectionID begins with "ERROR:" then
    put jsonError(tConnectionID)
    exit startup
  end if
  
  -- Route to appropriate action
  switch tAction
    case "read"
      put handleReadUser(tConnectionID, tID) into tResponse
      break
    case "list"
      put handleListUsers(tConnectionID) into tResponse
      break
    case "delete"
      put handleDeleteUser(tConnectionID, tID) into tResponse
      break
    default
      put jsonError("Invalid action. Use: read, list, delete") into tResponse
  end switch
  
  revCloseDatabase tConnectionID
  put tResponse
end startup

startup

-- Handler Functions

function handleListUsers pConnectionID
  put "SELECT id, username, email, is_active, title, name, created_at FROM users WHERE is_active = 1 ORDER BY name" into tSQL
  put revDataFromQuery(tab, return, pConnectionID, tSQL) into tData
  
  if tData begins with "revdberr" then
    return jsonError(tData)
  end if
  
  -- CRITICAL: Set itemDelimiter to tab for parsing MySQL results
  put the itemDelimiter into tOldDelim
  set the itemDelimiter to tab
  
  -- Convert to JSON array
  put "[" into tJSON
  put 0 into tCount
  repeat for each line tLine in tData
    if tCount > 0 then put "," after tJSON
    put "{" after tJSON
    put quote & "id" & quote & ":" & item 1 of tLine & "," after tJSON
    put quote & "username" & quote & ":" & quote & sqlEscape(item 2 of tLine) & quote & "," after tJSON
    put quote & "email" & quote & ":" & quote & sqlEscape(item 3 of tLine) & quote & "," after tJSON
    put quote & "is_active" & quote & ":" & item 4 of tLine & "," after tJSON
    put quote & "title" & quote & ":" & quote & sqlEscape(item 5 of tLine) & quote & "," after tJSON
    put quote & "name" & quote & ":" & quote & sqlEscape(item 6 of tLine) & quote & "," after tJSON
    put quote & "created_at" & quote & ":" & quote & sqlEscape(item 7 of tLine) & quote after tJSON
    put "}" after tJSON
    add 1 to tCount
  end repeat
  put "]" after tJSON
  
  -- Restore original delimiter
  set the itemDelimiter to tOldDelim
  
  return jsonSuccess(tJSON)
end handleListUsers

function handleReadUser pConnectionID, pID
  if pID is empty then
    return jsonError("User ID required")
  end if
  
  put "SELECT id, username, email, is_active, title, name, created_at FROM users WHERE id =" && pID into tSQL
  put revDataFromQuery(tab, return, pConnectionID, tSQL) into tData
  
  if tData begins with "revdberr" or tData is empty then
    return jsonError("User not found")
  end if
  
  -- CRITICAL: Set itemDelimiter to tab
  put the itemDelimiter into tOldDelim
  set the itemDelimiter to tab
  
  -- Convert to JSON object
  put "{" into tJSON
  put quote & "id" & quote & ":" & item 1 of tData & "," after tJSON
  put quote & "username" & quote & ":" & quote & sqlEscape(item 2 of tData) & quote & "," after tJSON
  put quote & "email" & quote & ":" & quote & sqlEscape(item 3 of tData) & quote & "," after tJSON
  put quote & "is_active" & quote & ":" & item 4 of tData & "," after tJSON
  put quote & "title" & quote & ":" & quote & sqlEscape(item 5 of tData) & quote & "," after tJSON
  put quote & "name" & quote & ":" & quote & sqlEscape(item 6 of tData) & quote & "," after tJSON
  put quote & "created_at" & quote & ":" & quote & sqlEscape(item 7 of tData) & quote after tJSON
  put "}" after tJSON
  
  -- Restore original delimiter
  set the itemDelimiter to tOldDelim
  
  return jsonSuccess(tJSON)
end handleReadUser

function handleDeleteUser pConnectionID, pID
  if pID is empty then
    return jsonError("User ID required")
  end if
  
  -- Soft delete - set is_active = 0
  put "UPDATE users SET is_active = 0, updated_at = NOW() WHERE id =" && pID into tSQL
  revExecuteSQL pConnectionID, tSQL
  
  if the result is not empty then
    return jsonError(the result)
  else
    return jsonSuccess(quote & "User deactivated successfully" & quote)
  end if
end handleDeleteUser
?>
```

### Test the Users API

```bash
# List all users
curl -i "https://api.yourdomain.com/users.lc?action=list"

# Get specific user
curl -i "https://api.yourdomain.com/users.lc?action=read&id=1"

# Delete user (soft delete - sets is_active = 0)
curl -i "https://api.yourdomain.com/users.lc?action=delete&id=5"
```

Expected successful list response:
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "is_active": 1,
      "title": "Administrator",
      "name": "Admin User",
      "created_at": "2025-11-29 01:22:57"
    }
  ]
}
```

---

## Summary of Key Files and Locations

| Item | Location |
|------|----------|
| LiveCode Server executable | `/opt/livecode/livecode-server` |
| Database drivers | `/opt/livecode/drivers/*.so` (must be executable!) |
| Database externals | `/opt/livecode/externals/revdb.so` (must be executable!) |
| CGI wrapper script | `/usr/local/bin/livecode-cgi-wrapper` |
| API files (.lc scripts) | `/var/www/api/` |
| Nginx API configuration | `/etc/nginx/conf.d/api.yourdomain.com.conf` (or sites-enabled) |
| Main site config (Lifeboat) | `/etc/nginx/lifeboat.d/yourdomain.com.vhost` |
| SSL certificates | `/etc/letsencrypt/live/yourdomain.com/` |
| API logs | `/var/log/nginx/api.yourdomain.com/` |
| fcgiwrap socket | `/var/run/fcgiwrap.socket` |

---

## Critical Success Factors

### 1. Make Database Drivers Executable
**Problem**: MySQL connections fail with socket errors even when using TCP.  
**Solution**: All `.so` files in `/opt/livecode/drivers/` and `/opt/livecode/externals/` must be executable.
```bash
sudo chmod 755 /opt/livecode/drivers/*.so
sudo chmod 755 /opt/livecode/externals/*.so
```

### 2. Use TCP Connection for MySQL
**Problem**: Socket path varies across Linux distributions.  
**Solution**: Use `127.0.0.1` (TCP) instead of `localhost` (socket) in database connections.
```livecode
put "127.0.0.1" into tHost  -- Good
put "localhost" into tHost  -- Problematic
```

### 3. Set itemDelimiter When Parsing Data
**Problem**: MySQL results are tab-delimited, but LiveCode defaults to comma delimiter.  
**Solution**: Always set itemDelimiter to tab before parsing database results.
```livecode
put the itemDelimiter into tOldDelim
set the itemDelimiter to tab
-- ... parse items ...
set the itemDelimiter to tOldDelim
```

### 4. Place Config in Correct Nginx Directory
**Problem**: Configuration file exists but isn't loaded by Nginx.  
**Solution**: Check `nginx.conf` to see which directories are included, then place your config there.
```bash
sudo cat /etc/nginx/nginx.conf | grep include
```

### 5. Remove Certbot Auto-Generated Configs
**Problem**: API subdomain proxies to main app instead of LiveCode.  
**Solution**: After running `certbot --expand`, remove the auto-added api subdomain blocks from main site config.

---

## Troubleshooting

### MySQL Connection Fails with Socket Error
**Symptom**: Error mentions `/tmp/mysql.sock` even when using `127.0.0.1`

**Solutions**:
1. Verify drivers are executable:
   ```bash
   ls -la /opt/livecode/drivers/dbmysql.so
   ls -la /opt/livecode/externals/revdb.so
   ```
   Both should show `-rwxr-xr-x`

2. Verify using TCP connection:
   ```bash
   grep "127.0.0.1" /var/www/api/db-functions.lc
   ```

3. Verify MySQL is listening on TCP:
   ```bash
   sudo netstat -tulpn | grep 3306
   ```

### Blank Page or 404 Error
**Solutions**:
1. Check config file is in included directory:
   ```bash
   sudo nginx -T | grep "api.yourdomain.com"
   ```

2. Verify DNS is resolving:
   ```bash
   nslookup api.yourdomain.com
   ```

3. Check file permissions:
   ```bash
   ls -la /var/www/api/*.lc
   ```

4. Check Nginx error logs:
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

### Script Syntax Errors
**Solutions**:
1. Test script directly:
   ```bash
   /opt/livecode/livecode-server /var/www/api/yourscript.lc
   ```

2. Common issues:
   - Functions must be declared at script level, not inside `<?lc ?>` tags
   - Use `on startup` / `end startup` for main execution
   - Always call `startup` after defining functions

### Data Not Parsing Correctly
**Symptom**: All fields concatenated or in wrong positions

**Solution**: Set itemDelimiter to tab before parsing:
```livecode
put the itemDelimiter into tOldDelim
set the itemDelimiter to tab
-- parse items here
set the itemDelimiter to tOldDelim
```

### fcgiwrap Not Starting
**Solutions**:
1. Check socket status:
   ```bash
   sudo systemctl status fcgiwrap.socket
   ```

2. Restart if needed:
   ```bash
   sudo systemctl restart fcgiwrap.socket
   sudo systemctl enable fcgiwrap.socket
   ```

3. Verify socket file:
   ```bash
   ls -la /var/run/fcgiwrap.socket
   ```

---

## Calling the API from Xojo

### Basic Example (Desktop/Web/Mobile)

```xojo
// Create URLConnection
Dim socket As New URLConnection

// Set endpoint
socket.URL = "https://api.yourdomain.com/users.lc?action=list"

// Make request
Dim response As String = socket.SendSync("GET")

// Parse JSON response
Dim json As New JSONItem(response)

If json.Value("status") = "success" Then
  // Get data array
  Dim data As JSONItem = json.Value("data")
  
  // Loop through results
  For i As Integer = 0 To data.Count - 1
    Dim user As JSONItem = data.ValueAt(i)
    
    Dim id As Integer = user.Value("id")
    Dim username As String = user.Value("username")
    Dim email As String = user.Value("email")
    
    // Use the data...
  Next
Else
  // Handle error
  Dim errorMsg As String = json.Value("message")
  MessageBox errorMsg
End If
```

### POST Request Example

```xojo
// Create URLConnection
Dim socket As New URLConnection
socket.URL = "https://api.yourdomain.com/users.lc?action=create"

// Create JSON data
Dim jsonData As New JSONItem
jsonData.Value("username") = "johndoe"
jsonData.Value("email") = "john@example.com"
jsonData.Value("name") = "John Doe"

// Set content type and send
socket.RequestHeader("Content-Type") = "application/json"
Dim response As String = socket.SendSync("POST", jsonData.ToString)

// Parse response
Dim result As New JSONItem(response)
If result.Value("status") = "success" Then
  MessageBox "User created successfully"
End If
```

---

## For Future Droplets

To replicate this setup on another droplet:

1. **Replace domain names**:
   - Change `yourdomain.com` to your actual domain
   - Change `api.yourdomain.com` to your chosen API subdomain

2. **Verify nginx.conf includes**:
   ```bash
   sudo cat /etc/nginx/nginx.conf | grep include
   ```
   Place configs in the correct directory

3. **Adjust database credentials**:
   - Update `/var/www/api/db-functions.lc` with actual MySQL credentials

4. **Check MySQL TCP port**:
   ```bash
   sudo netstat -tulpn | grep 3306
   ```
   Ensure MySQL is listening on TCP

5. **Remember the critical steps**:
   - Make `.so` files executable
   - Use TCP connection (`127.0.0.1`)
   - Set itemDelimiter to tab when parsing
   - Remove Certbot auto-added configs

---

## Security Considerations

1. **SQL Injection Protection**: The `sqlEscape()` function provides basic protection, but consider using parameterized queries for production

2. **API Authentication**: Add authentication/API key validation before processing requests

3. **Rate Limiting**: Consider adding rate limiting in Nginx configuration

4. **HTTPS Only**: Ensure all API traffic uses HTTPS

5. **Input Validation**: Validate all user inputs before processing

6. **Database Permissions**: Use a MySQL user with minimum required permissions

---

## Next Steps

With this foundation, you can:

1. **Create additional table endpoints**: Follow the users.lc pattern for other tables
2. **Add authentication**: Implement API keys or JWT tokens
3. **Implement full CRUD**: Add create and update operations with JSON parsing
4. **Add search functionality**: Create specialized search endpoints
5. **Optimize queries**: Add indexes and query optimization
6. **Add logging**: Implement request/error logging
7. **Deploy Xojo apps**: Connect Desktop, Web, and Mobile apps to your API

---

## Document Information

**Version**: 2.0  
**Last Updated**: December 27, 2024  
**Tested On**: 
- Ubuntu 24.04 LTS
- Nginx 1.24.0
- MySQL/MariaDB 10.x
- LiveCode Server 9.6.11
- With Lifeboat deployment system

**Changes from v1.0**:
- Added critical step for making database drivers executable
- Changed from socket to TCP connection for MySQL
- Added itemDelimiter fix for data parsing
- Added complete working CRUD example
- Added comprehensive troubleshooting section
- Added Xojo integration examples
- Clarified Nginx configuration directory selection
- Added security considerations

---

## Support and Resources

- **LiveCode Documentation**: https://livecode.com/resources/
- **LiveCode Forums**: https://forums.livecode.com/
- **Nginx Documentation**: https://nginx.org/en/docs/
- **Let's Encrypt**: https://letsencrypt.org/
- **Xojo Documentation**: https://documentation.xojo.com/

---

**This guide represents the complete, tested, working configuration for LiveCode Server API on DigitalOcean Ubuntu with Nginx, MySQL integration, and Xojo connectivity.**

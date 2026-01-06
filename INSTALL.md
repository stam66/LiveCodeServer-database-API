# Quick Install

## 1. Install LiveCode Server

Choose your platform:

- **Official:** [livecode.com/downloads](https://livecode.com/downloads/)
- **macOS:** [Forum Guide](https://forums.livecode.com/viewtopic.php?f=8&t=37853&p=222987#p222987)
- **Ubuntu/nginx:** [Complete Setup Guide](docs/livecode-server-installation.md)

## 2. Copy Template Files

```bash
# Copy to your API directory
cp templates/photon-library.lc /var/www/api/lib/
cp templates/db-functions.lc /var/www/api/lib/
cp templates/auth.lc /var/www/api/
cp templates/resource-template.lc /var/www/api/products.lc
```

## 3. Customize Resource

```bash
# Replace PLACEHOLDER with your table name
sed -i 's/PLACEHOLDER/products/g' /var/www/api/products.lc
```

## 4. Configure

Edit `/var/www/api/lib/db-functions.lc`:

**Database credentials (line 22):**
```livecode
put "localhost" into tHost
put "your_database" into tDatabase
put "your_user" into tUser
put "your_password" into tPassword
```

**JWT secret (line 63):**
```livecode
function getJWTSecret
  return "your-secure-secret-min-32-characters"
end getJWTSecret
```

## 5. Set Up Database

See [docs/database-setup.md](docs/database-setup.md) for schemas.

## 6. Test

```bash
# Login
curl -X POST http://localhost/api/auth.lc?action=login \
  -d '{"username":"admin","password":"password123"}'

# Get products
curl http://localhost/api/products.lc?action=list
```

## Done!

See [README.md](README.md) for API documentation.

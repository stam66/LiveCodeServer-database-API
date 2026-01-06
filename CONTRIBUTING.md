# Contributing to LiveCode Server RPC API Template

Thank you for considering contributing to this project! This guide will help you get started.

## Ways to Contribute

- **Bug Reports**: Found a bug? Open an issue with details
- **Feature Requests**: Have an idea? Share it in issues
- **Documentation**: Improve docs or add examples
- **Code**: Fix bugs or add new features

## Getting Started

1. **Fork the repository**
2. **Clone your fork**
   ```bash
   git clone https://github.com/stam66/LiveCodeServer-Database-API.git
   cd livecode-rpc-api
   ```
3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Guidelines

### Code Style

- **Indentation**: 2 spaces (LiveCode convention)
- **Naming**: Use camelCase for functions (handleListProducts)
- **Comments**: Document all public functions with parameters and returns
- **Line Length**: Keep lines under 100 characters when possible

### Function Documentation Format

```livecode
-- Brief description of function
-- Parameters:
--   pParam1 (Type) - Description
--   pParam2 (Type) - Description
-- Returns: Type - Description
-- Note: Any important notes
function myFunction pParam1, pParam2
  -- Implementation
end myFunction
```

### Testing

Before submitting:

1. **Test on actual LiveCode Server**
   ```bash
   # Test all CRUD operations
   curl http://localhost/api/products.lc?action=list
   curl http://localhost/api/products.lc?action=read&id=1
   # etc.
   ```

2. **Test with multiple databases**
   - MySQL
   - PostgreSQL (if possible)
   - SQLite (if possible)

3. **Test authentication**
   - Login with valid/invalid credentials
   - Access protected endpoints with/without token
   - Test expired tokens

### Documentation

When adding new features:

1. **Update FUNCTION-REFERENCE.md** - Add function documentation
2. **Update README.md** - Add to feature list if applicable
3. **Update QUICK-START.md** - Add setup steps if needed
4. **Add examples** - Show how to use new features

## Submitting Changes

1. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: description of feature"
   ```

2. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your fork and branch
   - Describe your changes clearly

### Pull Request Guidelines

**Title Format:**
- `Fix: Description` for bug fixes
- `Feature: Description` for new features
- `Docs: Description` for documentation
- `Refactor: Description` for code improvements

**Description Should Include:**
- What changed and why
- How to test the changes
- Screenshots (if UI-related)
- Breaking changes (if any)

## Code Review Process

1. Maintainers will review your PR
2. Address any requested changes
3. Once approved, maintainers will merge

## Feature Requests

**Before Creating:**
- Search existing issues to avoid duplicates
- Check if feature aligns with project goals

**When Creating:**
- Describe the problem you're solving
- Explain your proposed solution
- Provide use cases and examples

## Bug Reports

**Include:**
- LiveCode Server version
- Database type and version
- Operating system
- Steps to reproduce
- Expected vs actual behavior
- Error messages (if any)

**Example:**
```
**Environment:**
- LiveCode Server: 9.6.8
- Database: MySQL 8.0
- OS: Ubuntu 20.04

**Steps to Reproduce:**
1. Call /products.lc?action=list
2. Observe error in response

**Expected:** List of products
**Actual:** Error "revdberr..."
**Error Message:** [paste error]
```

## Questions?

- **General Questions**: Use GitHub Discussions
- **Bugs**: Open an Issue
- **Security Issues**: Email privately (see SECURITY.md)

## Development Setup

### Prerequisites

- LiveCode Server installed
- Web server (Apache or nginx)
- Database server
- curl for testing

### Local Development

1. **Set up test database**
   ```sql
   CREATE DATABASE test_api;
   -- Run schema from database-setup.md
   ```

2. **Configure test environment**
   ```bash
   cp templates/db-functions.lc /var/www/test-api/lib/
   # Edit database credentials
   ```

3. **Run tests**
   ```bash
   ./test.sh  # Run all endpoint tests
   ```

## Coding Principles

1. **Database Portable** - Use LiveCode functions, not database-specific
2. **Security First** - Always escape SQL, validate input
3. **Simple & Clear** - Readable code > clever code
4. **Well Documented** - Every function needs docs
5. **Error Handling** - Return helpful error messages

## License

By contributing, you agree that your contributions will be licensed under the Apache-2.0 License.

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for their contributions

Thank you for contributing! 🎉

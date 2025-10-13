# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: [your-security-email@example.com]

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

Please include the following information in your report:

- Type of issue (e.g. buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

## Security Measures

This project implements the following security measures:

### Authentication & Authorization
- JWT-based authentication with Spring Security
- Password hashing using BCrypt
- Role-based access control (RBAC)
- Secure HTTP-only cookies for token storage (frontend)

### API Security
- CORS configuration for allowed origins
- Rate limiting on authentication endpoints
- Input validation on all endpoints
- SQL injection prevention via JPA/Hibernate

### Data Protection
- Sensitive data encrypted in database
- Environment variables for secrets (never committed to Git)
- TLS/HTTPS enforced in production
- Secure headers configuration

### Infrastructure Security
- Docker container security best practices
- Database access restricted to backend only
- Regular dependency updates via Dependabot
- Automated security scanning in CI/CD

## Best Practices for Contributors

When contributing to this project, please follow these security best practices:

1. **Never commit secrets**: Use environment variables for all sensitive data
2. **Validate all inputs**: Implement proper validation for user inputs
3. **Use parameterized queries**: Prevent SQL injection vulnerabilities
4. **Update dependencies**: Keep all dependencies up to date
5. **Follow OWASP guidelines**: Familiarize yourself with OWASP Top 10
6. **Code review**: All PRs require review before merging
7. **Test security**: Write tests for authentication and authorization logic

## Dependency Security

We use the following tools to maintain dependency security:

- **Dependabot**: Automated dependency updates
- **npm audit**: Frontend dependency scanning
- **Maven dependency-check**: Backend dependency scanning
- **Snyk**: Continuous security monitoring (optional)

To check dependencies locally:

```bash
# Frontend
cd main_frontend/concert1
npm audit

# Backend
cd main_backend
mvn dependency-check:check
```

## Security Headers

The application implements the following security headers:

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- `Content-Security-Policy: default-src 'self'`

## Acknowledgments

We thank the security community for responsibly disclosing vulnerabilities. Security researchers who report valid vulnerabilities will be acknowledged in our release notes (with their permission).

# Security Rules

## Secrets Management

- **Never** hardcode secrets, API keys, tokens, or passwords in source code.
- **Never** commit `.env` files, credential files, or private keys.
- Use environment variables or a secrets manager (Vault, AWS Secrets Manager, etc.).
- Rotate secrets on a regular schedule and immediately after any suspected exposure.
- Add secret patterns to `.gitignore` and use pre-commit hooks to prevent accidental commits.

## SQL and Query Safety

- Use parameterized queries or prepared statements for ALL database queries.
- **Never** concatenate user input into query strings.
- Use an ORM or query builder that parameterizes by default.
- Apply the principle of least privilege to database user permissions.

```
// Bad
db.Query("SELECT * FROM users WHERE id = " + userId)

// Good
db.Query("SELECT * FROM users WHERE id = ?", userId)
```

## Input Validation

- Validate ALL input at system boundaries: HTTP handlers, message consumers, CLI parsers.
- Validate type, length, format, and range.
- Use allowlists over denylists when possible.
- Reject unexpected fields (strict schema validation).
- Sanitize file names and paths to prevent path traversal (`../`).
- Limit request body size to prevent denial of service.

## Cross-Site Scripting (XSS) Prevention

- Encode all output rendered in HTML contexts.
- Use framework-provided auto-escaping (React JSX, Vue templates, Go html/template).
- Never use `dangerouslySetInnerHTML`, `v-html`, or equivalent without sanitization.
- Set `Content-Type` headers correctly on all responses.
- Implement Content Security Policy (CSP) headers.

## Cross-Site Request Forgery (CSRF) Protection

- Use anti-CSRF tokens on all state-changing endpoints.
- Validate the `Origin` and `Referer` headers as a secondary defense.
- Use `SameSite=Strict` or `SameSite=Lax` on session cookies.

## Rate Limiting

- Apply rate limiting on ALL public-facing endpoints.
- Use stricter limits on authentication endpoints (login, registration, password reset).
- Return `429 Too Many Requests` with a `Retry-After` header.
- Rate limit by IP, user ID, or API key as appropriate.
- Log rate limit violations for monitoring.

## Error Messages and Logging

- **Never** expose stack traces, internal paths, or system details in error responses.
- Return generic error messages to clients; log detailed errors server-side.
- **Never** log sensitive data: passwords, tokens, credit card numbers, personal information.
- Use structured logging with correlation IDs for traceability.
- Mask or redact sensitive fields in log output.

```
// Bad (leaks internals)
{ "error": "ECONNREFUSED 10.0.1.42:5432 - password auth failed for user 'dbadmin'" }

// Good (safe for clients)
{ "error": "Service temporarily unavailable. Please try again later.", "code": "SERVICE_UNAVAILABLE" }
```

## Authentication and Authorization

- Use established libraries and standards (OAuth 2.0, OIDC, JWT).
- Hash passwords with bcrypt, scrypt, or argon2. Never use MD5 or SHA for passwords.
- Implement proper session management: secure, httpOnly, sameSite cookies.
- Check authorization on every request, not just at the UI level.
- Apply the principle of least privilege to all roles and permissions.

## Dependencies

- Audit dependencies regularly for known vulnerabilities (`npm audit`, `go mod verify`).
- Pin dependency versions in production (use lock files).
- Review new dependencies before adding them: maintenance status, download count, known issues.
- Minimize the number of dependencies to reduce attack surface.

## Transport Security

- Use HTTPS for all communications. No exceptions.
- Set HSTS headers with appropriate max-age.
- Validate TLS certificates in all outbound connections.
- Use TLS 1.2+ only; disable older protocols.

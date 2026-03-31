---
name: security
description: "Application security expert: vulnerability detection, secure coding, supply chain safety, compliance"
triggers: ["security", "vulnerability", "auth", "encryption", "OWASP", "CVE", "penetration", "audit"]
---

# Security Profile

## Core Principles

Security is not a feature — it is a constraint that applies to every line of code.
Every security decision must default to DENY. If a check fails, the system must
refuse access, not grant it. This is the fail-secure principle.

### Fail-Open vs Fail-Secure

**Fail-open** (DANGEROUS): When a security check encounters an error, the system
allows access. This is the most common source of critical vulnerabilities.

**Fail-secure** (REQUIRED): When a security check encounters an error, the system
denies access and logs the failure for investigation.

Detection patterns for fail-open code:

```
# DANGEROUS: Fail-open patterns to flag immediately
try { authenticate(user) } catch { return true }       # catch grants access
if err != nil { return nil }                            # error returns nil (no denial)
if !isValid { log.Warn("invalid") }                     # logs but doesn't block
token, _ := jwt.Parse(tokenString, keyFunc)              # ignores parse error
if len(allowedIPs) == 0 { return true }                 # empty allowlist = allow all
```

```
# CORRECT: Fail-secure patterns
try { authenticate(user) } catch { return false; log.error(e) }
if err != nil { return nil, fmt.Errorf("auth failed: %w", err) }
if !isValid { return http.StatusForbidden }
token, err := jwt.Parse(tokenString, keyFunc); if err != nil { deny() }
if len(allowedIPs) == 0 { return false }   # empty allowlist = deny all
```

---

## OWASP Top 10 Checklist

### 1. Injection (SQL, Command, LDAP, NoSQL)

**Detection patterns:**
- String concatenation in SQL: `"SELECT * FROM users WHERE id = " + userInput`
- Template strings in queries: `` `DELETE FROM ${table} WHERE ${condition}` ``
- `exec()`, `eval()`, `os.system()`, `subprocess.call(shell=True)` with user input
- LDAP filters built from user input: `"(uid=" + username + ")"`
- MongoDB queries with `$where` or unvalidated `$regex`

**Required fixes:**
- Use parameterized queries / prepared statements exclusively
- Use ORM query builders (GORM `.Where("id = ?", id)`, not raw string)
- For command execution: use allowlists of permitted commands, never pass raw input
- Validate and sanitize all input at the boundary (API handler level)
- Apply the principle of least privilege to database accounts

### 2. Broken Authentication

**Detection patterns:**
- JWT with no expiration (`exp` claim missing)
- JWT with `alg: none` accepted
- JWT secret shorter than 256 bits
- Session tokens in URL parameters
- No rate limiting on login endpoints
- Password stored as plaintext or weak hash (MD5, SHA1 without salt)

**Required practices:**
- JWT: short expiration (15min access token), separate refresh token (7d max)
- JWT: validate `iss`, `aud`, `exp` claims on every request
- JWT: use RS256 or ES256 for production, HS256 only with 256+ bit secrets
- Passwords: bcrypt (cost >= 12), scrypt, or argon2id — never MD5/SHA1/SHA256 alone
- Session: regenerate session ID after login, invalidate on logout
- Rate limiting: max 5 failed attempts per 15 minutes, then lockout or CAPTCHA
- MFA: support TOTP at minimum for privileged accounts

### 3. Sensitive Data Exposure

**Detection patterns:**
- Secrets in source code: `apiKey = "sk-..."`, `password = "admin123"`
- Secrets in logs: `log.Info("token: " + token)`
- PII in error messages returned to clients
- HTTP (not HTTPS) for any authenticated endpoint
- Missing `Strict-Transport-Security` header
- Sensitive data in localStorage (use httpOnly secure cookies instead)

**Required practices:**
- Encrypt at rest: AES-256-GCM for data, bcrypt/argon2 for passwords
- Encrypt in transit: TLS 1.2+ only, HSTS header with `max-age=31536000`
- Never log secrets, tokens, passwords, or full credit card numbers
- Mask PII in logs: show only last 4 digits, first initial, etc.
- Use structured logging to prevent accidental secret inclusion
- Set `Cache-Control: no-store` for responses containing sensitive data

### 4. Cross-Site Scripting (XSS)

**Detection patterns:**
- `innerHTML = userInput` or `v-html="userInput"` without sanitization
- `document.write(userInput)`
- Template literals rendered without encoding: `${userInput}`
- Missing Content-Security-Policy header
- `dangerouslySetInnerHTML` in React without DOMPurify

**Required practices:**
- Output encode all user-controlled data for the correct context (HTML, JS, URL, CSS)
- Use framework auto-escaping (Vue `{{ }}` auto-escapes, but `v-html` does NOT)
- Set CSP header: `default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'`
- If rich text is needed: sanitize with DOMPurify or equivalent before rendering
- Set `X-Content-Type-Options: nosniff` to prevent MIME-type sniffing

### 5. Cross-Site Request Forgery (CSRF)

**Detection patterns:**
- State-changing operations on GET requests
- No CSRF token in forms or AJAX requests
- Missing `SameSite` attribute on cookies
- CORS `Access-Control-Allow-Origin: *` on authenticated endpoints

**Required practices:**
- Use synchronizer token pattern or double-submit cookie
- Set `SameSite=Strict` (or `Lax` minimum) on all session cookies
- Validate `Origin` and `Referer` headers as defense-in-depth
- Never use `Access-Control-Allow-Origin: *` with `credentials: true`

### 6. Server-Side Request Forgery (SSRF)

**Detection patterns:**
- User-supplied URLs passed to `http.Get()`, `fetch()`, `requests.get()`
- URL parsing that doesn't validate scheme, host, or port
- Redirects followed without validation
- DNS rebinding: hostname resolves to internal IP after validation

**Required practices:**
- Maintain an allowlist of permitted external domains
- Block requests to private IP ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8, 169.254.0.0/16, ::1
- Disable HTTP redirects or re-validate after each redirect
- Use a dedicated egress proxy for external requests

### 7. Path Traversal

**Detection patterns:**
- File paths constructed from user input: `os.Open("/data/" + filename)`
- Presence of `../` in file paths without sanitization
- `filepath.Join` without `filepath.Clean` and prefix validation
- Archive extraction (zip/tar) without path validation (zip-slip)

**Required practices:**
- Canonicalize paths with `filepath.Clean()` then verify prefix matches expected directory
- Use chroot or sandboxed file access where possible
- Reject paths containing `..`, null bytes, or encoded traversal sequences
- For archive extraction: validate every entry path before extracting

---

## Supply Chain Security

### Dependency Verification

Before adding ANY dependency, evaluate against these 6 risk criteria:

| Risk Factor | Threshold | Action |
|---|---|---|
| Single maintainer | 1 maintainer | HIGH RISK — find alternative or vendor |
| Unmaintained | No commits in 12 months | HIGH RISK — find alternative |
| Low popularity | <100 weekly downloads | MEDIUM RISK — extra scrutiny |
| High-risk features | Native code, postinstall scripts, network access | MEDIUM RISK — audit scripts |
| Past CVEs | Any unpatched CVE | CRITICAL — do not use |
| No security contact | No SECURITY.md or security policy | LOW RISK — note for future |

### Lock File Integrity

- ALWAYS commit lock files (package-lock.json, go.sum, poetry.lock)
- Verify lock file changes in every PR — unexpected changes may indicate supply chain attack
- Use `npm audit`, `go mod verify`, `pip-audit` in CI pipeline
- Pin exact versions in production, use ranges only in libraries

### Hallucinated Packages

AI-generated code frequently references packages that do not exist. Before installing:
- Verify the package exists on the official registry (npmjs.com, pkg.go.dev, pypi.org)
- Check the package name matches exactly (typosquatting: `lodash` vs `1odash`)
- Verify the import path matches the package documentation

---

## Secrets Management

### Never Hardcode Secrets

Detection regex patterns for common secret formats:

```
# AWS Access Key
AKIA[0-9A-Z]{16}

# AWS Secret Key
[0-9a-zA-Z/+]{40}

# GitHub Token
gh[ps]_[0-9a-zA-Z]{36}

# Generic API Key patterns
(?i)(api[_-]?key|apikey|secret[_-]?key)\s*[:=]\s*['"][^'"]{8,}['"]

# JWT Token
eyJ[A-Za-z0-9-_]+\.eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_.+/=]+

# Private Key
-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----

# Connection strings with passwords
(?i)(mysql|postgres|mongodb|redis)://[^:]+:[^@]+@
```

### Required practices:
- Use environment variables or dedicated secret managers (Vault, AWS Secrets Manager)
- Rotate secrets on a schedule: API keys every 90 days, passwords every 180 days
- Immediately rotate any secret that has been exposed in logs, commits, or error messages
- Use `.gitignore` to exclude `.env`, `credentials.json`, `*.pem`, `*.key`
- In CI/CD: use pipeline secret variables, never echo secrets in build logs

---

## Rationalizations to Reject

When reviewing code, REJECT these common security rationalizations:

1. **"It's just internal"** — Internal networks get breached. Zero-trust means every endpoint is authenticated.
2. **"We'll fix it later"** — Security debt compounds. Later never comes. Fix it now or file a tracked issue with a deadline.
3. **"The framework handles it"** — Frameworks have defaults, not guarantees. Verify the framework actually covers your specific case.
4. **"It's behind a firewall"** — Firewalls are a single layer. Defense in depth requires application-level security regardless.
5. **"Users wouldn't do that"** — Attackers are not users. They will do exactly what you didn't expect.
6. **"It's just a prototype"** — Prototypes become production. Bake security in from the start.
7. **"The risk is low"** — Low probability times high impact still equals unacceptable risk for auth and data exposure.

---

## Verification Checklist

Before approving any code change, verify these 6 categories:

### 1. Fallback Secrets
- [ ] No hardcoded fallback values for secrets (e.g., `os.Getenv("KEY") || "default-key"`)
- [ ] Missing environment variables cause startup failure, not silent fallback

### 2. Default Credentials
- [ ] No default admin/admin, root/root, or test/test credentials
- [ ] First-run setup forces credential creation

### 3. Fail-Open Security
- [ ] All auth/authz checks deny on error
- [ ] Empty allowlists deny all (not allow all)
- [ ] Timeout = deny, not allow

### 4. Weak Cryptography
- [ ] No MD5 or SHA1 for security purposes (checksums for non-security uses are acceptable)
- [ ] No DES, 3DES, RC4, or ECB mode
- [ ] RSA keys >= 2048 bits, AES keys >= 256 bits
- [ ] Random number generation uses crypto/rand, not math/rand

### 5. Permissive Access
- [ ] CORS is not `*` on authenticated endpoints
- [ ] File permissions are restrictive (600 for keys, 644 for configs)
- [ ] Database accounts have minimum required privileges

### 6. Debug Features
- [ ] No debug endpoints in production (pprof, debug/vars, phpinfo)
- [ ] Verbose error messages not returned to clients in production
- [ ] Debug logging disabled or gated behind environment flag

---

## Vulnerability Response Protocol

When a vulnerability is discovered:

1. **HALT** — Stop all related deployments immediately
2. **Assess blast radius** — What data/systems could be affected? Who has access?
3. **Classify severity** — CRITICAL (active exploitation possible), HIGH (exploitable with effort), MEDIUM (requires specific conditions), LOW (theoretical)
4. **Fix criticals first** — CRITICAL and HIGH vulnerabilities block all other work
5. **Rotate compromised credentials** — Any secret that may have been exposed must be rotated immediately, not "after the fix"
6. **Audit related code paths** — The same class of vulnerability likely exists elsewhere in the codebase
7. **Add regression test** — Create a test that specifically targets the vulnerability to prevent reintroduction
8. **Post-mortem** — Document what happened, why it wasn't caught, and what process changes prevent recurrence

---

## Agent Safety: Permission Deny Patterns

The following paths must NEVER be read, written, or exfiltrated by automated agents:

```
~/.ssh/**              # SSH keys
~/.aws/**              # AWS credentials
~/.gnupg/**            # GPG keys
~/.config/gcloud/**    # GCP credentials
~/.azure/**            # Azure credentials
~/.kube/config         # Kubernetes credentials
**/wallet.dat          # Crypto wallets
**/keystore/**         # Keystores
**/.env                # Environment files (read only when explicitly needed for the current project)
**/.npmrc              # NPM registry tokens
**/.pypirc             # PyPI registry tokens
**/credentials.json    # Service account keys
**/token.json          # OAuth tokens
```

When an agent encounters these paths:
- Do NOT read file contents
- Do NOT include contents in responses or logs
- Warn the user if a code change attempts to access these paths
- If credentials are needed for a task, ask the user to provide them via secure input

---

## Security Review Output Format

When performing a security review, structure findings as:

| # | Severity | Category | File:Line | Finding | Remediation |
|---|----------|----------|-----------|---------|-------------|
| 1 | CRITICAL | Injection | api/handler.go:45 | Raw SQL with string concatenation | Use parameterized query |
| 2 | HIGH | Auth | middleware/jwt.go:23 | JWT parsed without expiration validation | Add exp claim check |
| 3 | MEDIUM | XSS | components/Comment.vue:12 | v-html with user content | Use DOMPurify or text interpolation |

Every finding MUST include:
- Specific file and line number
- The actual vulnerable code snippet
- A concrete fix (not just "fix this")
- Severity based on exploitability and impact

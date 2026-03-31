---
name: code-review-checklist
description: "Comprehensive code review checklist across 5 dimensions"
---

# Code Review Checklist

Use this checklist when reviewing pull requests. Every item should be checked before approving.

## 1. Security

- [ ] No hardcoded secrets, API keys, or credentials
- [ ] All user input is validated and sanitized at system boundaries
- [ ] SQL queries use parameterized statements (no string concatenation)
- [ ] Output is encoded to prevent XSS (no raw HTML insertion)
- [ ] Authentication and authorization checks are present on protected endpoints
- [ ] Sensitive data is not exposed in logs, error messages, or API responses
- [ ] New dependencies have been reviewed for known vulnerabilities
- [ ] File uploads validate type, size, and content (not just extension)

## 2. Performance

- [ ] No N+1 query patterns (check ORM eager loading)
- [ ] List endpoints are paginated with reasonable defaults
- [ ] Database queries use appropriate indexes (check with EXPLAIN)
- [ ] No blocking I/O in request handlers; long tasks are offloaded
- [ ] Caching is applied where appropriate with correct TTL and invalidation
- [ ] No unnecessary data fetched (SELECT only needed columns/fields)
- [ ] Frontend bundles remain within size budget after changes

## 3. Code Quality

- [ ] Functions are under 50 lines; files are under 800 lines
- [ ] No code duplication (DRY); shared logic is extracted
- [ ] Naming is clear and self-documenting
- [ ] Error handling is consistent and comprehensive (no swallowed errors)
- [ ] No dead code, commented-out code, or TODO items without issue references
- [ ] Public APIs have doc comments explaining purpose and usage
- [ ] Complex logic has inline comments explaining *why*, not *what*
- [ ] Changes follow the existing codebase patterns and conventions

## 4. Testing

- [ ] New code has corresponding unit tests
- [ ] Edge cases are covered (null, empty, boundary values, error paths)
- [ ] Tests are independent and can run in any order
- [ ] No `it.skip`, `test.skip`, or disabled tests in committed code
- [ ] Mocks are at system boundaries, not on internal implementation
- [ ] Test names describe the scenario: what_when_then
- [ ] Integration tests cover critical paths (auth, data mutation, payment)

## 5. AI Residuals

These are common artifacts left by AI-generated code that require human review:

- [ ] No hallucinated imports (verify every import path exists)
- [ ] No invented API endpoints or methods that do not exist in the codebase
- [ ] No placeholder or stub implementations disguised as complete code
- [ ] No overly verbose comments that restate the obvious
- [ ] No unnecessary abstractions added "for flexibility" without a concrete use case
- [ ] No copy-pasted patterns that do not fit the current context
- [ ] Error messages are accurate and specific, not generic boilerplate
- [ ] Configuration values are correct for the target environment (not copied from examples)

## Review Process

1. **Read the PR description** to understand intent before reading code.
2. **Check the diff as a whole** for architectural concerns before line-by-line review.
3. **Run the code locally** for non-trivial changes.
4. **Leave actionable comments**: explain what to change and why.
5. **Distinguish blocking vs non-blocking feedback**: prefix non-blocking with "nit:" or "optional:".
6. **Approve only when all blocking items are resolved.**

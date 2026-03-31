---
name: documentation
description: "Documentation expert: diff-driven doc updates, API docs, architecture diagrams, cross-doc consistency"
triggers: ["documentation", "README", "docs", "CHANGELOG", "API doc", "comment", "JSDoc", "architecture diagram"]
---

# Documentation Profile

## Core Principle

**Documentation that doesn't match reality is worse than no documentation.**

Outdated documentation actively misleads developers. It causes them to build on false
assumptions, debug non-existent configurations, and waste hours on paths that no longer
exist. Every documentation change must be verified against the current codebase.

---

## Diff-Driven Update Workflow

Documentation updates are triggered by code changes, not by schedule. When code changes,
documentation MUST be updated in the same PR. This is the diff-driven workflow:

### Step 1: Read the Diff

```
git diff [base-branch]...HEAD
git diff --name-only [base-branch]...HEAD
```

Identify ALL changed files: source code, config files, scripts, migrations, schemas.

### Step 2: Identify Documentation Files

Scan the repository for all documentation:
- `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`
- `CLAUDE.md` (project instructions for AI tools)
- `CHANGELOG.md`
- `docs/` directory and all `.md` files within
- API documentation (Swagger/OpenAPI specs, JSDoc, GoDoc)
- Inline code comments on changed functions
- Configuration file comments

### Step 3: Cross-Reference Changes Against Documentation

For each code change, ask:
- Does any documentation reference this file, function, API, or config?
- Does this change alter the behavior described in any doc?
- Does this change add new features/endpoints not yet documented?
- Does this change remove features that are still documented?
- Does this change modify environment variables, config keys, or CLI flags?

### Step 4: Auto-Update Factual Changes

These changes can be made automatically without user approval:
- File paths that moved or were renamed
- Counts that changed (e.g., "supports 5 indicators" → "supports 7 indicators")
- Table rows added/removed to match code reality
- API endpoint signatures (method, path, parameters)
- Import paths that changed
- Version numbers that incremented
- CLI flag names or defaults that changed

### Step 5: Ask About Narrative Changes

These require human judgment — flag them for the user:
- Explanation of WHY a feature works a certain way
- Architecture decision rationale
- Migration guides for breaking changes
- Tutorial or getting-started rewrites
- Tone or audience changes

### Step 6: Verify Cross-Document Consistency

After all updates, verify:
- README and ARCHITECTURE don't contradict each other
- CLAUDE.md project structure matches actual directory layout
- CHANGELOG entries match the actual changes in the release
- API docs match the implemented endpoints
- Config examples match the actual config schema
- No document references a file, function, or feature that no longer exists

### Step 7: Ensure Discoverability

Every documentation file must be reachable:
- README.md links to all other key documents
- CLAUDE.md references all relevant project docs
- API docs are linked from README or a docs index
- No orphan documents (files that exist but are never linked)

---

## 7 Document Types to Audit

### 1. README.md

**Purpose:** First entry point for anyone encountering the project.

**Must contain:**
- Project name and one-line description
- Quick start (clone → install → run in <5 commands)
- Prerequisites (runtime versions, system dependencies)
- Configuration (environment variables with descriptions and defaults)
- Basic usage examples
- Link to detailed documentation
- License

**Quality checks:**
- [ ] Quick start actually works (test it)
- [ ] All prerequisites are listed (don't assume Node/Go/Python is installed)
- [ ] Environment variables are complete (no undocumented required vars)
- [ ] Examples use realistic values (not `your-api-key-here` without explanation)

### 2. ARCHITECTURE.md

**Purpose:** System design for developers who need to understand the codebase.

**Must contain:**
- High-level system diagram (components and their relationships)
- Directory structure with purpose of each top-level directory
- Data flow description (request lifecycle from entry to response)
- Key design decisions and their rationale
- External dependencies and why they were chosen
- Deployment architecture (if applicable)

**Quality checks:**
- [ ] Diagram matches actual code structure
- [ ] All listed directories exist
- [ ] Design decisions are still valid (not describing a past architecture)
- [ ] External dependencies match actual imports/packages

### 3. CONTRIBUTING.md

**Purpose:** Guide for new contributors to make their first PR.

**Must contain:**
- Development environment setup (step by step)
- Branch naming conventions
- Commit message format
- PR template and review process
- Testing requirements (what must pass before PR)
- Code style guide or linter configuration reference

**Quality checks:**
- [ ] Setup instructions produce a working environment
- [ ] Conventions match what's actually enforced in CI
- [ ] Testing commands actually work

### 4. CLAUDE.md (AI Project Instructions)

**Purpose:** Tell AI coding tools how to work with this project.

**Must contain:**
- Project overview and tech stack
- Directory structure with purpose annotations
- Coding conventions (naming, error handling, patterns)
- Testing conventions (frameworks, file locations, run commands)
- Build and run commands
- Architecture constraints (what NOT to do)

**Quality checks:**
- [ ] Directory structure matches reality
- [ ] Build commands actually work
- [ ] Conventions match what the codebase actually uses
- [ ] No references to deleted files or deprecated patterns

### 5. CHANGELOG.md

**Purpose:** Human-readable history of notable changes per version.

**Rules:**
- **NEVER regenerate** — polish existing entries for grammar and clarity
- **ADD** new entries for unreleased changes under an `[Unreleased]` section
- Follow [Keep a Changelog](https://keepachangelog.com/) format
- Categories: Added, Changed, Deprecated, Removed, Fixed, Security
- Each entry is one line describing a user-visible change
- Include PR/issue references where available

**Quality checks:**
- [ ] Entries match actual changes (not aspirational)
- [ ] No duplicate entries
- [ ] Dates are correct
- [ ] Version numbers follow semver

### 6. API Documentation

**Purpose:** Complete reference for API consumers.

**Each endpoint must document:**

```
### [Method] [Path]

[One-line description]

**Authentication:** [Required/Optional/None]

**Parameters:**

| Name | In | Type | Required | Description | Default |
|------|-----|------|----------|-------------|---------|
| symbol | query | string | Yes | Trading pair (e.g., BTCUSDT) | — |
| limit | query | integer | No | Number of results | 100 |

**Request Body:** (for POST/PUT)
```json
{
  "field": "value",
  "nested": { "key": "value" }
}
```

**Response 200:**
```json
{
  "data": [...],
  "pagination": { "page": 1, "total": 100 }
}
```

**Error Responses:**

| Code | Description |
|------|-------------|
| 400 | Invalid parameters — [specific reason] |
| 401 | Missing or invalid authentication token |
| 404 | Resource not found |
| 429 | Rate limit exceeded (max 100 req/min) |
```

**Quality checks:**
- [ ] Every endpoint is documented (compare against router/routes file)
- [ ] Request/response examples are valid JSON
- [ ] Error codes match actual error handling in code
- [ ] Authentication requirements match middleware configuration
- [ ] Parameter types match actual validation

### 7. Inline Code Comments

**Purpose:** Explain WHY, not WHAT. The code explains what; comments explain why.

**When to comment:**
- Non-obvious business logic: `// Price rounded down to tick size per Binance API requirement`
- Workarounds: `// Using retry loop because Binance WebSocket drops connection every 24h`
- Performance decisions: `// Pre-allocating slice to avoid repeated growth during batch processing`
- Magic numbers that can't be named constants: `// 14 is the standard RSI period per Wilder (1978)`
- Algorithm source: `// Implements Welles Wilder's smoothing method (not standard EMA)`

**When NOT to comment:**
- `i++ // increment i` — obvious from the code
- `// Constructor` above a constructor — obvious from the structure
- `// GetUser returns a user` — obvious from the function name
- Dead code commented out — delete it, use version control

**Sync rule:** When code changes, review adjacent comments. Stale comments are bugs.

---

## Freshness Indicators

Documentation should communicate its recency:

- **Last updated** dates on architecture and design docs
- **Version** references in API docs (which software version does this doc describe?)
- **Tested on** date for setup/installation guides
- **Reviewed** date for security-related documentation

If a document hasn't been updated in 6+ months but the code has changed significantly,
flag it for review.

---

## Measurable Quality Standards

### Technical Accuracy: 100%
- Every file path in docs exists in the repo
- Every command in docs executes successfully
- Every code example compiles/runs without errors
- Every config key in docs exists in the actual config schema
- Every API example returns the documented response

### Readability: Flesch-Kincaid Score > 60
- Short sentences (avg < 20 words)
- Common words over jargon (unless the jargon is necessary domain terminology)
- Active voice: "Run the migration" not "The migration should be run"
- One idea per paragraph

### Code Examples Must Work
- Every code example in documentation must be tested
- Use code fences with language tags for syntax highlighting
- Include required imports/setup, not just the interesting line
- Show expected output where helpful
- If an example is abbreviated, mark with `// ...` and explain what's omitted

---

## Audience Analysis

### User-Facing Documentation (How to Use)
- **Audience:** Someone using your software, not building it
- **Tone:** Practical, task-oriented
- **Structure:** Goal → Steps → Verification
- **Avoid:** Implementation details, internal architecture, source code references
- **Examples:** Installation guide, configuration reference, tutorials, FAQ

### Developer-Facing Documentation (How it Works)
- **Audience:** Someone contributing to or maintaining the codebase
- **Tone:** Technical, precise
- **Structure:** Context → Architecture → Decisions → Conventions
- **Include:** Design rationale, tradeoffs, known limitations, areas for improvement
- **Examples:** ARCHITECTURE.md, CONTRIBUTING.md, CLAUDE.md, inline comments

### API Consumer Documentation (How to Integrate)
- **Audience:** Developer building against your API
- **Tone:** Reference, complete
- **Structure:** Authentication → Endpoints → Examples → Errors → Rate Limits
- **Include:** Copy-pasteable examples in multiple languages, error recovery guidance
- **Avoid:** Internal implementation details, database schemas

---

## Progressive Disclosure

Structure documentation from simple to complex:

### Level 1: Quick Start (30 seconds)
- What is this? (one sentence)
- How do I run it? (3-5 commands)
- Where do I go for more? (link)

### Level 2: Basic Usage (5 minutes)
- Configuration options
- Common use cases with examples
- Troubleshooting common issues

### Level 3: Detailed Reference (as needed)
- Complete API reference
- All configuration options with descriptions
- Architecture and design decisions
- Performance tuning guide

### Level 4: Advanced Topics (deep dive)
- Extending the system
- Custom plugin/middleware development
- Deployment and scaling guide
- Security hardening

Each level should be self-contained. A user at Level 1 should not need to read Level 3
to accomplish basic tasks.

---

## Documentation Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Outdated README | New developer follows wrong setup steps, wastes hours | Update README in same PR as code changes |
| Missing setup instructions | "Works on my machine" — nobody else can run it | Document every prerequisite, every env var, every command |
| Undocumented environment variables | App crashes with cryptic error about missing config | List all env vars with description, type, required/optional, default |
| Broken links | Click → 404 → frustration → distrust | Run link checker in CI (markdown-link-check) |
| Screenshots of text | Can't search, can't copy, can't update, can't read on mobile | Use text, code blocks, and diagrams-as-code (Mermaid) |
| Wall of text | Nobody reads it | Use headers, bullet points, tables, code blocks |
| Aspirational documentation | Describes planned features as if they exist | Document only what's implemented. Use "Roadmap" for future plans. |
| Copy-pasted boilerplate | Generic content that doesn't apply to this project | Write project-specific content or delete |
| Version-less docs | Reader doesn't know if docs match their version | Include version/date, maintain docs per major version |
| Single monolithic doc | 2000-line README that covers everything | Split into focused documents, link from index |

---

## Documentation Review Checklist

When reviewing documentation changes:

### Accuracy
- [ ] All file paths exist in the repository
- [ ] All commands execute successfully
- [ ] All code examples compile/run
- [ ] All links resolve (no 404s)
- [ ] Version numbers are correct
- [ ] Environment variable names match the code

### Completeness
- [ ] All new features are documented
- [ ] All removed features are un-documented
- [ ] All changed behaviors are reflected
- [ ] All new configuration options are listed
- [ ] All new API endpoints are documented
- [ ] Error scenarios are covered

### Consistency
- [ ] No contradictions between documents
- [ ] Terminology is consistent (don't mix "signal" and "alert" for the same concept)
- [ ] Code style in examples matches project conventions
- [ ] Formatting is consistent (heading levels, list styles, code fence languages)

### Discoverability
- [ ] New documents are linked from README or index
- [ ] Table of contents is updated if applicable
- [ ] Search terms a user would use are present in the text
- [ ] Related documents cross-reference each other

---

## Documentation Update Output Format

When reporting documentation changes needed:

| # | Document | Section | Current State | Required Update | Type |
|---|----------|---------|--------------|-----------------|------|
| 1 | README.md | Quick Start | Shows `npm install` | Should be `pnpm install` (project uses pnpm) | AUTO-FIX |
| 2 | ARCHITECTURE.md | Directory Structure | Lists `services/` | Directory renamed to `internal/application/` | AUTO-FIX |
| 3 | API.md | /api/v1/signals | Not documented | New endpoint added in this PR | ADD |
| 4 | CLAUDE.md | Tech Stack | Lists "Redis 6" | Upgraded to Redis 7 in docker-compose | AUTO-FIX |
| 5 | README.md | Overview | Describes single-strategy system | Now supports multiple strategies — narrative rewrite needed | ASK USER |

AUTO-FIX items are applied immediately. ASK USER items are flagged for human decision.

**English** | [中文](README.zh-CN.md)

# CCClaude

**A reusable Claude Code harness with role-profile composition architecture.**

CCClaude provides a structured framework for using Claude Code across software projects. It defines roles, profiles, skills, rules, and hooks that compose at runtime to create specialized AI development agents.

## Features

- **5 Roles**: Planner, Worker, Reviewer, Releaser, Harden
- **10 Profiles**: Architect, Backend, Frontend, Database, DevOps, Security, Performance, Testing, Reviewer, Documentation
- **Guardrail Rules**: Coding style, git workflow, testing, security, and performance rules enforced on every interaction
- **Contextual Skills**: Domain knowledge loaded automatically based on conversation context
- **Extensible**: Add project-specific profiles, skills, and rules without modifying the harness

## Quick Start

### 1. Clone the harness

```bash
git clone https://github.com/anthropics/CCClaude.git
```

### 2. Initialize in your project

```bash
# Unix/macOS
/path/to/CCClaude/init.sh /path/to/your-project

# Windows PowerShell
/path/to/CCClaude/init.ps1 -ProjectDir /path/to/your-project
```

### 3. Start using it

```
/plan Add user authentication with OAuth 2.0
/work T1
/review
/harden all    # Audit all role definitions against iron rule standards
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  CCClaude Harness                │
│                                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐    │
│  │  Planner  │   │  Worker   │   │ Reviewer  │    │
│  │   Role    │   │   Role    │   │   Role    │    │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘    │
│       │              │              │            │
│       ▼              ▼              ▼            │
│  ┌──────────────────────────────────────────┐   │
│  │            Profile Composition            │   │
│  │  backend | frontend | devops | testing    │   │
│  │  security | database | api | docs | perf  │   │
│  └──────────────────┬───────────────────────┘   │
│                     │                            │
│       ┌─────────────┼─────────────┐              │
│       ▼             ▼             ▼              │
│  ┌─────────┐  ┌──────────┐  ┌─────────┐        │
│  │  Rules   │  │  Skills   │  │  Hooks   │        │
│  │ (always) │  │(contextual│  │ (events) │        │
│  └─────────┘  └──────────┘  └─────────┘        │
│                                                  │
│       Role + Profile + Rules + Skills            │
│                    =                             │
│            Runtime Agent                         │
└─────────────────────────────────────────────────┘
```

## Directory Structure

```
CCClaude/
├── CLAUDE.md                    # Harness self-documentation
├── README.md                    # This file
├── LICENSE                      # MIT License
├── init.sh                      # Unix/macOS project initializer
├── init.ps1                     # Windows project initializer
├── rules/
│   ├── common/                  # Universal rules (always loaded)
│   │   ├── coding-style.md
│   │   ├── git-workflow.md
│   │   ├── testing.md
│   │   ├── security.md
│   │   └── performance.md
│   └── _project/                # Your project-specific rules
├── skills/
│   ├── common/                  # Shared skills (contextually loaded)
│   │   ├── git-workflow/
│   │   ├── code-review-checklist/
│   │   └── tdd-workflow/
│   └── _project/                # Your project-specific skills
├── profiles/
│   ├── common/                  # Built-in profiles
│   └── _project/                # Your project-specific profiles
├── templates/                   # File templates
│   ├── Plans.md.template
│   └── CLAUDE.md.template
└── commands/                    # Slash command definitions
```

## Profiles

| Profile | Description |
|---------|-------------|
| `architect` | System design, component boundaries, API contracts, ADR documentation, DDD |
| `backend` | Server-side development: APIs, DDD, clean architecture, error handling, logging |
| `frontend` | UI components, state management, accessibility (WCAG 2.1 AA), performance |
| `database` | Schema design, migrations, query optimization, indexing, multi-DB knowledge |
| `devops` | CI/CD pipelines, Docker/K8s, deployment strategies, monitoring, infrastructure |
| `security` | Vulnerability detection, OWASP Top 10, supply chain safety, fail-secure patterns |
| `performance` | Profiling, benchmarking, regression detection, N+1 queries, Core Web Vitals |
| `testing` | TDD workflow, diff-aware testing, regression detection, edge case coverage |
| `reviewer` | Multi-pass code review, confidence scoring, anti-pattern detection, AI residuals |
| `documentation` | Diff-driven doc updates, API docs, cross-doc consistency, CHANGELOG management |

## Commands

| Command | Role | Description |
|---------|------|-------------|
| `/plan <feature>` | Planner | Decompose a feature into tasks, produce Plans.md |
| `/work <task-id>` | Worker | Execute a specific task from Plans.md |
| `/review` | Reviewer | Review current code changes against all rules |
| `/release [patch\|minor\|major]` | Releaser | Prepare release: changelog, version, tags |
| `/orchestrate <pipeline>` | All | Run pipeline: feature, bugfix, refactor, or security |
| `/harden [role\|all]` | Harden | Audit and harden role/profile/rule definitions |

## Iron Rule System

CCClaude's core innovation is a structured iron rule system that prevents AI agents from making common mistakes. Every role definition contains:

- **Tool Bans** — explicitly allowed and banned tools with reasons for each
- **Numbered Iron Rules** — NEVER/DO NOT/CRITICAL statements, each with a reason explaining the consequence of violation
- **Ban Format Standard** — no soft language, no escape hatches, every ban must be verifiable and specific

Three universal rules in `rules/common/` apply to all roles:
- `iron-rule-standard.md` — ban format and structure requirements
- `honesty.md` — no guessing, no fabrication, explicit uncertainty tagging
- `anti-overreach.md` — stay in scope, no gold-plating

The **Harden role** (`/harden`) audits all other role and profile definitions against these standards, providing dual enforcement.

## Customization

### Adding Project-Specific Rules

Create markdown files in `rules/_project/`:

```markdown
<!-- rules/_project/api-conventions.md -->
# API Conventions

- All endpoints return JSON with envelope: { data, error, meta }
- Use snake_case for JSON field names
- Version prefix: /api/v1/
```

### Adding Project-Specific Skills

Create a directory with a `SKILL.md` in `skills/_project/`:

```markdown
<!-- skills/_project/domain-model/SKILL.md -->
---
name: domain-model
description: "Project domain model and business rules"
---

# Domain Model
...
```

### Adding Project-Specific Profiles

Create profile definitions in `profiles/_project/` for roles unique to your project.

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes following the rules in `rules/common/`
4. Write tests for new functionality
5. Submit a pull request

## License

MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

CCClaude draws inspiration from these open-source projects and resources:

- [Anthropic Claude Code](https://docs.anthropic.com/en/docs/claude-code) -- The foundation this harness extends
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — 136+ skills, 30+ agents, comprehensive harness
- [claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) — Plan→Work→Review cycle, TypeScript guardrail engine
- [garrytan/gstack](https://github.com/garrytan/gstack) — Best-in-class review, testing, and benchmarking skills
- [trailofbits/skills](https://github.com/trailofbits/skills) — Security skills from a top audit firm
- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) — Subagent catalog
- [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) — Database and backend profiles
- [OpenSSF Security Guide](https://best.openssf.org/Security-Focused-Guide-for-AI-Code-Assistant-Instructions.html) — AI security best practices

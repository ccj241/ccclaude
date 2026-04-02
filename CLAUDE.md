# CCClaude

## What Is This

CCClaude is a reusable Claude Code harness that provides structured roles, profiles, skills, rules, and hooks for software development projects. It implements a role-profile composition architecture where runtime agents are assembled from a base role plus one or more profiles.

## Architecture

CCClaude uses a four-role system with ten composable profiles:

### Roles (4)

| Role | Purpose |
|------|---------|
| **Planner** | Decomposes requirements into tasks, produces Plans.md |
| **Worker** | Executes tasks from Plans.md using the assigned profile |
| **Reviewer** | Reviews code changes against rules and checklists |
| **Orchestrator** | Coordinates multi-agent workflows across roles |
| **Harden** | Audits and hardens role/profile definitions — injects bans, mistake-proofing over cleverness |

### Profiles (10)

Profiles are composable skill sets that specialize a Worker for a particular domain:

| Profile | Domain |
|---------|--------|
| backend | Server-side code, APIs, databases |
| frontend | UI components, styling, client-side logic |
| fullstack | Combined backend + frontend |
| devops | CI/CD, infrastructure, deployment |
| testing | Test writing, coverage, quality assurance |
| security | Security audits, vulnerability assessment |
| database | Schema design, migrations, query optimization |
| api-design | API contracts, OpenAPI specs, versioning |
| documentation | Technical writing, API docs, guides |
| performance | Profiling, optimization, load testing |

### How Composition Works

At runtime, an agent is assembled as: **Role + Profile(s) + Rules + Skills**

```
Worker + backend profile + common rules + git-workflow skill
  = A backend-focused developer agent with git expertise
```

Rules are always loaded (they are guardrails). Skills are loaded contextually based on the conversation.

### Iron Rule System

Every role in CCClaude follows a structured iron rule system. This is the core innovation that prevents AI agents from making stupid mistakes.

**Key principles:**
- Every role has explicit **tool bans** with reasons
- Every role has numbered **iron rules** with NEVER/DO NOT/CRITICAL statements
- Every ban has a **reason** explaining the specific consequence of violation
- The **Harden role** audits all other roles against these standards (dual enforcement)

**Three universal rules apply to all roles** (defined in `rules/common/`):
- `iron-rule-standard.md` — ban format and structure requirements
- `honesty.md` — no guessing, no fabrication, explicit uncertainty tagging
- `anti-overreach.md` — stay in scope, no gold-plating

## Commands

| Command | Description |
|---------|-------------|
| `/plan` | Start the Planner role to decompose a feature into tasks |
| `/work` | Start the Worker role to execute tasks from Plans.md |
| `/review` | Start the Reviewer role to audit code changes |
| `/release` | Prepare a release (changelog, version bump, tags) |
| `/orchestrate` | Start multi-agent coordination |
| `/harden` | Audit and harden role/profile/rule definitions |

## Directory Structure

```
CCClaude/
├── CLAUDE.md               # This file
├── README.md               # Project documentation
├── LICENSE                  # MIT License
├── init.sh                 # Unix initializer
├── init.ps1                # Windows initializer
├── rules/
│   ├── common/             # Universal rules (always active)
│   └── _project/           # Project-specific rules (add yours here)
├── skills/
│   ├── common/             # Shared skills (contextually loaded)
│   └── _project/           # Project-specific skills (add yours here)
├── profiles/
│   ├── common/             # Built-in profiles
│   └── _project/           # Project-specific profiles (add yours here)
├── templates/              # File templates (Plans.md, CLAUDE.md)
└── commands/               # Slash command definitions
```

## Extending CCClaude

To add project-specific customizations, place files in the `_project/` directories:

- **rules/_project/**: Add `.md` files with project-specific coding rules
- **skills/_project/**: Add skill directories with `SKILL.md` files for domain knowledge
- **profiles/_project/**: Add profile definitions for project-specific roles

These directories are ignored by CCClaude's own git repository and are meant to be populated per-project by `init.sh`.

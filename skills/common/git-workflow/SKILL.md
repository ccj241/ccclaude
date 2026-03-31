---
name: git-workflow
description: "Git workflow standards: branching, commits, merging, conflict resolution"
---

# Git Workflow

## Branching Strategy

| Branch | Purpose | Branches From | Merges Into |
|--------|---------|---------------|-------------|
| `main` | Production-ready code | - | - |
| `develop` | Integration branch | `main` | `main` (via release) |
| `feature/*` | New features | `develop` | `develop` |
| `bugfix/*` | Bug fixes | `develop` | `develop` |
| `hotfix/*` | Urgent production fixes | `main` | `main` + `develop` |
| `release/*` | Release preparation | `develop` | `main` + `develop` |

## Conventional Commit Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Examples

```
feat(auth): add JWT token refresh endpoint
fix(cart): correct discount calculation for bulk orders
docs(api): update authentication guide with OAuth examples
refactor(user): extract address validation into shared module
test(payment): add integration tests for Stripe webhook handler
chore(deps): upgrade Express from 4.18 to 4.19
perf(search): add database index on products.category_id
```

### Commit Body Guidelines

- Explain the motivation for the change, not the mechanics.
- Wrap body lines at 72 characters.
- Reference related issues: `Closes #42`, `Refs #108`.

## Merge vs Rebase

| Situation | Strategy |
|-----------|----------|
| Updating feature branch with latest develop | `git rebase develop` (linear history) |
| Merging feature into develop | Squash merge (one clean commit per feature) |
| Merging release into main | Merge commit (preserve release boundary) |
| Hotfix into main | Merge commit |
| Local work-in-progress cleanup | Interactive rebase before pushing |

**Rule:** Never rebase commits that have been pushed to a shared branch.

## Conflict Resolution Steps

1. **Identify**: Run `git status` to see conflicted files.
2. **Understand**: Read both sides of the conflict. Use `git log --merge` to see divergent commits.
3. **Resolve**: Edit the file, choosing the correct resolution. Do not blindly accept "ours" or "theirs".
4. **Verify**: Run tests after resolving to ensure correctness.
5. **Complete**: Stage resolved files with `git add`, then continue the merge/rebase.
6. **Communicate**: If the conflict involves another contributor's code, discuss the resolution with them.

## Stash Workflow

```bash
# Save work in progress with a descriptive message
git stash push -m "WIP: user profile validation"

# List all stashes
git stash list

# Apply most recent stash and remove it
git stash pop

# Apply a specific stash without removing it
git stash apply stash@{2}

# Drop a stash you no longer need
git stash drop stash@{0}
```

**Rule:** Never leave stashes for more than one work session. Apply or drop them promptly.

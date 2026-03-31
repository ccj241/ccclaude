# Git Workflow Rules

## Commit Messages

Use Conventional Commits format strictly:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type | When to Use |
|------|------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, whitespace, semicolons (no logic change) |
| `refactor` | Code restructuring (no feature or fix) |
| `test` | Adding or updating tests |
| `chore` | Build, CI, dependencies, tooling |
| `perf` | Performance improvement |
| `ci` | CI/CD configuration changes |

### Rules

- Description MUST be lowercase, imperative mood: "add feature" not "added feature" or "adds feature".
- Description MUST be under 72 characters.
- Scope is optional but encouraged. Use the module or domain area: `feat(auth): add token refresh`.
- Body explains *why*, not *what*. The diff shows *what*.
- Footer references issues: `Closes #123` or `Refs #456`.

## Branch Naming

```
feature/<short-description>
bugfix/<short-description>
hotfix/<short-description>
release/<version>
```

- Use lowercase and hyphens: `feature/add-user-auth`, not `feature/AddUserAuth`.
- Keep branch names under 50 characters.
- Delete branches after merge.

## Protected Branches

- **Never** force push to `main`, `master`, `develop`, or `release/*` branches.
- **Never** skip hooks with `--no-verify` or `--no-gpg-sign`.
- **Never** commit directly to protected branches; always use pull requests.

## Atomic Commits

- Each commit MUST represent exactly one logical change.
- If you need "and" to describe what a commit does, split it into multiple commits.
- Tests for a feature go in the same commit as the feature code.
- Do not mix refactoring with feature work in the same commit.

## Pull Request Description

Every PR MUST include:

```markdown
## Summary
- Brief description of what changed and why

## Changes
- List of specific changes made

## Testing
- How the changes were tested
- Any new tests added

## Checklist
- [ ] Tests pass
- [ ] No new warnings
- [ ] Documentation updated (if applicable)
- [ ] Breaking changes documented (if applicable)
```

## Merge Strategy

- Feature branches merge into `develop` via squash merge (clean history).
- Release branches merge into `main` via merge commit (preserve release boundary).
- Hotfix branches merge into both `main` and `develop`.
- Resolve merge conflicts locally, never via GitHub UI for non-trivial conflicts.

## Stash Workflow

- Use `git stash` with a descriptive message: `git stash push -m "WIP: auth token refresh"`.
- Do not leave stashes lingering. Apply or drop within the same work session.

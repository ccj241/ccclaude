---
name: anti-overreach
description: "Anti-overreach — every role stays within its scope, no gold-plating"
---

# Anti-Overreach Rules

These rules prevent roles from doing more than they should.

## Core Principle

**Doing the right thing wrong is better than doing the wrong thing right.** Overreach — doing things outside your assigned scope — introduces unreviewed changes, increases regression risk, and wastes user review effort.

## Rules

1. **NEVER do work outside your task/review/plan scope.** Reason: out-of-scope work bypasses the planning and review pipeline, making changes untrackable.

2. **DO NOT refactor unrelated code while fixing a bug.** Reason: the refactoring is unreviewed and may introduce regressions unrelated to the original fix.

3. **DO NOT add features not requested by the user.** Reason: unrequested features carry unknown risk and maintenance cost the user never agreed to.

4. **DO NOT suggest "while we're at it, we could also..."** Reason: scope creep is the #1 cause of delayed delivery and review fatigue.

5. **DO NOT add error handling, validation, or fallbacks for scenarios that cannot happen.** Reason: speculative defensive code adds complexity without value and obscures real logic.

6. **DO NOT add comments, docstrings, or type annotations to code you didn't change.** Reason: touching unchanged code creates noise in diffs and review.

7. **If you find a problem outside your scope, note it — do not fix it.** Record it in Plans.md Notes section or report it in your output. Reason: fixing it yourself bypasses the Planner's prioritization and the Reviewer's audit.

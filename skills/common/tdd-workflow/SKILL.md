---
name: tdd-workflow
description: "Test-Driven Development workflow: Red-Green-Refactor with edge case coverage"
---

# Test-Driven Development Workflow

## The Red-Green-Refactor Cycle

### Step 1: RED -- Write a Failing Test

1. Write a test that describes the desired behavior.
2. Run the test. It MUST fail. If it passes, either the test is wrong or the feature already exists.
3. Verify the failure message makes sense and points to the right thing.

**RED Gate:** Do NOT proceed to Step 2 until you have a clear, meaningful test failure.

### Step 2: GREEN -- Make It Pass

1. Write the minimum code necessary to make the test pass.
2. Do not optimize. Do not handle edge cases. Do not refactor.
3. Run the test. It MUST pass.
4. Run the full test suite to ensure nothing else broke.

### Step 3: REFACTOR -- Clean Up

1. Improve the code structure without changing behavior.
2. Remove duplication, improve naming, extract functions.
3. Run the full test suite after each refactoring step. Tests MUST stay green.
4. Commit when the refactoring is complete.

### Then Repeat

Return to Step 1 for the next behavior. Each cycle should take 5-15 minutes.

## Edge Case Categories

Every feature implementation should cycle through these 8 categories of edge cases:

| # | Category | Examples |
|---|----------|----------|
| 1 | **Empty/null input** | `null`, `undefined`, `""`, `[]`, `{}` |
| 2 | **Boundary values** | `0`, `-1`, `MAX_INT`, first element, last element |
| 3 | **Invalid input** | Wrong type, malformed format, missing required fields |
| 4 | **Duplicate values** | Duplicate keys, repeated submissions, idempotency |
| 5 | **Large input** | Oversized strings, huge collections, deep nesting |
| 6 | **Concurrent access** | Race conditions, double writes, stale reads |
| 7 | **Permission/auth** | Unauthorized, forbidden, expired token, wrong role |
| 8 | **External failure** | Network timeout, service unavailable, malformed response |

## When to Use TDD

TDD is most valuable for:

- Business logic with clear input/output contracts
- Data transformations and calculations
- State machines and workflow engines
- API endpoint handlers
- Utility functions and shared libraries
- Bug fixes (write the failing test first, then fix)

## When TDD May Not Be the Best Fit

- Exploratory prototyping (write tests after the design stabilizes)
- UI layout and visual styling (use visual regression testing instead)
- One-off scripts and migrations
- Infrastructure configuration (use integration tests instead)

In these cases, still write tests -- just write them after the implementation rather than before.

## TDD Anti-Patterns to Avoid

- **Testing implementation details:** Test behavior, not how it is achieved internally.
- **Too many mocks:** If a test requires 5+ mocks, the design may need restructuring.
- **Test-per-method:** Organize tests by behavior/scenario, not by method name.
- **Skipping RED:** Always verify the test fails first. A test that never fails proves nothing.
- **Large GREEN steps:** If making the test pass requires 50+ lines, break the behavior into smaller tests.

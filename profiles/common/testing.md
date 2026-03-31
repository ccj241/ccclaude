---
name: testing
description: "Testing expert: TDD workflow, diff-aware testing, regression detection, edge case coverage"
triggers: ["test", "TDD", "unit test", "integration test", "E2E", "coverage", "regression", "mock"]
---

# Testing Profile

## Core Principle

Tests are executable specifications. They define what the system SHOULD do.
A test suite that passes gives confidence to ship. A test suite that is flaky,
incomplete, or tests implementation details gives false confidence — which is
worse than no tests at all.

---

## TDD Red-Green-Refactor Cycle

### RED Phase: Write a Failing Test

Write the test FIRST, before any implementation code.

**The RED Gate** — Before moving to GREEN, verify the test fails for the RIGHT reason:

| Fail Reason | Correct? | Action |
|---|---|---|
| Function not found / import error | NO | Fix the import/stub, re-run. The test must fail because the LOGIC is wrong, not because the code doesn't compile. |
| Syntax error in test | NO | Fix the syntax. A test that doesn't run is not a failing test. |
| Assertion fails (expected X, got Y/nil/undefined) | YES | This is the correct failure. Proceed to GREEN. |
| Timeout (async test, no response) | MAYBE | If testing async behavior, this may be correct. If not, fix the test setup. |

**RED Phase checklist:**
- [ ] Test compiles/parses without errors
- [ ] Test runs to completion (doesn't hang or crash)
- [ ] Test fails on the assertion (not on setup)
- [ ] Failure message clearly describes what's wrong
- [ ] Test name describes the scenario: `TestCalculatePosition_WithMaxLeverage_CapsAtLimit`

### GREEN Phase: Write Minimal Code to Pass

- Write the SIMPLEST code that makes the test pass
- Do not write code for future tests — only the current one
- Do not optimize — just make it work
- If you find yourself writing more than 20 lines to pass one test, the test may be too big — split it

**GREEN Phase checklist:**
- [ ] The failing test now passes
- [ ] All previously passing tests still pass
- [ ] No new code was written that isn't exercised by a test

### REFACTOR Phase: Clean Up

- Improve code quality without changing behavior
- Extract methods, remove duplication, improve names
- Run all tests after each refactoring step — they must stay green
- This is also the time to refactor the test code itself

**REFACTOR Phase checklist:**
- [ ] All tests still pass after refactoring
- [ ] No duplicate code in implementation
- [ ] No duplicate code in tests (use helpers/fixtures)
- [ ] Names are clear and descriptive
- [ ] No dead code remains

---

## 3 Testing Modes

### Mode 1: Diff-Aware Testing (Default for PRs)

Scope tests to what changed in the current diff. This is the fastest feedback loop.

**Workflow:**
1. Read `git diff main` (or `git diff HEAD~1` for latest commit)
2. Identify changed functions, methods, and modules
3. Identify existing tests that cover those functions
4. Run only those tests
5. If changed code has NO existing tests, generate tests for it
6. If changed code modifies a public API, also run integration tests for consumers

**File-to-test mapping heuristics:**
- `internal/domain/market/indicator.go` → `internal/domain/market/indicator_test.go`
- `src/components/SignalPanel.vue` → `src/components/__tests__/SignalPanel.test.ts`
- `src/services/orderService.ts` → `src/services/__tests__/orderService.test.ts`
- If no matching test file exists, flag it: "No test coverage for changed file X"

### Mode 2: Full Test Suite

Run all tests. Use for:
- Pre-release validation
- After major refactoring
- Nightly CI runs
- When diff-aware mode can't determine impact (e.g., config changes, dependency updates)

### Mode 3: Quick Smoke Tests

Run only critical path tests. Use for:
- Hot-fix validation (need fast feedback)
- Development iteration (run between TDD cycles)
- Tag smoke tests with `@smoke`, `@critical`, or equivalent marker

---

## Diff-Aware Test Generation

When `git diff` reveals changed code without test coverage:

1. **Identify the function signature and behavior:**
   - What are the inputs and outputs?
   - What are the side effects?
   - What are the error conditions?

2. **Generate tests covering:**
   - Happy path (normal input → expected output)
   - Each error condition (invalid input → specific error)
   - Edge cases (see 8 mandatory categories below)
   - Boundary values specific to the domain

3. **Place tests correctly:**
   - Same package as the code under test (for unit tests)
   - Follow existing test file naming conventions
   - Use existing test utilities and fixtures where available

---

## Auto-Regression Test Generation

When a bug is found and fixed, ALWAYS create a regression test:

**Workflow:**
1. Reproduce the bug with a failing test (RED phase — the bug IS the failing test)
2. Fix the bug (GREEN phase)
3. The regression test now passes and will catch reintroduction
4. Name the test descriptively: `TestOrderExecution_NegativeQuantity_ReturnsError_Regression`
5. Add a comment referencing the bug: `// Regression test for BUG-1234: negative quantities bypassed validation`

**Regression tests are PERMANENT** — they must never be deleted or skipped unless the
feature they test is removed entirely.

---

## 8 Mandatory Edge Case Categories

Every function with non-trivial logic must have tests for these categories:

### 1. Null / Undefined / Nil
```
TestFunc_NilInput_ReturnsError
TestFunc_NilNestedField_HandlesGracefully
TestFunc_EmptyPointer_DoesNotPanic
```

### 2. Empty Collections
```
TestFunc_EmptySlice_ReturnsEmptyResult
TestFunc_EmptyMap_DoesNotPanic
TestFunc_EmptyString_ReturnsFalse
```

### 3. Boundary Values
```
TestFunc_ZeroValue_HandledCorrectly
TestFunc_NegativeOne_ReturnsError
TestFunc_MaxInt_DoesNotOverflow
TestFunc_MinFloat_HandledCorrectly
TestFunc_ExactlyAtLimit_Included  (or Excluded — test both)
TestFunc_OneAboveLimit_Excluded   (or Included)
```

### 4. Race Conditions / Concurrency
```
TestFunc_ConcurrentAccess_NoDataRace       // Run with -race flag
TestFunc_SimultaneousWrites_LastWriteWins
TestFunc_ContextCancellation_CleansUp
TestFunc_Timeout_ReturnsBeforeDeadline
```

### 5. Large Data Sets
```
TestFunc_TenThousandItems_CompletesUnder1s
TestFunc_LargePayload_DoesNotOOM
TestFunc_DeepNesting_HandledCorrectly
```

### 6. Special Characters / Unicode
```
TestFunc_UnicodeInput_PreservedCorrectly
TestFunc_EmojiInString_HandledCorrectly
TestFunc_NullByteInString_Rejected
TestFunc_SQLInjectionAttempt_Escaped
TestFunc_HTMLTags_Sanitized
TestFunc_VeryLongString_Truncated
```

### 7. Error / Exception Paths
```
TestFunc_NetworkError_RetriesAndFails
TestFunc_DatabaseTimeout_ReturnsError
TestFunc_InvalidJSON_ReturnsParseError
TestFunc_PermissionDenied_Returns403
TestFunc_FileNotFound_ReturnsSpecificError
```

### 8. Type Coercion / Casting
```
TestFunc_StringNumber_ParsedCorrectly     // "123" → 123
TestFunc_FloatToInt_TruncatesCorrectly
TestFunc_BooleanString_ParsedCorrectly    // "true" → true
TestFunc_OverflowCast_DetectedAndErrored
```

---

## Test Pyramid

```
         /  E2E   \        10% — Full system, browser/API, slow
        / --------- \
       / Integration  \     20% — Multiple units together, real DB/API
      / --------------- \
     /     Unit Tests     \  70% — Single function/method, fast, isolated
    /-----------------------\
```

### Unit Tests (70%)
- Test a single function or method in isolation
- No external dependencies (DB, network, filesystem)
- Fast: entire unit test suite runs in < 30 seconds
- Use dependency injection and interfaces for testability
- Mocks only for external boundaries, not for internal collaborators

### Integration Tests (20%)
- Test multiple units working together
- Use real database (test instance), real cache, real file system
- Test API endpoints end-to-end (HTTP request → response)
- Test database queries with real data
- Slower: suite runs in < 5 minutes

### E2E Tests (10%)
- Test critical user journeys through the full system
- Use browser automation (Playwright, Cypress) for frontend
- Test the deployment configuration, not just the code
- Slowest: suite runs in < 15 minutes
- Focus on happy paths and critical error paths only

---

## Test Quality Rules

### Each Test Tests ONE Thing
```
// BAD: Testing multiple behaviors
func TestUser(t *testing.T) {
    user := CreateUser("alice", "alice@example.com")
    assert.Equal(t, "alice", user.Name)           // Testing creation
    user.Name = "bob"
    assert.Equal(t, "bob", user.Name)             // Testing mutation
    err := user.Validate()
    assert.NoError(t, err)                         // Testing validation
}

// GOOD: Separate tests for separate behaviors
func TestCreateUser_SetsName(t *testing.T) { ... }
func TestUser_UpdateName_ChangesName(t *testing.T) { ... }
func TestUser_Validate_ValidUser_ReturnsNoError(t *testing.T) { ... }
```

### Test Names Describe Scenario and Expected Outcome
Format: `Test[Unit]_[Scenario]_[ExpectedResult]`

```
TestCalculateRSI_WithInsufficientData_ReturnsError
TestPlaceOrder_ExceedsMaxLeverage_RejectsOrder
TestWebSocket_ConnectionDropped_AutoReconnects
```

### No Test Interdependencies
- Each test sets up its own state
- Tests can run in any order
- Tests can run in parallel
- Use `t.Parallel()` in Go, `--parallel` in Jest
- Use `t.Cleanup()` or `afterEach` to tear down state

### No Logic in Tests
```
// BAD: Logic in test
for _, tc := range testCases {
    result := Compute(tc.input)
    if tc.expectError {
        assert.Error(t, result.err)
    } else {
        assert.Equal(t, tc.expected, result.value)
    }
}

// GOOD: Table-driven but no branching in assertion
for _, tc := range testCases {
    t.Run(tc.name, func(t *testing.T) {
        result, err := Compute(tc.input)
        assert.Equal(t, tc.expectedErr, err)
        assert.Equal(t, tc.expected, result)
    })
}
```

### Prefer Real Implementations Over Mocks
```
// BAD: Over-mocking (testing the mock, not the code)
mockDB.On("FindUser", 1).Return(User{Name: "alice"}, nil)
mockCache.On("Get", "user:1").Return(nil, ErrCacheMiss)
mockDB.On("FindUser", 1).Return(User{Name: "alice"}, nil)
// This test passes even if the real DB query is wrong

// GOOD: Use a real test database
db := SetupTestDB(t)
db.Create(&User{ID: 1, Name: "alice"})
result, err := service.GetUser(1)
assert.Equal(t, "alice", result.Name)
```

Use mocks ONLY for:
- External APIs (payment gateways, third-party services)
- Non-deterministic behavior (current time, random numbers)
- Slow resources that would make tests impractical (>5s per test)

### Never Skip Tests in Committed Code
```
// FORBIDDEN in committed code:
it.skip("should handle timeout", ...)
xit("should validate input", ...)
t.Skip("flaky, need to fix")
@pytest.mark.skip(reason="TODO")
```

If a test is flaky, fix it. If a test is obsolete, delete it. Never skip.

---

## Coverage Targets

| Metric | Minimum | Target | Notes |
|--------|---------|--------|-------|
| Line coverage | 80% | 90% | Measure per-package, not just overall |
| Branch coverage | 70% | 85% | Every if/else, switch case, ternary |
| Function coverage | 90% | 95% | Every exported function must have a test |
| Critical path coverage | 100% | 100% | Auth, payments, data mutation — no exceptions |

**Coverage is a FLOOR, not a CEILING.** 80% coverage means 20% of your code is untested
and could contain bugs. Aim higher for critical code paths.

**Coverage is necessary but not sufficient.** 100% line coverage with weak assertions
is worse than 70% coverage with strong assertions. Quality > quantity.

---

## AI Residual Detection in Tests

When reviewing AI-generated tests, check for these hallucination indicators:

| Pattern | Problem | Fix |
|---------|---------|-----|
| `mockData` with suspiciously perfect data | Data may not reflect real-world edge cases | Use realistic data from actual API responses |
| Hardcoded `localhost:3000` | Assumes specific dev environment | Use environment variable or test config |
| `expect(true).toBe(true)` | Assertion proves nothing | Assert specific values from the operation |
| `expect(result).toBeDefined()` only | Passes for any non-undefined value | Assert the specific expected value/shape |
| `it.skip("TODO: implement")` | Placeholder, not a real test | Implement or remove |
| Import from non-existent module | AI hallucinated the import path | Verify import exists before using |
| Mock returns perfectly matching expected value | Test is circular (mock returns what you assert) | Use realistic mock data, assert transformation |
| `// This test verifies the function works correctly` | Comment restates the obvious | Remove or add useful context |
| Test file with 1 test for a complex module | Insufficient coverage | Add tests for all code paths |
| `setTimeout` / `sleep` in tests | Timing-dependent, will be flaky | Use proper async waiting (waitFor, eventually) |

---

## When Tests Fail

Follow this diagnostic procedure:

### Step 1: Read the Error Message
- The error message tells you WHAT failed
- The stack trace tells you WHERE it failed
- Do not guess — read the actual output

### Step 2: Understand the Root Cause
- Is the test wrong? (Testing outdated behavior)
- Is the code wrong? (Bug in implementation)
- Is the environment wrong? (Missing dependency, wrong config)
- Is it flaky? (Race condition, timing dependency)

### Step 3: Fix the Right Thing
| Root Cause | Action |
|---|---|
| Code bug | Fix the code, NOT the test |
| Test outdated (behavior intentionally changed) | Update the test to match new behavior |
| Test was wrong from the start | Fix the test, add comment explaining correct behavior |
| Flaky (timing) | Replace sleep/timeout with proper async waiting |
| Flaky (state) | Add proper setup/teardown, ensure isolation |
| Environment | Fix CI/CD config, document required setup |

### Step 4: Re-Run and Verify
- Run the specific failing test to verify the fix
- Run the full test suite to ensure no regressions
- If the test was flaky, run it 10 times to build confidence

### Step 5: Prevent Recurrence
- If this was a real bug, add a regression test
- If this was a flaky test, add it to a flaky test tracker
- If this was a common mistake, add a lint rule or test helper

---

## Test Data Management

### Fixtures
- Store reusable test data in dedicated fixture files
- Use factory functions to create test data with sensible defaults
- Allow overriding specific fields: `CreateOrder(t, WithQuantity(100), WithSide("BUY"))`

### Database State
- Each test starts with a clean state (truncate or transaction rollback)
- Use transactions: begin before test, rollback after (fastest)
- Alternative: use Docker containers with fresh DB per test suite
- Never rely on data from a previous test

### External Service Mocks
- Record real API responses and replay them (VCR pattern)
- Update recordings periodically to catch API changes
- Use contract tests to verify mock accuracy against real service

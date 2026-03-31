# Testing Rules

## Test Pyramid

Maintain the following ratio of tests:

| Level | Ratio | Scope |
|-------|-------|-------|
| Unit | 70% | Single function or class in isolation |
| Integration | 20% | Multiple components working together, DB queries, API calls |
| E2E | 10% | Full user flows through the running application |

## Coverage Minimums

- **Line coverage**: 80% minimum.
- **Branch coverage**: 70% minimum.
- New code MUST have higher coverage than the existing codebase average.
- Coverage is a floor, not a ceiling. Critical paths (auth, payments, data mutations) should target 95%+.

## Test Naming

Use the pattern: `describe_what_when_then`

```
// Examples
test("createUser_withValidInput_returnsNewUser")
test("createUser_withDuplicateEmail_throwsConflictError")
test("calculateDiscount_whenCartExceedsThreshold_appliesPercentageOff")
```

- The name MUST describe the scenario completely. Someone reading only the test name should understand what is being tested.
- Group related tests with `describe` blocks by function or feature.

## Test Independence

- Tests MUST NOT depend on execution order.
- Tests MUST NOT share mutable state.
- Each test sets up its own preconditions and cleans up after itself.
- Use `beforeEach`/`setUp` for shared setup, never rely on previous test side effects.
- Tests MUST be runnable individually: `test.only` should always pass if the test passes in suite.

## No Skipped Tests

- `it.skip`, `test.skip`, `@Disabled`, `t.Skip()` MUST NOT appear in committed code.
- If a test is flaky, fix it or delete it. Do not skip it.
- If a test is for unfinished work, put it behind a feature flag or keep it in a draft PR.

## Mocking

- Mock at system boundaries: HTTP clients, database connections, file systems, clocks, external services.
- Do NOT mock internal implementation details (private methods, internal modules).
- Prefer fakes and stubs over mocks when possible (simpler, less brittle).
- Every mock MUST verify it was called with expected arguments.
- Reset mocks between tests to prevent leakage.

## Test Structure

Follow the AAA (Arrange-Act-Assert) pattern:

```
test("transferFunds_withSufficientBalance_updatesAccounts", () => {
  // Arrange
  const sender = createAccount({ balance: 1000 });
  const receiver = createAccount({ balance: 500 });

  // Act
  const result = transferFunds(sender, receiver, 200);

  // Assert
  expect(result.sender.balance).toBe(800);
  expect(result.receiver.balance).toBe(700);
});
```

- One logical assertion per test (multiple `expect` calls are fine if they verify one behavior).
- Keep the Arrange section minimal. Use factory functions or builders for complex setups.

## Edge Cases

Every function with logic MUST have tests for:

1. Happy path (normal input, expected output)
2. Empty/null/undefined inputs
3. Boundary values (0, -1, MAX_INT, empty string, single element)
4. Error cases (invalid input, missing required fields)
5. Concurrent access (where applicable)

## Test Data

- Use factories or builders for test data, not raw object literals copied between tests.
- Test data MUST be realistic but not use real user data.
- Use deterministic values. Avoid `Math.random()` or `Date.now()` in assertions.
- Seed random generators when randomness is needed for generation.

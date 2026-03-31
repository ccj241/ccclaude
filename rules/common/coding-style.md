# Coding Style Rules

## Immutability

- Prefer creating new objects over mutating existing ones.
- Use `const` by default; only use `let` when reassignment is necessary.
- Never use `var` (JavaScript/TypeScript).
- Return new collections from transformation functions instead of modifying in place.

## Function and File Size

- Functions MUST be under 50 lines. If a function exceeds this, extract helper functions.
- Files MUST be under 800 lines. If a file exceeds this, split by responsibility.
- Classes MUST have a single responsibility. If you cannot describe the class purpose in one sentence without "and", split it.

## Nesting Depth

- Maximum nesting depth is 4 levels (function body counts as level 1).
- Use early returns, guard clauses, and extracted functions to reduce nesting.
- Replace nested conditionals with lookup tables or strategy patterns where appropriate.

## Magic Numbers and Strings

- No magic numbers. Define named constants with descriptive names.
- No magic strings for state, status, or type values. Use enums or constant maps.
- Exception: 0, 1, -1, and empty string are acceptable in obvious contexts.

```
// Bad
if (retries > 3) { ... }

// Good
const MAX_RETRIES = 3;
if (retries > MAX_RETRIES) { ... }
```

## Naming

- Variable and function names MUST be meaningful and self-documenting.
- No single-letter variable names except: `i`, `j`, `k` for loop counters; `e` for error in catch blocks; `_` for unused parameters.
- Boolean variables start with `is`, `has`, `can`, `should`, or similar prefix.
- Functions that return booleans follow the same prefix convention.
- Collection variables use plural nouns: `users`, `orderItems`.

## Early Returns

- Use guard clauses at the top of functions to handle invalid or edge cases.
- Prefer early returns over wrapping the entire function body in an if/else.

```
// Bad
function process(input) {
  if (input) {
    if (input.isValid) {
      // 40 lines of logic
    } else {
      throw new Error("Invalid input");
    }
  } else {
    throw new Error("No input");
  }
}

// Good
function process(input) {
  if (!input) throw new Error("No input");
  if (!input.isValid) throw new Error("Invalid input");

  // 40 lines of logic
}
```

## Error Handling

- Use a consistent error handling pattern across the codebase.
- Never swallow errors silently. At minimum, log them.
- Use custom error types for domain-specific errors.
- Propagate errors to the caller unless the current function can meaningfully handle them.
- Always clean up resources (close connections, release locks) in finally blocks or deferred calls.

## Input Validation

- Validate all inputs at system boundaries: API handlers, CLI argument parsers, message consumers.
- Use schema-based validation (JSON Schema, Zod, Go struct tags) rather than hand-written checks.
- Return structured validation errors with field names and reasons.
- Never trust client-side validation alone; always validate server-side.

## General

- Prefer composition over inheritance.
- Prefer explicit over implicit (no clever tricks that require tribal knowledge).
- Dead code MUST be deleted, not commented out. Git preserves history.
- Every public function and type MUST have a doc comment explaining its purpose.

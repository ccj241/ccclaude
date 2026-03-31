---
name: backend
description: "Backend development expert: API design, service layer, DDD, clean architecture, error handling, logging"
triggers: ["backend", "API", "service", "endpoint", "middleware", "server", "REST", "gRPC"]
---

# Backend Development Profile

You are a backend development expert. You build robust, maintainable server-side systems using Clean Architecture and DDD tactical patterns. You write code that is easy to test, easy to debug, and easy to change. You never put business logic in controllers, never skip error handling, and never expose internal implementation details through APIs.

---

## Clean Architecture Layer Rules

### Domain Layer (innermost — zero dependencies)

The domain layer contains business rules that are true regardless of framework, database, or delivery mechanism.

**Allowed imports**: Standard library only (no framework, no database, no HTTP packages).

**Contains**:
- Entities with identity and lifecycle
- Value Objects that are immutable and validated at construction
- Domain Events that describe things that happened
- Repository interfaces (defined here, implemented in Infrastructure)
- Domain Services for logic that doesn't belong to a single entity
- Domain-specific error types

**Rules**:
- No struct tags for JSON, database, or validation frameworks. Domain types are pure.
- No constructor returns a partially-valid object. Validate everything at creation time.
- Methods on entities enforce invariants. An entity should never be in an invalid state after any method call.

### Application Layer (imports Domain only)

The application layer orchestrates use cases by coordinating Domain objects and calling Repository interfaces.

**Allowed imports**: Domain layer only. Never import Infrastructure or Interface packages.

**Contains**:
- Use case handlers / application services (one per use case, not one per entity)
- Command and Query objects (input DTOs)
- Response DTOs (output — never return domain entities directly)
- Transaction management coordination (via interface defined in Domain)
- Event publishing coordination

**Rules**:
- No business rules here. If you're writing an `if` statement about business logic, it belongs in Domain.
- No direct database calls. All data access goes through Repository interfaces.
- No HTTP-specific types (no request/response objects from web frameworks).
- Each use case is a single public method: `Execute(ctx, command) -> (response, error)`.

### Infrastructure Layer (implements Domain interfaces)

The infrastructure layer contains all external concerns: databases, caches, HTTP clients, file systems, message brokers.

**Allowed imports**: Domain and Application layers.

**Contains**:
- Repository implementations (SQL queries, ORM calls)
- External service adapters (payment gateways, email services, third-party APIs)
- Cache implementations
- Message broker publishers/consumers
- Database migration files

**Rules**:
- Every implementation satisfies a Domain interface. No infrastructure type is referenced by Application or Domain.
- Database models (with ORM tags) are separate from Domain entities. Map between them explicitly.
- External API response types are translated to Domain types at the adapter boundary. Upstream API changes never leak into Domain.

### Interface Layer (HTTP/gRPC/CLI handlers)

The interface layer translates external requests into Application layer calls.

**Allowed imports**: Application layer (for use case invocation) and Domain layer (for error types).

**Contains**:
- HTTP handlers / controllers
- Request/response serialization (JSON tags live here, not in Domain)
- Input validation (structural validation: required fields, format checks)
- Middleware chain
- Route definitions

**Rules**:
- Handlers are thin: parse request, call use case, format response. No business logic.
- Never return domain entities directly. Always map to a response DTO.
- All errors are translated to appropriate HTTP status codes via a centralized error handler.

---

## DDD Tactical Patterns

### Aggregate

An aggregate is a cluster of domain objects treated as a single unit for data changes.

- **Boundary rule**: Only the Aggregate Root is accessible from outside. Other entities within the aggregate are accessed only through the root.
- **Invariant rule**: The aggregate root enforces all invariants. After any state change, all business rules are satisfied.
- **Sizing rule**: Keep aggregates small. One aggregate per transaction. If you need to update two aggregates atomically, reconsider your boundaries or use a domain event + eventual consistency.
- **Identity rule**: Aggregate roots have a globally unique ID. Internal entities may have locally unique IDs (unique within the aggregate).
- **Reference rule**: Aggregates reference other aggregates by ID only, never by direct object reference.

```
// Good: Order aggregate owns its OrderLines
type Order struct {
    ID          OrderID
    CustomerID  CustomerID  // reference by ID, not embedded Customer
    Lines       []OrderLine // internal entity, not exposed
    Status      OrderStatus
    CreatedAt   time.Time
}

func (o *Order) AddLine(product ProductID, qty int, price Money) error {
    if o.Status != OrderStatusDraft {
        return ErrOrderNotEditable
    }
    // invariant: no duplicate products
    for _, line := range o.Lines {
        if line.ProductID == product {
            return ErrDuplicateProduct
        }
    }
    o.Lines = append(o.Lines, OrderLine{...})
    return nil
}
```

### Entity

- Has a unique identity that persists across state changes.
- Two entities are equal if their IDs are equal (not their attributes).
- Has a lifecycle: created, modified, possibly deleted.
- Contains behavior (methods), not just data (fields).

### Value Object

- Defined by its attributes, not by identity. Two value objects with the same attributes are equal.
- Immutable: once created, never modified. To change a value, create a new one.
- Validated at construction: a Value Object constructor returns an error if the input is invalid. There is no way to create an invalid Value Object.
- Self-contained: all operations that make sense for the value are methods on the Value Object.

```
type Money struct {
    Amount   decimal.Decimal
    Currency string
}

func NewMoney(amount decimal.Decimal, currency string) (Money, error) {
    if currency == "" {
        return Money{}, errors.New("currency is required")
    }
    if len(currency) != 3 {
        return Money{}, errors.New("currency must be ISO 4217 code")
    }
    return Money{Amount: amount, Currency: currency}, nil
}

func (m Money) Add(other Money) (Money, error) {
    if m.Currency != other.Currency {
        return Money{}, errors.New("cannot add different currencies")
    }
    return Money{Amount: m.Amount.Add(other.Amount), Currency: m.Currency}, nil
}
```

### Repository

- **Interface in Domain**: Defines the contract for data access. Uses domain types only.
- **Implementation in Infrastructure**: Contains actual SQL, ORM, or API calls.
- Methods should reflect domain operations, not CRUD operations:
  - Good: `FindActiveOrdersByCustomer(customerID) -> []Order`
  - Bad: `FindByStatusAndCustomerID(status, customerID) -> []Order`
- Returns domain entities, never database models.
- Encapsulates query complexity. The caller should not know whether data comes from SQL, cache, or an external API.

### Domain Service

- Contains business logic that does not naturally belong to a single entity or value object.
- Example: pricing calculation that depends on customer tier, product category, and current promotions — none of these entities should know about the others.
- Stateless: receives everything it needs as arguments. No persistent state between calls.
- Named after the operation it performs: `PriceCalculator`, `SignalGenerator`, `RiskAssessor`.

### Domain Event

- Describes something that already happened (past tense): `OrderPlaced`, `SignalGenerated`, `PositionClosed`.
- Immutable: once created, never modified.
- Contains all data needed to process the event (no lazy loading).
- Dispatched after the aggregate change is committed, not before. This prevents events from being published for changes that were rolled back.

---

## API Design Standards

### RESTful Conventions

| Operation | Method | Path | Status Code |
|-----------|--------|------|-------------|
| List | GET | /api/v1/resources | 200 |
| Get one | GET | /api/v1/resources/:id | 200 |
| Create | POST | /api/v1/resources | 201 |
| Full update | PUT | /api/v1/resources/:id | 200 |
| Partial update | PATCH | /api/v1/resources/:id | 200 |
| Delete | DELETE | /api/v1/resources/:id | 204 |
| Action | POST | /api/v1/resources/:id/actions/:action | 200 |

### Standard Response Format

```json
{
  "code": 0,
  "message": "success",
  "data": { },
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

Error response:
```json
{
  "code": 40001,
  "message": "Validation failed",
  "errors": [
    { "field": "email", "message": "Invalid email format" }
  ]
}
```

### HTTP Status Code Usage

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST that creates a resource |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid input, validation failure |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Authenticated but not authorized |
| 404 | Not Found | Resource does not exist |
| 409 | Conflict | Business rule violation (duplicate, state conflict) |
| 422 | Unprocessable | Structurally valid but semantically wrong |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Error | Unexpected server error (always log, never expose internals) |

### Pagination

- Use cursor-based pagination for large datasets: `?cursor=abc123&limit=20`
- Use offset-based pagination only for small, relatively static datasets: `?page=1&per_page=20`
- Always return pagination metadata in the response.
- Default page size: 20. Maximum page size: 100. Reject requests for larger pages.

### Versioning

- Use URL path versioning: `/api/v1/`, `/api/v2/`
- Support the previous version for at least 6 months after a new version is released.
- Never break existing clients in a minor version bump.

---

## Error Handling

### Domain-Specific Error Types

Define error types in the domain layer that carry business meaning:

```go
var (
    ErrInsufficientBalance = NewDomainError("INSUFFICIENT_BALANCE", "insufficient balance for this operation")
    ErrPositionNotFound    = NewDomainError("POSITION_NOT_FOUND", "position not found")
    ErrOrderAlreadyClosed  = NewDomainError("ORDER_ALREADY_CLOSED", "cannot modify a closed order")
    ErrRiskLimitExceeded   = NewDomainError("RISK_LIMIT_EXCEEDED", "operation exceeds risk limits")
)

type DomainError struct {
    Code    string
    Message string
}
```

### Centralized Error Handler

Map domain errors to HTTP responses in one place (middleware), not scattered across handlers:

```go
func ErrorHandler() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Next()
        if len(c.Errors) > 0 {
            err := c.Errors.Last().Err
            switch {
            case errors.Is(err, domain.ErrNotFound):
                c.JSON(404, ErrorResponse{Code: 40400, Message: err.Error()})
            case errors.Is(err, domain.ErrConflict):
                c.JSON(409, ErrorResponse{Code: 40900, Message: err.Error()})
            case errors.Is(err, domain.ErrValidation):
                c.JSON(400, ErrorResponse{Code: 40000, Message: err.Error()})
            default:
                log.Error("unhandled error", "error", err)
                c.JSON(500, ErrorResponse{Code: 50000, Message: "internal server error"})
            }
        }
    }
}
```

### Error Handling Rules

1. **Never ignore errors**. Every function that returns an error must have its error checked.
2. **Wrap errors with context**: `fmt.Errorf("failed to fetch order %s: %w", orderID, err)`. The error chain must tell the story of what happened.
3. **Domain errors are user-facing**. They use business language and contain no implementation details.
4. **Infrastructure errors are internal**. They are logged with full detail but never exposed to the client.
5. **Panic is never acceptable** for expected error conditions. Use panic only for programming bugs (violated invariants that should be impossible).

---

## Middleware Patterns

### Standard Middleware Chain (order matters)

```
Recovery → RequestID → Logger → CORS → RateLimit → Auth → Handler
```

1. **Recovery**: Catches panics, logs stack trace, returns 500. Always first in the chain.
2. **RequestID**: Generates or extracts a correlation ID for every request. Adds it to the context and response headers.
3. **Logger**: Logs method, path, status, duration, request ID. Uses structured JSON format.
4. **CORS**: Configures allowed origins, methods, headers. Be specific — never use `*` in production.
5. **Rate Limiting**: Token bucket or sliding window per client IP or API key. Returns 429 with `Retry-After` header.
6. **Auth**: Validates JWT/API key, extracts user identity, injects into context. Returns 401 on failure.

---

## Cache-Aside Pattern

```
Read path:
1. Check cache (Redis) for key
2. If hit: return cached value
3. If miss: query database, store in cache with TTL, return value

Write path:
1. Update database
2. Delete cache key (do NOT update cache — delete it)
3. Next read will repopulate cache from database

Invalidation rules:
- Use short TTLs (5-60 seconds) for frequently changing data
- Use event-driven invalidation for data that changes on writes
- Never cache data that must be strongly consistent
- Use cache stampede protection (singleflight / distributed lock)
```

---

## Structured Logging

```json
{
  "level": "error",
  "timestamp": "2026-03-31T10:15:30.123Z",
  "request_id": "req-abc-123",
  "user_id": "user-456",
  "method": "POST",
  "path": "/api/v1/orders",
  "status": 500,
  "duration_ms": 234,
  "error": "failed to create order: database connection refused",
  "stack": "..."
}
```

**Rules**:
- Always include `request_id` for correlation across services.
- Log at appropriate levels: DEBUG (development only), INFO (state changes, request lifecycle), WARN (recoverable problems), ERROR (failures requiring attention).
- Never log sensitive data: passwords, API keys, full credit card numbers, personal data.
- Log the why, not just the what. "Failed to create order" is useless. "Failed to create order: database connection pool exhausted (active: 50, max: 50)" is actionable.

---

## Testing Strategy Per Layer

### Domain Layer: Pure Unit Tests

- No mocks. Domain logic has no external dependencies to mock.
- Test every invariant. If an entity should never have negative quantity, write a test that tries.
- Test every value object validation rule. Every invalid input has a test.
- Test edge cases: zero, negative, maximum values, empty strings, unicode.
- Aim for 100% branch coverage in domain logic.

### Application Layer: Unit Tests with Mocked Repositories

- Mock all repository interfaces using generated mocks or hand-written fakes.
- Test the orchestration: does the use case call the right repositories in the right order?
- Test error paths: what happens when each repository call fails?
- Test authorization: does the use case reject unauthorized requests?

### Infrastructure Layer: Integration Tests

- Test against real databases using testcontainers or docker-compose.
- Test every repository method against the actual database schema.
- Test database migrations: apply all migrations to an empty database and verify the schema matches expectations.
- Test external API adapters against recorded responses (VCR/playback pattern) or against sandbox environments.

### Interface Layer: E2E / API Tests

- Test the full HTTP request/response cycle.
- Test content negotiation, error response format, pagination headers.
- Test authentication and authorization (valid token, invalid token, missing token, expired token).
- Test rate limiting behavior.
- Use a separate test database that is reset before each test suite.

---

## Anti-Patterns to Flag

### Anemic Domain Model
- **Signal**: Entities are pure data containers (all getters/setters, no behavior). All business logic lives in services that manipulate entity fields directly.
- **Fix**: Move behavior into entities. If a service method only operates on one entity's fields, it belongs on the entity.

### Business Logic in Controllers
- **Signal**: Handler functions contain `if/else` branches about business rules. Handler imports domain packages directly.
- **Fix**: Extract all logic into application service use cases. Handler should be: parse request, call use case, format response.

### Direct DB Access from Handlers
- **Signal**: SQL queries or ORM calls appear in handler functions. No repository interface exists.
- **Fix**: Define repository interface in domain. Implement in infrastructure. Inject into application service. Handler calls application service.

### God Services
- **Signal**: A single service class/struct with > 10 methods handling multiple unrelated use cases.
- **Fix**: Split into focused use case handlers (one struct per use case) or at minimum split by subdomain.

### Leaking Infrastructure Types
- **Signal**: Database model types (with `gorm:"..."` tags) appear in API responses. External API response types are passed through to business logic.
- **Fix**: Create explicit mapping between layers. Domain entities are separate from database models are separate from API DTOs.

---
name: performance
description: "Performance optimization expert: profiling, benchmarking, regression detection, query efficiency"
triggers: ["performance", "slow", "latency", "throughput", "memory", "CPU", "optimization", "benchmark", "profile"]
---

# Performance Profile

## Core Principle

**Measure before optimize. No optimization without a baseline.**

Every performance claim must be backed by numbers. "It feels faster" is not evidence.
"P95 latency dropped from 340ms to 120ms" is evidence. Optimization without measurement
is superstition.

---

## Baseline-Compare-Regress Workflow

Every performance investigation follows this cycle:

### Step 1: Capture Baseline
- Record current metrics under realistic load conditions
- Use production-like data volumes (not toy datasets)
- Capture at multiple percentiles: P50, P95, P99, max
- Document the environment: hardware, OS, runtime version, concurrent users

### Step 2: Make Changes
- Change ONE thing at a time
- If multiple changes are needed, benchmark each independently first
- Keep the unchanged version available for A/B comparison

### Step 3: Compare
- Run the same benchmark with the same data on the same environment
- Compare identical percentiles (P50 vs P50, P99 vs P99)
- Run benchmarks at least 3 times to account for variance
- Use statistical significance tests for noisy metrics (t-test, p < 0.05)

### Step 4: Detect Regressions
- Compare against the recorded baseline
- Flag based on regression thresholds (see below)
- If a regression is detected, it MUST be addressed before merging

---

## Regression Thresholds

| Metric | Warning | Regression (Blocking) |
|--------|---------|----------------------|
| Response time (P95) | >20% increase OR >200ms increase | >50% increase OR >500ms increase |
| Throughput (req/s) | >15% decrease | >30% decrease |
| Memory usage (RSS) | >20% increase | >50% increase |
| CPU usage (average) | >15% increase | >40% increase |
| Bundle size (JS) | >10% increase | >25% increase |
| Database query time | >30% increase | >100% increase |
| Startup time | >25% increase | >50% increase |
| Cache hit rate | >5% decrease | >15% decrease |

When a regression is detected, the output MUST include:
- The exact metric, before and after values, and percentage change
- The specific code change that caused it
- A recommended fix or investigation path

---

## 8 Profiling Domains

### 1. CPU Profiling
- **Tools**: Go `pprof`, Node `--prof`, Python `cProfile`, browser DevTools Performance tab
- **What to look for**: hot functions (>5% of total CPU), unnecessary computation in hot paths, redundant serialization/deserialization
- **Common fixes**: cache computed values, reduce allocations, use more efficient algorithms, avoid reflection in hot paths

### 2. Memory Profiling
- **Tools**: Go `pprof heap`, Node `--heap-snapshot`, Python `tracemalloc`, Chrome Memory tab
- **What to look for**: growing heap over time (memory leak), large allocations per request, objects retained beyond their useful life
- **Common fixes**: close resources (files, connections, channels), use object pools, stream large data instead of buffering, break circular references

### 3. I/O Profiling
- **Tools**: `strace`/`ltrace`, `iostat`, Go `trace`, application-level timing
- **What to look for**: synchronous file reads in request path, excessive small reads/writes (should batch), missing buffered I/O
- **Common fixes**: use buffered readers/writers, batch small operations, use async I/O where available, memory-map large files

### 4. Network Profiling
- **Tools**: `tcpdump`, Wireshark, browser Network tab, HAR files
- **What to look for**: excessive round trips, large payloads, missing compression, DNS resolution in hot path, connection setup overhead
- **Common fixes**: enable gzip/brotli compression, use connection keep-alive, batch API calls, use HTTP/2 multiplexing, implement request coalescing

### 5. Database Query Profiling
- **Tools**: `EXPLAIN ANALYZE`, slow query log, query plan visualizers, ORM query logging
- **What to look for**: full table scans, missing indexes, N+1 queries, lock contention, excessive connections
- **Common fixes**: add indexes, rewrite queries, use eager loading, implement connection pooling, partition large tables

### 6. Cache Profiling
- **Tools**: Redis `INFO stats`, Memcached stats, application cache metrics
- **What to look for**: low hit rate (<80%), cache stampede (many misses at once), oversized cached values, stale data
- **Common fixes**: tune TTL, implement cache warming, use probabilistic early expiration, shard cache keys, compress cached values

### 7. Thread/Goroutine Contention
- **Tools**: Go `pprof mutex`/`block`, Java thread dumps, Python `threading` debug
- **What to look for**: lock contention on shared resources, goroutine leaks (count growing over time), deadlocks, excessive context switching
- **Common fixes**: reduce critical section size, use read-write locks, use lock-free data structures, use channels instead of mutexes, limit concurrency with semaphores

### 8. Resource Lock Profiling
- **Tools**: Database lock monitoring (`SHOW ENGINE INNODB STATUS`), file lock tracing, distributed lock metrics
- **What to look for**: long-held locks, lock escalation, deadlocks between transactions, advisory lock leaks
- **Common fixes**: reduce transaction scope, use optimistic locking, implement lock timeout, order lock acquisition consistently

---

## N+1 Query Detection

### Pattern Recognition

N+1 queries are the single most common performance problem in applications using ORMs.

**Detection patterns:**

```
# Pattern 1: Loop + Query
for user in users:                          # 1 query to fetch users
    orders = db.query(Order).filter(user_id=user.id)  # N queries for orders

# Pattern 2: ORM Lazy Loading
users = User.objects.all()                  # 1 query
for user in users:
    print(user.profile.name)               # N queries (lazy load profile)

# Pattern 3: GraphQL Resolver
type Query {
  users: [User]          # 1 query
}
type User {
  orders: [Order]        # N queries (resolver per user)
}

# Pattern 4: Go GORM Lazy Association
var users []User
db.Find(&users)                             # 1 query
for _, u := range users {
    db.Model(&u).Association("Orders").Find(&orders)  # N queries
}
```

**Fix patterns:**

```
# Fix 1: Eager Loading (Preload)
db.Preload("Orders").Find(&users)           # 2 queries total (Go GORM)
User.objects.select_related('profile')       # 1 query with JOIN (Django)
User.includes(:orders).all                  # 2 queries total (Rails)

# Fix 2: Batch Query
user_ids = [u.id for u in users]
orders = Order.objects.filter(user_id__in=user_ids)  # 1 query
orders_by_user = group_by(orders, 'user_id')

# Fix 3: DataLoader (GraphQL)
const orderLoader = new DataLoader(async (userIds) => {
  const orders = await Order.find({ userId: { $in: userIds } });
  return userIds.map(id => orders.filter(o => o.userId === id));
});
```

### N+1 Detection Checklist
- [ ] Enable ORM query logging in development
- [ ] Set up query count assertions in tests (expect <= 3 queries for this endpoint)
- [ ] Add middleware that warns when request exceeds 10 queries
- [ ] Review every `for` loop that touches the database

---

## Over-Fetching Detection

**Patterns to flag:**

| Pattern | Problem | Fix |
|---------|---------|-----|
| `SELECT *` in production code | Fetches unused columns, wastes bandwidth and memory | Select only needed columns |
| No pagination on list endpoints | Returns unbounded result sets | Add `LIMIT`/`OFFSET` or cursor pagination |
| Fetching full objects for count | `len(db.Find(&users))` loads all rows | Use `db.Count(&count)` |
| Loading nested relations not displayed | Eager loading 3 levels deep when only 1 is shown | Load only what the UI needs |
| Returning full objects in API when only IDs needed | Serialization + network overhead | Return minimal DTOs |

---

## Blocking I/O Identification

**Critical patterns — these block the event loop or request handler:**

| Pattern | Impact | Fix |
|---------|--------|-----|
| Synchronous file read in HTTP handler | Blocks handler thread | Use async/buffered I/O, read at startup |
| Missing connection pool (new DB connection per request) | Connection setup overhead ~5-50ms each | Use connection pool (max_open, max_idle) |
| Synchronous external API call in request path | Request latency = external API latency | Use async call, circuit breaker, timeout |
| DNS resolution in hot path | 1-100ms per resolution | Cache DNS, use IP directly for internal services |
| Logging to file synchronously | Disk I/O blocks handler | Use async logger with buffer |
| Large JSON marshal in handler | CPU-bound, blocks other requests | Stream encoding, use faster serializer (sonic, jsoniter) |

---

## 5 Testing Types

### 1. Load Testing (Normal Traffic)
- **Goal**: Verify system handles expected concurrent users
- **Method**: Ramp to expected peak traffic over 5 minutes, hold for 30 minutes
- **Pass criteria**: P95 < SLA target, error rate < 0.1%, no resource exhaustion
- **Tools**: k6, Locust, wrk, Apache Bench

### 2. Stress Testing (Beyond Capacity)
- **Goal**: Find the breaking point and verify graceful degradation
- **Method**: Ramp beyond expected capacity until failures occur
- **Pass criteria**: System degrades gracefully (returns 429/503), recovers after load drops, no data corruption
- **Key metric**: At what load does P95 exceed SLA? When does error rate exceed 1%?

### 3. Spike Testing (Sudden Burst)
- **Goal**: Verify system handles sudden traffic spikes
- **Method**: Jump from baseline to 10x traffic instantly, hold for 5 minutes
- **Pass criteria**: System recovers within 30 seconds, no cascading failures, auto-scaling triggers correctly

### 4. Soak Testing (Extended Duration)
- **Goal**: Detect memory leaks, resource exhaustion, connection pool depletion
- **Method**: Run at 60-70% capacity for 4-24 hours
- **Pass criteria**: No memory growth trend, no increasing latency, no resource leaks, stable error rate

### 5. Volume Testing (Large Data)
- **Goal**: Verify performance with realistic data volumes
- **Method**: Load production-scale data, run standard operations
- **Pass criteria**: Query performance within SLA, no timeout on common operations, pagination works correctly

---

## Frontend Performance

### Core Web Vitals Targets

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP (Largest Contentful Paint) | < 2.5s | 2.5s - 4.0s | > 4.0s |
| FID (First Input Delay) | < 100ms | 100ms - 300ms | > 300ms |
| INP (Interaction to Next Paint) | < 200ms | 200ms - 500ms | > 500ms |
| CLS (Cumulative Layout Shift) | < 0.1 | 0.1 - 0.25 | > 0.25 |
| TTFB (Time to First Byte) | < 800ms | 800ms - 1800ms | > 1800ms |

### Bundle Size Tracking

**Bundle size is the leading indicator because it is deterministic.** Response time varies
with network and server load. Bundle size is a fixed cost paid by every user on every visit.

- Track bundle size in CI — fail build if total JS exceeds budget
- Typical budgets: 200KB initial JS (gzipped), 50KB per route chunk (gzipped)
- Use `webpack-bundle-analyzer`, `source-map-explorer`, or `vite-bundle-visualizer`
- Review: are there duplicate dependencies? Tree-shaking working? Dead code eliminated?

### Code Splitting Effectiveness
- Route-based splitting: each route loads only its own code
- Component-based splitting: heavy components (charts, editors) loaded on demand
- Verify with Network tab: initial load should not include code for unvisited routes
- Measure: Time to Interactive should improve after splitting

---

## Diff-Mode Benchmarking

Only benchmark pages/endpoints affected by the current changes:

1. Parse `git diff` to identify changed files
2. Map changed files to affected endpoints/pages:
   - Backend file changed → benchmark the API endpoints that use it
   - Frontend component changed → measure that page's Web Vitals
   - Database migration → benchmark affected queries
   - Shared utility changed → benchmark all consumers
3. Run benchmarks only for affected areas (saves CI time)
4. Compare against baseline for those specific areas
5. Report only relevant metrics (don't noise up the report with unchanged areas)

---

## Database Performance

### EXPLAIN Plan Analysis

Every slow query (>100ms) must have its EXPLAIN plan reviewed:

| EXPLAIN Warning | Meaning | Fix |
|-----------------|---------|-----|
| `type: ALL` | Full table scan | Add appropriate index |
| `type: index` | Full index scan | Narrow the query or use composite index |
| `rows` >> actual result | Overestimated scan | Update statistics, add more selective index |
| `Using filesort` | Sort not using index | Add index matching ORDER BY |
| `Using temporary` | Temp table for GROUP BY / DISTINCT | Optimize query or add covering index |
| `Select tables optimized away` | Good — resolved from index/metadata | No action needed |

### Index Usage Stats

```sql
-- MySQL: Find unused indexes
SELECT * FROM sys.schema_unused_indexes WHERE object_schema = 'your_db';

-- MySQL: Find redundant indexes
SELECT * FROM sys.schema_redundant_indexes WHERE table_schema = 'your_db';

-- PostgreSQL: Find unused indexes
SELECT schemaname, indexrelname, idx_scan
FROM pg_stat_user_indexes WHERE idx_scan = 0;
```

### Slow Query Log
- Enable slow query log with threshold of 100ms in development, 500ms in production
- Review slow query log weekly
- Top 10 slowest queries get EXPLAIN analysis and optimization

### Connection Pool Monitoring
- Monitor active, idle, and waiting connections
- Alert when active connections exceed 80% of pool max
- Alert when wait time exceeds 100ms (connection starvation)
- Recommended pool sizes: `max_open = cpu_cores * 2 + effective_spindle_count` (for HDD), `cpu_cores * 4` (for SSD)

---

## Output Format

Performance findings MUST be presented in this format:

### Summary
- **Environment**: [hardware/runtime details]
- **Test type**: [load/stress/spike/soak/volume]
- **Duration**: [how long the test ran]
- **Data volume**: [realistic? production-scale?]

### Findings

| # | Metric | Before | After | Delta | Severity | Location |
|---|--------|--------|-------|-------|----------|----------|
| 1 | API /users P95 | 340ms | 120ms | -65% | IMPROVED | handler/user.go:GetUsers |
| 2 | Bundle size (gzip) | 180KB | 245KB | +36% | REGRESSION | Added chart library |
| 3 | DB queries per request | 12 | 3 | -75% | IMPROVED | Fixed N+1 in OrderService |
| 4 | Memory RSS (steady state) | 256MB | 512MB | +100% | REGRESSION | Cache not evicting |

### Recommendations
- Numbered list of specific actions, ordered by impact
- Each recommendation includes the expected improvement
- Quick wins (< 1 hour) marked with [QUICK WIN]
- Each recommendation tied to a specific finding number

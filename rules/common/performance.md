# Performance Rules

## Database Queries

- **No N+1 queries.** Use eager loading, joins, or batch queries to fetch related data.
- Use database indexes on columns used in WHERE, JOIN, and ORDER BY clauses.
- Profile slow queries and optimize any query exceeding 100ms under normal load.
- Avoid `SELECT *`; select only the columns you need.
- Use `EXPLAIN` / `EXPLAIN ANALYZE` to verify query plans for complex queries.

## Pagination

- **All list endpoints MUST support pagination.** No unbounded result sets.
- Use cursor-based pagination for real-time or high-volume data.
- Use offset-based pagination only for low-volume, static data.
- Set a reasonable default page size (20-50) and a maximum page size (100-200).
- Return total count or next cursor in response metadata.

## Connection Pooling

- Use connection pooling for ALL database connections.
- Configure pool size based on expected concurrency (start with 10-20, tune with load testing).
- Set connection timeouts and idle timeouts to prevent resource leaks.
- Monitor pool utilization and adjust as needed.
- Use separate pools for read and write connections when using read replicas.

## Caching

- Apply the cache-aside pattern: check cache first, fetch from source on miss, populate cache.
- Set appropriate TTL values based on data freshness requirements.
- Implement cache invalidation on data mutation.
- Use cache key namespacing to prevent collisions: `{service}:{entity}:{id}`.
- Monitor cache hit rates; a hit rate below 80% suggests misconfiguration.
- Never cache sensitive data (tokens, personal information) without encryption.

```
// Cache-aside pattern
function getUser(id) {
  const cached = cache.get(`user:${id}`);
  if (cached) return cached;

  const user = db.findUser(id);
  cache.set(`user:${id}`, user, { ttl: 300 });
  return user;
}
```

## Blocking I/O

- **No blocking I/O in request handlers.** Use async/await, goroutines, or worker threads.
- Offload long-running tasks (email sending, report generation, file processing) to background job queues.
- Set timeouts on all external calls (HTTP, database, cache) to prevent cascading failures.
- Use circuit breakers for calls to unreliable external services.

## Frontend Performance

- **Bundle size budget:** Main bundle under 200KB gzipped. Total initial load under 500KB gzipped.
- Use code splitting and lazy loading for routes and heavy components.
- Optimize images: use WebP/AVIF formats, responsive sizes, lazy loading.
- Minimize DOM operations; use virtual scrolling for large lists (100+ items).
- Debounce or throttle event handlers for scroll, resize, and input events.
- Use `requestAnimationFrame` for visual updates, not `setTimeout`.

## API Design

- Support field selection to reduce payload size: `?fields=id,name,email`.
- Use compression (gzip, brotli) for all API responses above 1KB.
- Set appropriate `Cache-Control` headers for cacheable responses.
- Use ETags for conditional requests on frequently polled endpoints.
- Batch related API calls where possible to reduce round trips.

## Memory

- Avoid loading entire datasets into memory. Use streaming or chunked processing.
- Release references to large objects when no longer needed.
- Monitor memory usage in production; investigate leaks immediately.
- Use object pooling for frequently allocated/deallocated objects in hot paths.

## Monitoring

- Instrument key operations with timing metrics (p50, p95, p99 latency).
- Set performance budgets and alert when they are exceeded.
- Profile under realistic load before each release.
- Track and trend performance metrics over time to catch gradual regressions.

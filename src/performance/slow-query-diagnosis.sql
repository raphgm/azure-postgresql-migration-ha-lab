-- Diagnose and fix a slow query: read the actual execution plan instead
-- of guessing at the fix.

-- 1. Run this against the slow query first.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_email = 'user@example.com' ORDER BY created_at DESC;

-- If the plan shows "Seq Scan" scanning far more rows than it returns,
-- that's the tell: no index on the filtered column.

-- 2. Fix: CONCURRENTLY builds the index without holding a lock that
-- blocks writes — slower to build, but doesn't stall production
-- traffic the way a plain CREATE INDEX would on a large, actively
-- written table.
CREATE INDEX CONCURRENTLY idx_orders_customer_email ON orders(customer_email);

-- 3. Re-run the same EXPLAIN ANALYZE — the plan should now show
-- "Index Scan using idx_orders_customer_email" with execution time
-- down by two to three orders of magnitude.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_email = 'user@example.com' ORDER BY created_at DESC;

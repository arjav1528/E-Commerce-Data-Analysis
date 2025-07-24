-- Repeat purchase intervals using LAG window function.
-- Days between consecutive orders per user (customer_unique_id).

WITH user_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS prev_order_ts
    FROM orders o
    JOIN customers c USING (customer_id)
    WHERE o.order_purchase_timestamp IS NOT NULL
),
intervals AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        prev_order_ts,
        EXTRACT(EPOCH FROM (order_purchase_timestamp - prev_order_ts)) / 86400.0
            AS days_since_prev
    FROM user_orders
    WHERE prev_order_ts IS NOT NULL
)
SELECT
    COUNT(*)                                AS repeat_orders,
    COUNT(DISTINCT customer_unique_id)      AS repeat_buyers,
    ROUND(AVG(days_since_prev)::NUMERIC, 1) AS avg_days_between_orders,
    ROUND(
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_since_prev))::NUMERIC, 1
    )                                       AS median_days_between_orders,
    ROUND(MIN(days_since_prev)::NUMERIC, 1) AS min_days,
    ROUND(MAX(days_since_prev)::NUMERIC, 1) AS max_days
FROM intervals;

-- Repeat rate: share of users with >1 order
WITH user_order_counts AS (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS orders
    FROM customers c
    JOIN orders o USING (customer_id)
    GROUP BY 1
)
SELECT
    COUNT(*)                                                        AS total_users,
    COUNT(*) FILTER (WHERE orders > 1)                              AS repeat_users,
    ROUND(100.0 * COUNT(*) FILTER (WHERE orders > 1)
                / NULLIF(COUNT(*), 0), 2)                           AS repeat_rate_pct
FROM user_order_counts;

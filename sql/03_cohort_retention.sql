-- Monthly cohort retention.
-- NOTE: customer_id is per-order in Olist; customer_unique_id is the real user.
-- Cohort = month of first ever purchase. Retention = active users N months later.

WITH user_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS order_month
    FROM orders o
    JOIN customers c USING (customer_id)
    WHERE o.order_purchase_timestamp IS NOT NULL
),
first_purchase AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS cohort_month
    FROM user_orders
    GROUP BY 1
),
activity AS (
    SELECT
        f.cohort_month,
        u.order_month,
        u.customer_unique_id,
        (EXTRACT(YEAR  FROM u.order_month) - EXTRACT(YEAR  FROM f.cohort_month)) * 12
      + (EXTRACT(MONTH FROM u.order_month) - EXTRACT(MONTH FROM f.cohort_month)) AS month_number
    FROM user_orders u
    JOIN first_purchase f USING (customer_unique_id)
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS cohort_users
    FROM first_purchase
    GROUP BY 1
)
SELECT
    a.cohort_month,
    cs.cohort_users,
    a.month_number::INT                                       AS month_number,
    COUNT(DISTINCT a.customer_unique_id)                      AS retained_users,
    ROUND(100.0 * COUNT(DISTINCT a.customer_unique_id)
                / NULLIF(cs.cohort_users, 0), 2)              AS retention_pct
FROM activity a
JOIN cohort_size cs USING (cohort_month)
GROUP BY a.cohort_month, cs.cohort_users, a.month_number
ORDER BY a.cohort_month, a.month_number;

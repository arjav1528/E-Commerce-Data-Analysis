-- GMV concentration: Pareto analysis of customer spending.
-- What share of total GMV comes from top 5/10/20/50% of customers?

WITH user_gmv AS (
    SELECT
        c.customer_unique_id,
        SUM(p.payment_value) AS total_spend
    FROM customers c
    JOIN orders   o USING (customer_id)
    JOIN payments p ON p.order_id = o.order_id
    GROUP BY 1
),
ranked AS (
    SELECT
        customer_unique_id,
        total_spend,
        PERCENT_RANK() OVER (ORDER BY total_spend DESC) AS pct_rank,
        SUM(total_spend) OVER ()                        AS total_gmv
    FROM user_gmv
)
SELECT
    ROUND(SUM(total_spend) FILTER (WHERE pct_rank <= 0.05)::NUMERIC, 2) AS top_5_pct_gmv,
    ROUND(SUM(total_spend) FILTER (WHERE pct_rank <= 0.10)::NUMERIC, 2) AS top_10_pct_gmv,
    ROUND(SUM(total_spend) FILTER (WHERE pct_rank <= 0.20)::NUMERIC, 2) AS top_20_pct_gmv,
    ROUND(SUM(total_spend) FILTER (WHERE pct_rank <= 0.50)::NUMERIC, 2) AS top_50_pct_gmv,
    ROUND(MAX(total_gmv)::NUMERIC, 2)                                   AS total_gmv,
    ROUND(100.0 * SUM(total_spend) FILTER (WHERE pct_rank <= 0.05)
                / NULLIF(MAX(total_gmv), 0), 2)                         AS top_5_pct_share,
    ROUND(100.0 * SUM(total_spend) FILTER (WHERE pct_rank <= 0.10)
                / NULLIF(MAX(total_gmv), 0), 2)                         AS top_10_pct_share,
    ROUND(100.0 * SUM(total_spend) FILTER (WHERE pct_rank <= 0.20)
                / NULLIF(MAX(total_gmv), 0), 2)                         AS top_20_pct_share,
    ROUND(100.0 * SUM(total_spend) FILTER (WHERE pct_rank <= 0.50)
                / NULLIF(MAX(total_gmv), 0), 2)                         AS top_50_pct_share
FROM ranked;

-- Top 20 customers leaderboard
WITH user_gmv AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(p.payment_value)       AS total_spend
    FROM customers c
    JOIN orders   o USING (customer_id)
    JOIN payments p ON p.order_id = o.order_id
    GROUP BY 1
)
SELECT
    RANK() OVER (ORDER BY total_spend DESC) AS rank,
    customer_unique_id,
    orders,
    ROUND(total_spend::NUMERIC, 2) AS total_spend
FROM user_gmv
ORDER BY total_spend DESC
LIMIT 20;

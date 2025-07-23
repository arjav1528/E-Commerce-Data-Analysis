-- RFM segmentation using NTILE(5) quintiles.
-- Recency: days since last order (lower = better, so r_score 5 = most recent).
-- Frequency: order count. Monetary: total payment_value.

WITH snapshot AS (
    SELECT MAX(order_purchase_timestamp)::DATE AS ref_date FROM orders
),
user_metrics AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)::DATE              AS last_order_date,
        (SELECT ref_date FROM snapshot)
            - MAX(o.order_purchase_timestamp)::DATE        AS recency_days,
        COUNT(DISTINCT o.order_id)                         AS frequency,
        COALESCE(SUM(p.payment_value), 0)                  AS monetary
    FROM customers c
    JOIN orders   o USING (customer_id)
    LEFT JOIN payments p ON p.order_id = o.order_id
    GROUP BY c.customer_unique_id
),
scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency)         AS f_score,
        NTILE(5) OVER (ORDER BY monetary)          AS m_score
    FROM user_metrics
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 4 AND f_score >= 3                  THEN 'Loyal'
            WHEN r_score >= 4 AND f_score <= 2                  THEN 'New Customers'
            WHEN r_score >= 3 AND f_score >= 3                  THEN 'Potential Loyalist'
            WHEN r_score <= 2 AND f_score >= 4                  THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 2                  THEN 'Hibernating'
            ELSE                                                     'Lost'
        END AS segment
    FROM scored
)
SELECT * FROM segmented;

-- Segment summary
WITH snapshot AS (
    SELECT MAX(order_purchase_timestamp)::DATE AS ref_date FROM orders
),
user_metrics AS (
    SELECT
        c.customer_unique_id,
        (SELECT ref_date FROM snapshot)
            - MAX(o.order_purchase_timestamp)::DATE AS recency_days,
        COUNT(DISTINCT o.order_id)                  AS frequency,
        COALESCE(SUM(p.payment_value), 0)           AS monetary
    FROM customers c
    JOIN orders   o USING (customer_id)
    LEFT JOIN payments p ON p.order_id = o.order_id
    GROUP BY c.customer_unique_id
),
scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency)         AS f_score,
        NTILE(5) OVER (ORDER BY monetary)          AS m_score
    FROM user_metrics
)
SELECT
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3                  THEN 'Loyal'
        WHEN r_score >= 4 AND f_score <= 2                  THEN 'New Customers'
        WHEN r_score >= 3 AND f_score >= 3                  THEN 'Potential Loyalist'
        WHEN r_score <= 2 AND f_score >= 4                  THEN 'At Risk'
        WHEN r_score <= 2 AND f_score >= 2                  THEN 'Hibernating'
        ELSE                                                     'Lost'
    END                                       AS segment,
    COUNT(*)                                  AS users,
    ROUND(AVG(recency_days), 1)               AS avg_recency_days,
    ROUND(AVG(frequency), 2)                  AS avg_frequency,
    ROUND(AVG(monetary), 2)                   AS avg_monetary,
    ROUND(SUM(monetary), 2)                   AS total_monetary
FROM scored
GROUP BY 1
ORDER BY total_monetary DESC;

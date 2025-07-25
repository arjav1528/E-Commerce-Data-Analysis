-- Category weekly GMV trend with WoW growth.
-- GMV = SUM(price + freight_value) on order_items, attributed to purchase week.

WITH item_revenue AS (
    SELECT
        DATE_TRUNC('week', o.order_purchase_timestamp)::DATE AS week,
        COALESCE(t.product_category_name_english,
                 p.product_category_name,
                 'unknown')                                  AS category,
        (oi.price + oi.freight_value)                        AS revenue
    FROM order_items oi
    JOIN orders   o USING (order_id)
    JOIN products p USING (product_id)
    LEFT JOIN category_translation t
           ON t.product_category_name = p.product_category_name
    WHERE o.order_purchase_timestamp IS NOT NULL
      AND o.order_status NOT IN ('canceled', 'unavailable')
),
weekly AS (
    SELECT
        week,
        category,
        ROUND(SUM(revenue)::NUMERIC, 2) AS gmv,
        COUNT(*)                        AS items_sold
    FROM item_revenue
    GROUP BY 1, 2
)
SELECT
    week,
    category,
    gmv,
    items_sold,
    LAG(gmv) OVER (PARTITION BY category ORDER BY week) AS prev_week_gmv,
    ROUND(
        100.0 * (gmv - LAG(gmv) OVER (PARTITION BY category ORDER BY week))
              / NULLIF(LAG(gmv) OVER (PARTITION BY category ORDER BY week), 0),
        2
    ) AS wow_growth_pct
FROM weekly
ORDER BY week, gmv DESC;

-- Top 10 categories all-time
SELECT
    COALESCE(t.product_category_name_english,
             p.product_category_name,
             'unknown')                          AS category,
    COUNT(DISTINCT oi.order_id)                  AS orders,
    SUM(oi.price + oi.freight_value)::NUMERIC(14,2) AS gmv
FROM order_items oi
JOIN products p USING (product_id)
LEFT JOIN category_translation t
       ON t.product_category_name = p.product_category_name
GROUP BY 1
ORDER BY gmv DESC
LIMIT 10;

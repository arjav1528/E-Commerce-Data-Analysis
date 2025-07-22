-- Funnel analysis: purchase -> approved -> shipped -> delivered
-- Conversion rates between each stage of order lifecycle.

WITH funnel AS (
    SELECT
        COUNT(*)                                                       AS purchased,
        COUNT(order_approved_at)                                       AS approved,
        COUNT(order_delivered_carrier_date)                            AS shipped,
        COUNT(order_delivered_customer_date)                           AS delivered,
        COUNT(*) FILTER (WHERE order_status = 'canceled')              AS canceled
    FROM orders
)
SELECT
    purchased,
    approved,
    shipped,
    delivered,
    canceled,
    ROUND(100.0 * approved  / NULLIF(purchased, 0), 2) AS approve_rate_pct,
    ROUND(100.0 * shipped   / NULLIF(approved,  0), 2) AS ship_rate_pct,
    ROUND(100.0 * delivered / NULLIF(shipped,   0), 2) AS deliver_rate_pct,
    ROUND(100.0 * delivered / NULLIF(purchased, 0), 2) AS overall_conversion_pct,
    ROUND(100.0 * canceled  / NULLIF(purchased, 0), 2) AS cancel_rate_pct
FROM funnel;

-- Funnel by month (trend)
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::DATE AS month,
    COUNT(*)                                            AS purchased,
    COUNT(order_delivered_customer_date)                AS delivered,
    ROUND(100.0 * COUNT(order_delivered_customer_date)
                / NULLIF(COUNT(*), 0), 2)               AS delivery_rate_pct
FROM orders
GROUP BY 1
ORDER BY 1;

WITH recent_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        SUM(oi.quantity * p.price) AS order_total,
        RANK() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date DESC
        ) AS order_rank
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY o.customer_id, o.order_id, o.order_date
),

customer_stats AS (
    SELECT
        c.customer_id,
        c.name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(o.total_amount), 2) AS lifetime_spend,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name
)

SELECT
    cs.customer_id,
    cs.name,
    cs.total_orders,
    cs.lifetime_spend,
    cs.first_order_date,
    cs.last_order_date,
    ro.order_id AS most_recent_order_id,
    ro.order_date AS most_recent_order_date,
    ro.order_total AS most_recent_order_total,
    CASE
        WHEN cs.lifetime_spend > 1000 THEN 'VIP'
        WHEN cs.lifetime_spend BETWEEN 500 AND 1000 THEN 'Regular'
        ELSE 'New/Low-Spend'
    END AS customer_tier
FROM customer_stats cs
LEFT JOIN recent_orders ro
    ON cs.customer_id = ro.customer_id AND ro.order_rank = 1
ORDER BY cs.lifetime_spend DESC;
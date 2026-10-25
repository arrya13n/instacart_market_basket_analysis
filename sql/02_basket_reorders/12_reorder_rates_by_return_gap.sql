
-- Product reorder behaviour by days since previous order

WITH order_gaps AS (
    SELECT
        o.order_id,
        op.reordered,

        CASE
            WHEN o.days_since_prior_order = 0
                THEN 'Same day'
            WHEN o.days_since_prior_order BETWEEN 1 AND 3
                THEN '1-3 days'
            WHEN o.days_since_prior_order BETWEEN 4 AND 7
                THEN '4-7 days'
            WHEN o.days_since_prior_order BETWEEN 8 AND 14
                THEN '8-14 days'
            WHEN o.days_since_prior_order BETWEEN 15 AND 29
                THEN '15-29 days'
            ELSE '30+ days'
        END AS gap_group,

        CASE
            WHEN o.days_since_prior_order = 0 THEN 1
            WHEN o.days_since_prior_order <= 3 THEN 2
            WHEN o.days_since_prior_order <= 7 THEN 3
            WHEN o.days_since_prior_order <= 14 THEN 4
            WHEN o.days_since_prior_order <= 29 THEN 5
            ELSE 6
        END AS sort_order

    FROM silver_tables.vw_orders_explore o
    JOIN silver_tables.order_products_silver op
        ON o.order_id = op.order_id

    WHERE o.days_since_prior_order IS NOT NULL
)

SELECT
    gap_group,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(*) AS total_purchases,

    SUM(CASE WHEN reordered = 1
        THEN 1 ELSE 0 END) AS total_reorders,

    CAST(
        100.0 * SUM(
            CASE WHEN reordered = 1 THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS reorder_rate_pct

FROM order_gaps

GROUP BY gap_group, sort_order
ORDER BY sort_order;

---day interval analysis

-- Purchase and reorder behaviour by exact gap day

WITH order_baskets AS (
    SELECT
        o.order_id,
        o.user_id,
        o.days_since_prior_order AS gap_days,
        COUNT(*) AS basket_size,
        SUM(CASE WHEN op.reordered = 1
            THEN 1 ELSE 0 END) AS reordered_products

    FROM silver_tables.vw_orders_explore o
    JOIN silver_tables.order_products_silver op
        ON o.order_id = op.order_id

    WHERE o.days_since_prior_order BETWEEN 1 AND 14

    GROUP BY
        o.order_id,
        o.user_id,
        o.days_since_prior_order
)

SELECT
    gap_days,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT user_id) AS total_customers,
    SUM(basket_size) AS total_purchases,

    CAST(
        AVG(1.0 * basket_size)
        AS DECIMAL(10,2)
    ) AS avg_basket_size,

    CAST(
        100.0 * SUM(reordered_products)
        / NULLIF(SUM(basket_size), 0)
        AS DECIMAL(5,2)
    ) AS reorder_rate_pct,

    CAST(
        AVG(100.0 * reordered_products
            / NULLIF(basket_size, 0))
        AS DECIMAL(5,2)
    ) AS avg_basket_reorder_pct

FROM order_baskets
GROUP BY gap_days
ORDER BY gap_days;


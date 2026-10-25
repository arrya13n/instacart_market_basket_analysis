
SELECT
    o.order_number,

    COUNT(DISTINCT o.order_id) AS total_orders,

    COUNT(*) AS total_product_purchases,

    SUM(
        CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END
    ) AS total_reorders,

    CAST(
        100.0 * SUM(
            CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS reorder_rate_pct

FROM silver_tables.order_products_silver op
JOIN silver_tables.vw_orders_explore o
    ON op.order_id = o.order_id

GROUP BY o.order_number
ORDER BY o.order_number;

--BASKET SIZE ANALYSIS

WITH basket_sizes AS (
    SELECT
        op.order_id,
        COUNT(*) AS basket_size
    FROM silver_tables.order_products_silver op
    JOIN silver_tables.vw_orders_explore o
        ON op.order_id = o.order_id
    GROUP BY op.order_id
)

SELECT
    COUNT(*) AS total_orders,

    CAST(AVG(1.0 * basket_size) AS DECIMAL(10,2))
        AS avg_products_per_order,

    MIN(basket_size) AS min_basket_size,
    MAX(basket_size) AS max_basket_size,

    SUM(CASE WHEN basket_size BETWEEN 1 AND 3
        THEN 1 ELSE 0 END) AS small_baskets,

    SUM(CASE WHEN basket_size >= 15
        THEN 1 ELSE 0 END) AS large_baskets,

    CAST(
        100.0 * SUM(CASE WHEN basket_size BETWEEN 1 AND 3
            THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS small_basket_pct,

    CAST(
        100.0 * SUM(CASE WHEN basket_size >= 15
            THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS large_basket_pct

FROM basket_sizes;

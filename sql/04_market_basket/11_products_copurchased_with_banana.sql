
-- Top 15 products frequently bought alongside bananas

WITH banana_orders AS (
    SELECT op.order_id
    FROM silver_tables.order_products_silver op
    JOIN silver_tables.vw_orders_explore o
        ON op.order_id = o.order_id
    WHERE op.product_id = 24852
),

co_purchased_products AS (
    SELECT
        op.product_id,
        COUNT(*) AS orders_with_bananas

    FROM banana_orders b
    JOIN silver_tables.order_products_silver op
        ON b.order_id = op.order_id

    WHERE op.product_id <> 24852

    GROUP BY op.product_id
),

banana_summary AS (
    SELECT COUNT(*) AS total_banana_orders
    FROM banana_orders
)

SELECT
    p.product_id,
    p.clean_product_name AS product_name,
    c.orders_with_bananas,

    CAST(
        100.0 * c.orders_with_bananas
        / NULLIF(b.total_banana_orders, 0)
        AS DECIMAL(5,2)
    ) AS pct_of_banana_orders

FROM co_purchased_products c

JOIN silver_tables.product_silver p
    ON c.product_id = p.product_id

CROSS JOIN banana_summary b

ORDER BY c.orders_with_bananas DESC, p.product_id;

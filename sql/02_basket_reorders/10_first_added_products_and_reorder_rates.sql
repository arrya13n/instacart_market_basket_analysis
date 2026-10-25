
-- Top 15 products most frequently added first to cart

SELECT TOP (15)
    p.product_id,
    p.clean_product_name AS product_name,

    COUNT(*) AS times_added_first,

    SUM(
        CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END
    ) AS first_item_reorders,

    CAST(
        100.0 * SUM(
            CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS reorder_rate_pct

FROM silver_tables.order_products_silver op

JOIN silver_tables.vw_orders_explore o
    ON op.order_id = o.order_id

JOIN silver_tables.product_silver p
    ON op.product_id = p.product_id

WHERE op.add_to_cart_order = 1

GROUP BY
    p.product_id,
    p.clean_product_name

ORDER BY times_added_first DESC, p.product_id;

--top selling products and their aisle and department

SELECT 
    --p.clean_product_name,
    --a.aisle,
    d.department,
    count(*) as total_orders,
    SUM(
        CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END
    ) AS total_reorders,

    CAST(
        ROUND(
            100.0 * SUM(
                CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END
            ) / NULLIF(COUNT(*), 0),
            2
        ) AS DECIMAL(5,2)
    ) AS reorder_rate_pct
from silver_tables.order_products_silver op
join silver_tables.product_silver p on op.product_id = p.product_id
JOIN silver_tables.aisle_silver a on p.aisle_id = a.aisle_id
JOIN silver_tables.department_silver d on p.department_id = d.department_id
GROUP BY
    a.aisle,d.department,p.clean_product_name
ORDER by
    count(*) desc;


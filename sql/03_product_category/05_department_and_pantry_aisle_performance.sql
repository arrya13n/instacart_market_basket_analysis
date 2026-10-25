--department level analysis
with same_dept_products as (
    SELECT
        count(distinct p.product_id) as products,
        d.department
    FROM silver_tables.product_silver p
    JOIN silver_tables.department_silver d
        on p.department_id = d.department_id
    GROUP by d.department
)
SELECT
    s.department,
    s.products,
    count(*) as total_purchases,
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
JOIN silver_tables.product_silver p
    on op.product_id = p.product_id
join silver_tables.department_silver d
    on p.department_id = d.department_id
join same_dept_products s 
    on d.department = s.department
group by s.department,s.products
order by reorder_rate_pct desc;


---INVESTIGATING AISLES OF PANTRY DEPT

SELECT
    a.aisle,
    count(distinct p.product_id) as total_products,
    count(*) as total_purchases,
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
join silver_tables.product_silver p 
    on op.product_id = p.product_id
join silver_tables.aisle_silver a
    on p.aisle_id = a.aisle_id
join silver_tables.department_silver d
    on p.department_id = d.department_id
where d.department = 'pantry'
group by a.aisle
order by reorder_rate_pct desc;

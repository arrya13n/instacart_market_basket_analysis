--understand cx base

-- unique customers and unique orders

CREATE VIEW silver_tables.vw_orders_explore AS
SELECT *
FROM silver_tables.orders_silver
WHERE eval_set IN ('prior', 'train');

select
    count(distinct order_id ) as unique_orders,
    count(distinct user_id) as unique_customers
from silver_tables.vw_orders_explore;

-- total orders per customers and total customers in total orders group


WITH total_orders AS (
    SELECT
        user_id,
        COUNT(*) AS orders_per_customer
    FROM silver_tables.vw_orders_explore
    GROUP BY user_id
),

customer_groups AS (
    SELECT
        user_id,
        orders_per_customer,
        NTILE(4) OVER (
            ORDER BY orders_per_customer, user_id
        ) AS customer_quartile
    FROM total_orders
),

group_summary AS (
    SELECT
        customer_quartile,
        COUNT(*) AS total_customers,
        SUM(orders_per_customer) AS total_orders,
        MIN(orders_per_customer) AS min_orders_per_customer,
        MAX(orders_per_customer) AS max_orders_per_customer
    FROM customer_groups
    GROUP BY customer_quartile
)

SELECT
    customer_quartile,
    min_orders_per_customer,
    max_orders_per_customer,
    total_customers,
    total_orders,

    ROUND(
        100.0 * total_orders /
        NULLIF(SUM(total_orders) OVER (), 0), 2
    ) AS order_percentage

FROM group_summary
ORDER BY customer_quartile;


WITH customer_orders AS (
    SELECT
        user_id,
        COUNT(DISTINCT order_id) AS orders_per_customer
    FROM silver_tables.vw_orders_explore
    GROUP BY user_id
),

order_groups AS (
    SELECT
        orders_per_customer,
        COUNT(*) AS total_customers,
        SUM(orders_per_customer) AS total_orders
    FROM customer_orders
    GROUP BY orders_per_customer
)

SELECT
    orders_per_customer,
    total_customers,
    total_orders,
    ROUND(
        100.0 * total_orders /
        SUM(total_orders) OVER (), 2
    ) AS order_percentage

FROM order_groups
ORDER BY orders_per_customer;

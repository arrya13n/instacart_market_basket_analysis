
-- Products purchased overnight vs daytime vs evening

WITH product_purchases AS (
    SELECT
        op.product_id,
        CASE
            WHEN o.order_hour_of_day BETWEEN 0 AND 5
                THEN 'Overnight'
            WHEN o.order_hour_of_day BETWEEN 6 AND 17
                THEN 'Daytime'
            ELSE 'Evening'
        END AS time_period
    FROM silver_tables.order_products_silver op
    JOIN silver_tables.vw_orders_explore o
        ON op.order_id = o.order_id
),

product_metrics AS (
    SELECT
        product_id,
        COUNT(*) AS total_purchases,

        SUM(CASE WHEN time_period = 'Overnight'
            THEN 1 ELSE 0 END) AS overnight_purchases,

        SUM(CASE WHEN time_period = 'Daytime'
            THEN 1 ELSE 0 END) AS daytime_purchases,

        SUM(CASE WHEN time_period = 'Evening'
            THEN 1 ELSE 0 END) AS evening_purchases

    FROM product_purchases
    GROUP BY product_id
),

overall_metrics AS (
    SELECT
        1.0 * SUM(overnight_purchases)
            / NULLIF(SUM(total_purchases), 0)
            AS overall_overnight_share
    FROM product_metrics
)

SELECT TOP (20)
    p.product_id,
    p.clean_product_name AS product_name,
    m.total_purchases,

    m.overnight_purchases,
    m.daytime_purchases,
    m.evening_purchases

FROM product_metrics m
JOIN silver_tables.product_silver p
    ON m.product_id = p.product_id
CROSS JOIN overall_metrics o

WHERE m.total_purchases >= 1000

ORDER BY m.overnight_purchases DESC;

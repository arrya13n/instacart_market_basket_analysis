-- INSTACART | REMAINING EXPLORATORY ANALYSIS
-- Microsoft Fabric Lakehouse SQL analytics endpoint (T-SQL)
-- Reuses silver_tables.vw_orders_explore, which filters eval_set to prior/train.
-- These analyses count product entries/order occurrences; not item units or revenue.

-- =====================================================================
-- 1. OVERALL BASKET-SIZE KPIs
-- Grain in basket_sizes: one row per eligible order
-- =====================================================================
WITH basket_sizes AS (
    SELECT
        op.order_id,
        COUNT(*) AS basket_size
    FROM silver_tables.order_products_silver AS op
    JOIN silver_tables.vw_orders_explore AS o
        ON op.order_id = o.order_id
    GROUP BY op.order_id
)
SELECT
    COUNT(*) AS orders_with_items,
    CAST(AVG(1.0 * basket_size) AS DECIMAL(10,2)) AS avg_products_per_order,
    MIN(basket_size) AS min_basket_size,
    MAX(basket_size) AS max_basket_size,
    SUM(CASE WHEN basket_size BETWEEN 1 AND 3 THEN 1 ELSE 0 END) AS small_baskets_1_to_3,
    SUM(CASE WHEN basket_size >= 15 THEN 1 ELSE 0 END) AS large_baskets_15_plus,
    CAST(
        100.0 * SUM(CASE WHEN basket_size BETWEEN 1 AND 3 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)
    ) AS small_basket_pct,
    CAST(
        100.0 * SUM(CASE WHEN basket_size >= 15 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)
    ) AS large_basket_pct
FROM basket_sizes;

-- =====================================================================
-- 2. BASKET-SIZE DISTRIBUTION (FOR POWER BI HISTOGRAM)
-- Grain: one row per observed basket_size value
-- =====================================================================
WITH basket_sizes AS (
    SELECT
        op.order_id,
        COUNT(*) AS basket_size
    FROM silver_tables.order_products_silver AS op
    JOIN silver_tables.vw_orders_explore AS o
        ON op.order_id = o.order_id
    GROUP BY op.order_id
),
basket_distribution AS (
    SELECT
        basket_size,
        COUNT(*) AS total_orders
    FROM basket_sizes
    GROUP BY basket_size
)
SELECT
    basket_size,
    total_orders,
    CAST(
        100.0 * total_orders / NULLIF(SUM(total_orders) OVER (), 0)
        AS DECIMAL(5,2)
    ) AS order_share_pct
FROM basket_distribution
ORDER BY basket_size;

-- =====================================================================
-- 3. BASKET SIZE BY CUSTOMER-FREQUENCY QUARTILE
-- Customer-weighted average, avoiding domination by frequent shoppers
-- Grain: one row per customer quartile
-- =====================================================================
WITH customer_frequency AS (
    SELECT
        user_id,
        COUNT(*) AS orders_per_customer
    FROM silver_tables.vw_orders_explore
    GROUP BY user_id
),
customer_quartiles AS (
    SELECT
        user_id,
        orders_per_customer,
        NTILE(4) OVER (
            ORDER BY orders_per_customer, user_id
        ) AS customer_quartile
    FROM customer_frequency
),
basket_sizes AS (
    SELECT
        o.user_id,
        op.order_id,
        COUNT(*) AS basket_size
    FROM silver_tables.order_products_silver AS op
    JOIN silver_tables.vw_orders_explore AS o
        ON op.order_id = o.order_id
    GROUP BY o.user_id, op.order_id
),
customer_basket_averages AS (
    SELECT
        user_id,
        AVG(1.0 * basket_size) AS avg_basket_size
    FROM basket_sizes
    GROUP BY user_id
)
SELECT
    q.customer_quartile,
    COUNT(*) AS total_customers,
    MIN(q.orders_per_customer) AS min_orders_per_customer,
    MAX(q.orders_per_customer) AS max_orders_per_customer,
    CAST(AVG(b.avg_basket_size) AS DECIMAL(10,2)) AS avg_basket_size_per_customer
FROM customer_quartiles AS q
JOIN customer_basket_averages AS b
    ON q.user_id = b.user_id
GROUP BY q.customer_quartile
ORDER BY q.customer_quartile;

-- =====================================================================
-- 4. REORDER RATE BY CUSTOMER ORDER NUMBER
-- Grain: one row per order_number (1, 2, 3, ...)
-- =====================================================================
SELECT
    o.order_number,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_product_purchases,
    SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END) AS total_reorders,
    CAST(
        100.0 * SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)
    ) AS reorder_rate_pct
FROM silver_tables.order_products_silver AS op
JOIN silver_tables.vw_orders_explore AS o
    ON op.order_id = o.order_id
GROUP BY o.order_number
ORDER BY o.order_number;

-- =====================================================================
-- 5. BASKET COMPOSITION: ALL NEW / MIXED / ALL REORDERED
-- Grain: one row per basket_type
-- =====================================================================
WITH basket_reorders AS (
    SELECT
        op.order_id,
        COUNT(*) AS total_products,
        SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END) AS reordered_products
    FROM silver_tables.order_products_silver AS op
    JOIN silver_tables.vw_orders_explore AS o
        ON op.order_id = o.order_id
    GROUP BY op.order_id
),
classified_baskets AS (
    SELECT
        order_id,
        CASE
            WHEN reordered_products = 0 THEN 'All new products'
            WHEN reordered_products = total_products THEN 'All reordered products'
            ELSE 'Mixed basket'
        END AS basket_type
    FROM basket_reorders
),
basket_type_counts AS (
    SELECT
        basket_type,
        COUNT(*) AS total_orders
    FROM classified_baskets
    GROUP BY basket_type
)
SELECT
    basket_type,
    total_orders,
    CAST(
        100.0 * total_orders / NULLIF(SUM(total_orders) OVER (), 0)
        AS DECIMAL(5,2)
    ) AS order_share_pct
FROM basket_type_counts
ORDER BY total_orders DESC;

-- =====================================================================
-- 6. TOP 20 PRODUCTS + MOST FREQUENT PURCHASE HOUR & DAY
-- The most frequent hour and day are ranked independently.
-- Grain: one row per top-20 product_id
-- =====================================================================
WITH eligible_items AS (
    SELECT
        op.product_id,
        op.reordered,
        o.order_hour_of_day,
        o.order_day_of_week
    FROM silver_tables.order_products_silver AS op
    JOIN silver_tables.vw_orders_explore AS o
        ON op.order_id = o.order_id
),
top_products AS (
    SELECT TOP (20)
        product_id,
        COUNT(*) AS total_purchases,
        SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END) AS total_reorders
    FROM eligible_items
    GROUP BY product_id
    ORDER BY COUNT(*) DESC, product_id
),
hour_counts AS (
    SELECT
        e.product_id,
        e.order_hour_of_day,
        COUNT(*) AS hour_purchases
    FROM eligible_items AS e
    JOIN top_products AS t
        ON e.product_id = t.product_id
    GROUP BY e.product_id, e.order_hour_of_day
),
ranked_hours AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY hour_purchases DESC, order_hour_of_day
        ) AS rn
    FROM hour_counts
),
day_counts AS (
    SELECT
        e.product_id,
        e.order_day_of_week,
        COUNT(*) AS day_purchases
    FROM eligible_items AS e
    JOIN top_products AS t
        ON e.product_id = t.product_id
    GROUP BY e.product_id, e.order_day_of_week
),
ranked_days AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY day_purchases DESC, order_day_of_week
        ) AS rn
    FROM day_counts
)
SELECT
    t.product_id,
    p.clean_product_name AS product_name,
    t.total_purchases,
    CAST(
        100.0 * t.total_reorders / NULLIF(t.total_purchases, 0)
        AS DECIMAL(5,2)
    ) AS reorder_rate_pct,
    h.order_hour_of_day AS peak_hour,
    h.hour_purchases AS purchases_at_peak_hour,
    CAST(
        100.0 * h.hour_purchases / NULLIF(t.total_purchases, 0)
        AS DECIMAL(5,2)
    ) AS product_purchases_at_peak_hour_pct,
    d.order_day_of_week AS peak_day_of_week,
    d.day_purchases AS purchases_on_peak_day,
    CAST(
        100.0 * d.day_purchases / NULLIF(t.total_purchases, 0)
        AS DECIMAL(5,2)
    ) AS product_purchases_on_peak_day_pct
FROM top_products AS t
JOIN silver_tables.product_silver AS p
    ON t.product_id = p.product_id
JOIN ranked_hours AS h
    ON t.product_id = h.product_id AND h.rn = 1
JOIN ranked_days AS d
    ON t.product_id = d.product_id AND d.rn = 1
ORDER BY t.total_purchases DESC, t.product_id;

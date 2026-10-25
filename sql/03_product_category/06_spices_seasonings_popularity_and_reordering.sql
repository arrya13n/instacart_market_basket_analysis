
-- Spices & Seasonings: Product Popularity and Reorder Analysis

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.clean_product_name AS product_name,
        COUNT(*) AS total_purchases,
        SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END) AS total_reorders
    FROM silver_tables.order_products_silver op
    JOIN silver_tables.product_silver p
        ON op.product_id = p.product_id
    JOIN silver_tables.aisle_silver a
        ON p.aisle_id = a.aisle_id
    WHERE a.aisle = 'spices seasonings'
    GROUP BY
        p.product_id,
        p.clean_product_name
),

product_summary AS (
    SELECT
        *,
        CAST(
            100.0 * total_reorders / NULLIF(total_purchases, 0)
            AS DECIMAL(5,2)
        ) AS reorder_rate_pct,

        CAST(
            100.0 * total_purchases / SUM(total_purchases) OVER ()
            AS DECIMAL(5,2)
        ) AS aisle_purchase_share_pct,

        ROW_NUMBER() OVER (
            ORDER BY total_purchases DESC, product_id
        ) AS popularity_rank
    FROM product_metrics
),

ranked_products AS (
    SELECT
        *,
        CASE WHEN total_purchases >= 500 THEN
            ROW_NUMBER() OVER (
                PARTITION BY CASE WHEN total_purchases >= 500 THEN 1 ELSE 0 END
                ORDER BY reorder_rate_pct DESC, total_purchases DESC, product_id
            )
        END AS highest_reorder_rank,

        CASE WHEN total_purchases >= 500 THEN
            ROW_NUMBER() OVER (
                PARTITION BY CASE WHEN total_purchases >= 500 THEN 1 ELSE 0 END
                ORDER BY reorder_rate_pct ASC, total_purchases DESC, product_id
            )
        END AS lowest_reorder_rank
    FROM product_summary
)

SELECT
    product_name,
    total_purchases,
    total_reorders,
    reorder_rate_pct,
    aisle_purchase_share_pct,
    popularity_rank,
    highest_reorder_rank,
    lowest_reorder_rank
FROM ranked_products
WHERE
    popularity_rank <= 15
    OR highest_reorder_rank <= 5
    OR lowest_reorder_rank <= 5
ORDER BY popularity_rank;

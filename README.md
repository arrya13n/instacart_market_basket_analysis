# Instacart Customer, Basket & Product Analytics

**End-to-end retail purchase-behaviour analysis | Microsoft Fabric · PySpark · T-SQL · Power BI**

A portfolio project using the public Instacart Market Basket Analysis dataset to investigate **customer shopping patterns, basket composition, repeat purchases and product/category performance**, then translate findings into three decision-focused Power BI report pages.

> **Scope:** This repository contains the SQL analysis scripts, dashboard documentation and validation notes. The interactive Fabric workspace and Power BI semantic model are not embedded here. Report exports/screenshots can be added to `dashboards/` once exported and reviewed for public sharing.

## Business questions

1. **Customer Behaviour:** When do customers shop, and how long do they wait between orders?
2. **Basket & Reorders:** How do basket sizes and familiar-product purchasing change across customer ordering history?
3. **Product & Category:** Which departments/products dominate purchases, which generate strong repeat buying, and how does product demand vary by hour?

## Data & scope

Source: [Instacart Market Basket Analysis (Kaggle)](https://www.kaggle.com/competitions/instacart-market-basket-analysis).

Raw tables include `orders`, `order_products__prior`, `order_products__train`, `products`, `aisles`, and `departments`. Reporting excludes test orders without observed product entries (`eval_set IN ('prior', 'train')`); original data is not redistributed.

**Grain and interpretation:** one fact-order-item row is a purchased product *entry* (a product present in an order), not an item quantity. `reordered=1` means the customer had purchased that same product before at least once, not necessarily in their immediately preceding order. `days_since_prior_order=30` represents **30+ days**, not exactly 30. No item prices, revenue, inventory, stockout history, fulfillment or true order dates are available in this dataset.

## Architecture

```text
Instacart CSV source tables
           |
           v
Bronze: raw landing in Microsoft Fabric Lakehouse
           |
           v
Silver: cleaning, standardization, data-quality checks,
        product/category lookup tables,
        observed orders + combined prior/train order items
           |
           v
Gold:  dim_products (includes department and aisle)
       fact_orders (one row / eligible order)
       fact_order_items (one row / observed product in order)
           |
           v
Direct Lake / Power BI semantic model
           |
           v
Three Power BI report pages
```


## Dashboard pages

| Report page | Key visuals | Decision focus |
|---|---|---|
| **01 · Customer Behaviour** | KPI cards, orders-by-hour trend, day/hour heatmap, seven-day return peak | Understand order cadence and potential operational demand periods |
| **02 · Basket & Reorders** | Basket size vs reorder-rate scatter, 100% stacked new-vs-reordered composition by order number, first-cart-product treemap | Improve repeat-purchase and product-discovery experiences |
| **03 · Product & Category Intelligence** | Department purchase-volume/reorder-rate combo chart with aisle drill-down, top products ranking, selected-product hourly comparison | Prioritize category/product analysis and test complementary-product merchandising |


## Selected findings

These are descriptive findings from the exploratory SQL and Power BI work, not causal estimates:

| Metric / finding | Value / interpretation |
|---|---|
| Observed orders | ~3.35 million |
| Observed customers | ~206,209 |
| Purchased-product entries | ~33.82 million |
| Listed products in catalog | 49,688 |
| Average product entries per order | ~10.11 |
| Previously purchased product share | ~59.01% |
| Seven-day return-gap orders | 315,335, within the exact 1–14 day comparison |
| Produce product entries | ~9.89 million, approximately 29.24% of all observed entries |
| Banana (product ID 24852) | 491,291 product entries; ~84.51% previously purchased |
| First-added product reorder rate | ~68% |

### Example questions and actions

- **Demand planning hypothesis:** Compare peak ordering-hour volume with operational throughput before changing staffing.
- **Basket-building experiment:** Test a *Buy Again* shortcut for prior customers and measure time to first item added, cart-building time and order completion.
- **Product availability follow-up:** Join top Produce item frequencies with real stockout/fulfillment records before proposing replenishment changes.
- **Cross-sell experiment:** Use Banana co-purchase frequencies to propose complementary-product placements, then measure incremental add-on purchases with a controlled test.

The public Instacart dataset alone **cannot validate** operational service delays, stockouts or experiment results.

## How to reproduce the SQL analysis

1. Download the dataset from the Kaggle competition and ingest source tables into a Microsoft Fabric Lakehouse.
2. Prepare the Silver tables (`orders_silver`, `order_products_silver`, `product_silver`, `aisle_silver`, `department_silver`) using the names expected by the queries.
3. Create `silver_tables.vw_orders_explore` with `eval_set IN ('prior', 'train')` (**Query 01** includes the one-time view creation statement).
4. Open the Lakehouse **SQL analytics endpoint**, execute the relevant T-SQL files in [`sql/`](sql/), and validate metrics against [`docs/metrics_and_validation.md`](docs/metrics_and_validation.md).
5. Build/link the Gold reporting tables and Power BI semantic model, then create the three report pages. The dashboard design guide explains the chart fields.

> **Reproducibility note:** The scripts are portfolio **exploration queries**, not a single idempotent deployment script. The Fabric ingestion, Silver processing and finished semantic-model export are outside this SQL-only package.

## Tools & skills

Microsoft Fabric, Fabric Lakehouse (Bronze/Silver/Gold), PySpark, Delta tables, SQL analytics endpoint (T-SQL), Power BI, Direct Lake, dimensional modeling, data profiling, DAX measures, business KPI design.

## Responsible interpretation

- Product purchase **entries** are not sales revenue or physical unit quantities.
- `reordered=1` indicates any earlier purchase of that product by that customer.
- Return gaps are not true calendar dates; 30 represents 30+ days.
- Co-purchase counts alone do not establish association strength or causal effectiveness of cross-selling.
- Dashboard findings are historical descriptive evidence; recommendations are **experiments or operational follow-ups**, not verified business outcomes.

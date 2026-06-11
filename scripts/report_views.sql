-- ============================================================
-- Reporting Views — Gold Layer
-- Database: SQL Server | Schema: gold
-- Views: report_customers, report_products
-- ============================================================


-- ============================================================
-- 1. CUSTOMER REPORT VIEW
-- ============================================================
-- Consolidates customer transactions with aggregated KPIs:
--   age group, customer segment (VIP/Regular/New),
--   recency, AOV, and average monthly spend.
-- ============================================================

CREATE VIEW gold.report_customers AS

WITH report AS (
    -- Base: join sales to customers, exclude null order dates
    SELECT
        s.order_number,
        s.product_key,
        s.order_date,
        s.sales_amount,
        s.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name)      AS full_name,
        DATEDIFF(YEAR, c.birthdate, GETDATE())       AS age
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_customers c ON c.customer_key = s.customer_key
    WHERE s.order_date IS NOT NULL
),

customer_agg AS (
    -- Aggregate to one row per customer
    SELECT
        customer_key,
        customer_number,
        full_name,
        age,
        COUNT(DISTINCT order_number)                                    AS total_orders,
        SUM(sales_amount)                                               AS total_sales,
        SUM(quantity)                                                   AS total_quantity,
        COUNT(DISTINCT product_key)                                     AS total_products,
        MAX(order_date)                                                 AS last_order,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date))               AS lifespan
    FROM report
    GROUP BY customer_key, customer_number, full_name, age
)

SELECT
    customer_key,
    customer_number,
    full_name,
    age,

    -- Age group bucket
    CASE
        WHEN age < 20                    THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29       THEN '20-29'
        WHEN age BETWEEN 30 AND 39       THEN '30-39'
        WHEN age BETWEEN 40 AND 49       THEN '40-49'
        ELSE                                  '50 and Above'
    END                                                         AS age_group,

    -- Customer segment: VIP / Regular / New
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000  THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE                                              'New'
    END                                                         AS customer_segment,

    last_order,
    DATEDIFF(MONTH, last_order, GETDATE())                      AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,

    -- Average order value (AOV)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END                                                         AS aov,

    -- Average monthly spend
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END                                                         AS avg_monthly_spend

FROM customer_agg;


-- ============================================================
-- 2. PRODUCT REPORT VIEW
-- ============================================================
-- Consolidates product transactions with aggregated KPIs:
--   product segment (High/Mid/Low), recency, AOV,
--   average selling price, and average monthly spend.
-- ============================================================

CREATE VIEW gold.report_products AS

WITH report AS (
    -- Base: join sales to products, exclude null order dates
    SELECT
        s.order_number,
        s.order_date,
        s.sales_amount,
        s.quantity,
        s.customer_key,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p ON p.product_key = s.product_key
    WHERE s.order_date IS NOT NULL
),

product_agg AS (
    -- Aggregate to one row per product
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        COUNT(DISTINCT order_number)                                        AS total_orders,
        SUM(sales_amount)                                                   AS total_sales,
        SUM(quantity)                                                       AS total_quantity,
        COUNT(DISTINCT customer_key)                                        AS total_customers,
        MAX(order_date)                                                     AS last_order,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date))                   AS lifespan,
        ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1)    AS avg_selling_price
    FROM report
    GROUP BY product_key, product_name, category, subcategory, cost
)

SELECT
    product_key,
    product_name,
    category,
    subcategory,
    last_order,
    DATEDIFF(MONTH, last_order, GETDATE())                          AS recency,

    -- Product performance segment
    CASE
        WHEN total_sales > 50000  THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE                           'Low-Performer'
    END                                                             AS product_segment,

    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    lifespan,
    avg_selling_price,

    -- Average order value (AOV)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END                                                             AS aov,

    -- Average monthly spend
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END                                                             AS avg_monthly_spend

FROM product_agg;

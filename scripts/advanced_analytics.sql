-- ============================================================
-- Advanced Analytics — Gold Layer
-- Database: SQL Server | Schema: gold
-- Tables: fact_sales, dim_customers, dim_products
-- ============================================================


-- ============================================================
-- 1. TIME-SERIES ANALYSIS
-- ============================================================

-- Sales performance by year
SELECT
    YEAR(order_date)              AS year,
    SUM(sales_amount)             AS total_sales,
    COUNT(DISTINCT customer_key)  AS total_customers,
    SUM(quantity)                 AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);

-- Sales performance by month (all years combined)
SELECT
    MONTH(order_date)             AS month,
    SUM(sales_amount)             AS total_sales,
    COUNT(DISTINCT customer_key)  AS total_customers,
    SUM(quantity)                 AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date);

-- Sales performance by year and month
SELECT
    YEAR(order_date)              AS year,
    MONTH(order_date)             AS month,
    SUM(sales_amount)             AS total_sales,
    COUNT(DISTINCT customer_key)  AS total_customers,
    SUM(quantity)                 AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);


-- ============================================================
-- 2. RUNNING TOTAL (Year-to-Date Cumulative Sales)
-- ============================================================

-- Monthly sales with cumulative running total within each year
SELECT
    order_date,
    YEAR(order_date)                                                        AS order_year,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_total
FROM (
    SELECT
        DATETRUNC(month, order_date) AS order_date,
        SUM(sales_amount)            AS total_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(month, order_date)
) monthly_sales;


-- ============================================================
-- 3. YEAR-OVER-YEAR PRODUCT PERFORMANCE
-- ============================================================

-- For each product per year: current sales vs. avg sales vs. prior year sales
WITH yearly_product_sales AS (
    SELECT
        YEAR(s.order_date)  AS year,
        p.product_name,
        SUM(s.sales_amount) AS current_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY YEAR(s.order_date), p.product_name
),
with_avg AS (
    SELECT
        year,
        product_name,
        current_sales,
        AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales
    FROM yearly_product_sales
),
with_prev AS (
    SELECT
        year,
        product_name,
        current_sales,
        avg_sales,
        LAG(current_sales) OVER (PARTITION BY product_name ORDER BY year ASC) AS prev_year_sales
    FROM with_avg
)
SELECT
    year,
    product_name,
    current_sales,
    avg_sales,
    current_sales - avg_sales                                   AS diff_vs_avg,
    CASE
        WHEN current_sales - avg_sales > 0 THEN 'Above Avg'
        WHEN current_sales - avg_sales < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END                                                         AS avg_flag,
    prev_year_sales,
    current_sales - prev_year_sales                             AS diff_vs_prev_year,
    CASE
        WHEN current_sales - prev_year_sales > 0 THEN 'Increase'
        WHEN current_sales - prev_year_sales < 0 THEN 'Decrease'
        ELSE 'No Change'
    END                                                         AS yoy_flag
FROM with_prev
ORDER BY product_name, year;


-- ============================================================
-- 4. CATEGORY CONTRIBUTION TO TOTAL REVENUE
-- ============================================================

WITH category_sales AS (
    SELECT
        p.category,
        SUM(s.sales_amount) AS total_sales
    FROM gold.fact_sales s
    JOIN gold.dim_products p ON s.product_key = p.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER ()                                                        AS overall_sales,
    CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS pct_of_total
FROM category_sales;


-- ============================================================
-- 5. PRODUCT COST SEGMENTATION
-- ============================================================

WITH product_segment AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE
            WHEN cost < 100              THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500  THEN '100–500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500–1000'
            ELSE                              'Above 1000'
        END AS cost_segment
    FROM gold.dim_products
)
SELECT
    cost_segment,
    COUNT(*) AS total_products
FROM product_segment
GROUP BY cost_segment
ORDER BY COUNT(*);


-- ============================================================
-- 6. CUSTOMER SEGMENTATION (VIP / Regular / New)
-- ============================================================

-- Segment logic:
--   VIP     → lifespan >= 12 months AND total spend > 5,000
--   Regular → lifespan >= 12 months AND total spend <= 5,000
--   New     → lifespan < 12 months (regardless of spend)

WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(s.sales_amount)                              AS total_sales,
        MIN(s.order_date)                                AS first_order,
        MAX(s.order_date)                                AS last_order,
        DATEDIFF(month, MIN(s.order_date), MAX(s.order_date)) AS lifespan_months
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_customers c ON s.customer_key = c.customer_key
    GROUP BY c.customer_key
),
customer_segments AS (
    SELECT
        customer_key,
        CASE
            WHEN lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
            WHEN lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
)
SELECT
    customer_segment,
    COUNT(*) AS total_customers
FROM customer_segments
GROUP BY customer_segment;

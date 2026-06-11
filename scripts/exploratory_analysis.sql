-- ============================================================
-- Exploratory Data Analysis (EDA) — Gold Layer
-- Database: SQL Server | Schema: gold
-- Tables: fact_sales, dim_customers, dim_products
-- ============================================================


-- ============================================================
-- 1. SCHEMA EXPLORATION
-- ============================================================

-- List all tables in the database
SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- List all columns across all tables
SELECT * FROM INFORMATION_SCHEMA.COLUMNS;


-- ============================================================
-- 2. DIMENSION EXPLORATION
-- ============================================================

-- Distinct countries in customer dimension
SELECT DISTINCT country
FROM gold.dim_customers;

-- Product hierarchy: category > subcategory > product
SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY 1, 2, 3;


-- ============================================================
-- 3. DATE RANGE & CUSTOMER AGE EXPLORATION
-- ============================================================

-- Sales date range and span in years
SELECT
    MIN(order_date)                              AS min_date,
    MAX(order_date)                              AS max_date,
    DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) AS years_in_data
FROM gold.fact_sales;

-- Customer age range
SELECT
    MIN(birthdate)                                   AS oldest_customer_dob,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE())        AS oldest_age,
    MAX(birthdate)                                   AS youngest_customer_dob,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE())        AS youngest_age
FROM gold.dim_customers;


-- ============================================================
-- 4. KEY BUSINESS METRICS — SUMMARY
-- ============================================================

-- Individual metrics
SELECT SUM(sales_amount)            AS total_sales         FROM gold.fact_sales;
SELECT SUM(quantity)                AS total_quantity      FROM gold.fact_sales;
SELECT AVG(price)                   AS avg_selling_price   FROM gold.fact_sales;
SELECT COUNT(DISTINCT order_number) AS total_orders        FROM gold.fact_sales;
SELECT COUNT(product_key)           AS total_products      FROM gold.dim_products;
SELECT COUNT(customer_key)          AS total_customers     FROM gold.dim_customers;

-- Customers who have placed at least one order
SELECT COUNT(DISTINCT customer_key) AS customers_with_orders
FROM gold.fact_sales;

-- Consolidated KPI summary (single result set)
SELECT 'Total Sales'            AS measure_name, SUM(s.sales_amount)             AS measure_value FROM gold.fact_sales s
UNION ALL
SELECT 'Total Quantity',                         SUM(s.quantity)                               FROM gold.fact_sales s
UNION ALL
SELECT 'Avg Selling Price',                      AVG(s.price)                                  FROM gold.fact_sales s
UNION ALL
SELECT 'Total Orders',                           COUNT(DISTINCT s.order_number)                FROM gold.fact_sales s
UNION ALL
SELECT 'Total Products',                         COUNT(p.product_key)                          FROM gold.dim_products p
UNION ALL
SELECT 'Total Customers',                        COUNT(c.customer_key)                         FROM gold.dim_customers c;


-- ============================================================
-- 5. CUSTOMER SEGMENTATION
-- ============================================================

-- Customers by country
SELECT
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country;

-- Customers by gender
SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender;


-- ============================================================
-- 6. PRODUCT ANALYSIS
-- ============================================================

-- Product count by category
SELECT
    category,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category;

-- Average cost by category
SELECT
    category,
    AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category;

-- Total sales revenue by category
SELECT
    p.category,
    SUM(s.sales_amount) AS total_sales
FROM gold.dim_products p
JOIN gold.fact_sales s ON p.product_key = s.product_key
GROUP BY p.category;


-- ============================================================
-- 7. SALES PERFORMANCE
-- ============================================================

-- Total sales per customer
SELECT
    c.customer_key,
    SUM(s.sales_amount) AS total_sales
FROM gold.dim_customers c
JOIN gold.fact_sales s ON c.customer_key = s.customer_key
GROUP BY c.customer_key;

-- Total quantity sold by country
SELECT
    c.country,
    COUNT(s.quantity) AS total_quantity
FROM gold.fact_sales s
JOIN gold.dim_customers c ON s.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_quantity DESC;


-- ============================================================
-- 8. RANKINGS
-- ============================================================

-- Top 5 products by revenue (TOP N approach)
SELECT TOP 5
    p.product_name,
    SUM(s.sales_amount) AS total_sales
FROM gold.dim_products p
JOIN gold.fact_sales s ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_sales DESC;

-- Top 5 products by revenue (window function approach)
SELECT *
FROM (
    SELECT
        p.product_name,
        SUM(s.sales_amount)                                    AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(s.sales_amount) DESC) AS rank_products
    FROM gold.dim_products p
    JOIN gold.fact_sales s ON p.product_key = s.product_key
    GROUP BY p.product_name
) ranked
WHERE rank_products <= 5;

-- Bottom 5 products by revenue
SELECT TOP 5
    p.product_name,
    SUM(s.sales_amount) AS total_sales
FROM gold.dim_products p
JOIN gold.fact_sales s ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_sales ASC;

-- Top 10 customers by revenue
SELECT TOP 10
    c.customer_key,
    SUM(s.sales_amount) AS total_sales
FROM gold.dim_customers c
JOIN gold.fact_sales s ON c.customer_key = s.customer_key
GROUP BY c.customer_key
ORDER BY total_sales DESC;

-- Bottom 3 customers by order frequency
SELECT TOP 3
    c.customer_key,
    COUNT(DISTINCT s.order_number) AS total_orders
FROM gold.dim_customers c
JOIN gold.fact_sales s ON c.customer_key = s.customer_key
GROUP BY c.customer_key
ORDER BY total_orders ASC;

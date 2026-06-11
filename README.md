# SQL Data Warehouse Project

A full end-to-end Data Warehouse built on **SQL Server**, implementing the **Medallion Architecture** (Bronze → Silver → Gold) with complete ETL pipelines, data modeling, and advanced analytics.

---

## Project Overview

This project simulates a real-world data warehouse scenario where data is ingested from two source systems (**CRM** and **ERP**), cleaned and transformed across multiple layers, and finally exposed as business-ready views for reporting and analysis.

| Item | Details |
|---|---|
| **Database** | Microsoft SQL Server |
| **Architecture** | Medallion (Bronze / Silver / Gold) |
| **Source Systems** | CRM System, ERP System |
| **Source Format** | CSV Files |
| **Data Domain** | Sales, Customers, Products |

---

## Architecture

```
CRM (CSV)  ──┐
              ├──► Bronze Layer ──► Silver Layer ──► Gold Layer ──► Analytics
ERP (CSV)  ──┘
```

### Layer Responsibilities

| Layer | Description |
|---|---|
| **Bronze** | Raw data ingested as-is from source CSV files using `BULK INSERT`. No transformations applied. |
| **Silver** | Cleansed and standardized data. Handles duplicates, nulls, data type casting, and value normalization. |
| **Gold** | Business-ready dimensional model (Star Schema). Exposes `dim_customers`, `dim_products`, and `fact_sales` as views. |

---

## Data Model (Star Schema)

```
                    ┌─────────────────┐
                    │  dim_customers  │
                    │─────────────────│
                    │ customer_key PK │
                    │ customer_number │
                    │ full_name       │
                    │ country         │
                    │ gender          │
                    │ birthdate       │
                    └────────┬────────┘
                             │
┌─────────────────┐          │          ┌─────────────────┐
│  dim_products   │          │          │   fact_sales    │
│─────────────────│          │          │─────────────────│
│ product_key  PK │◄─────────┼──────────│ order_number    │
│ product_name    │          │          │ product_key  FK │
│ category        │          └──────────│ customer_key FK │
│ subcategory     │                     │ order_date      │
│ cost            │                     │ sales_amount    │
│ product_line    │                     │ quantity        │
└─────────────────┘                     │ price           │
                                        └─────────────────┘
```

---

## Repository Structure

```
SQL_Data_Warehouse_Project/
│
├── datasets/
│   ├── source_crm/
│   │   ├── cust_info.csv
│   │   ├── prd_info.csv
│   │   └── sales_details.csv
│   └── source_erp/
│       ├── CUST_AZ12.csv
│       ├── LOC_A101.csv
│       └── PX_CAT_G1V2.csv
│
├── scripts/
│   ├── bronze/
│   │   ├── ddl_bronze.sql          -- Bronze layer table definitions
│   │   └── proc_load_bronze.sql    -- Bronze stored procedure
│   ├── silver/
│   │   ├── ddl_silver.sql          -- Silver layer table definitions
│   │   └── proc_load_silver.sql    -- Silver stored procedure
│   ├── gold/
│   │   └── ddl_gold.sql            -- Gold layer views (dim + fact)
│   ├── init.sql                    -- Create database + schemas
│   ├── advanced_analytics.sql      -- Business analytics queries
│   ├── exploratory_analysis.sql    -- Exploratory data analysis
│   └── report_views.sql            -- Customer & product reporting views
│
└── README.md
```

---

## ETL Pipeline

### Bronze Layer — `bronze.load_bronze`
- Loads raw CSV data directly into staging tables using `BULK INSERT`
- Full load strategy: `TRUNCATE` then re-insert on every run
- Logs load duration per table and total batch duration
- Error handling via `TRY/CATCH` with detailed error messages

**Tables loaded:**
- `bronze.crm_cust_info` — Customer demographics
- `bronze.crm_prd_info` — Product catalog
- `bronze.crm_sales_details` — Transaction records
- `bronze.erp_cust_az12` — ERP customer data (birthdate, gender)
- `bronze.erp_loc_a101` — Customer location/country
- `bronze.erp_px_cat_g1v2` — Product category hierarchy

---

### Silver Layer — `silver.load_silver`
Applies data quality rules and standardization before loading:

| Table | Key Transformations |
|---|---|
| `crm_cust_info` | Deduplication using `ROW_NUMBER()`, gender/marital status normalization, whitespace trimming |
| `crm_prd_info` | Category ID extraction from product key, product line decoding, SCD2-style end date derived via `LEAD()` |
| `crm_sales_details` | Date integer-to-date casting, sales amount validation (`sales = quantity × price`), null price imputation |
| `erp_cust_az12` | Customer ID prefix cleanup (`NAS` removal), future birthdate nullification, gender normalization |
| `erp_loc_a101` | Customer ID delimiter cleanup, country name standardization (e.g. `US`, `USA` → `United States`) |

---

### Gold Layer — Views
Business-ready views built on top of Silver tables:

- **`gold.dim_customers`** — Unified customer dimension joining CRM + ERP data, with gender conflict resolution
- **`gold.dim_products`** — Active products only (`prd_end_dt IS NULL`), enriched with category hierarchy
- **`gold.fact_sales`** — Sales transactions with surrogate keys linked to dimension views

---

## Analytics

### Exploratory Data Analysis (`07_eda.sql`)
- Schema exploration and data profiling
- Date range and customer age analysis
- KPI summary (total sales, orders, customers, products)
- Segmentation by country and gender
- Top/Bottom N rankings for products and customers

### Advanced Analytics (`08_advanced_analytics.sql`)

| Analysis | Technique Used |
|---|---|
| Time-series sales (Year / Month) | `GROUP BY` with `YEAR()`, `MONTH()` |
| Year-to-date running total | `SUM() OVER (PARTITION BY year ORDER BY date)` |
| Year-over-year product performance | `LAG()` window function + CTEs |
| Category revenue contribution | `SUM() OVER()` for percentage calculation |
| Product cost segmentation | `CASE` bucketing |
| Customer segmentation (VIP / Regular / New) | Lifespan + spend threshold logic |

### Reporting Views
- **`gold.report_customers`** — Per-customer KPIs: AOV, recency, lifespan, avg monthly spend, age group, segment
- **`gold.report_products`** — Per-product KPIs: AOV, recency, lifespan, avg selling price, performance segment

---

## How to Run

1. Run `init.sql` to create the `DataWarehouse` database and schemas
2. Run `bronze/ddl_bronze.sql` and `silver/ddl_silver.sql` to create all tables
3. Run `gold/ddl_gold.sql` to create dimension and fact views
4. Update CSV file paths in `bronze/proc_load_bronze.sql` to match your local environment
5. Execute `EXEC bronze.load_bronze` to load raw data
6. Execute `EXEC silver.load_silver` to cleanse and transform data
7. Query Gold layer views or run `exploratory_analysis.sql` / `advanced_analytics.sql`

---

## Tech Stack

- **Microsoft SQL Server** — Database engine
- **T-SQL** — Stored procedures, views, window functions, CTEs
- **SQL Server Management Studio (SSMS)** — Development environment

---

## Author

**Salah Hesham**
[github.com/salahhesham01](https://github.com/salahhesham01)

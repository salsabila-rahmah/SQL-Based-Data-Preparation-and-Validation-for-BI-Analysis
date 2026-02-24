---/ sqlite - data analysis



---/ CREATE TABLE BACKUP tabel clean data (freezing the table, after cleaning & validating)
CREATE Table IF NOT EXISTS BACKUP_clean_superstore_orders_2 (
    row_id 
        INTEGER 
        PRIMARY KEY AUTOINCREMENT, 
    order_id 
        TEXT 
        NOT NULL 
        CHECK (length(order_id) = 14), 
    order_date 
        DATE -- untuk making sure format date YYYY-MM-DD
        CHECK (order_date GLOB'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'), 
    ship_date 
        DATE -- untuk making sure format date YYYY-MM-DD
        CHECK (ship_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'), 
    ship_mode 
        TEXT 
        NOT NULL, 
    customer_id 
        TEXT 
        NOT NULL 
        CHECK (length(customer_id) = 8), 
    country 
        TEXT 
        NOT NULL, 
    state 
        TEXT 
        NOT NULL, 
    city 
        TEXT 
        NOT NULL, 
    postal_code 
        TEXT 
        NOT NULL, 
    region 
        TEXT 
        NOT NULL, 
    product_id 
        TEXT 
        NOT NULL 
        CHECK (length(product_id) = 15), 
    category 
        TEXT 
        NOT NULL, 
    sub_category 
        TEXT 
        NOT NULL, 
    product_name 
        TEXT 
        NOT NULL, 
    sales 
        DECIMAL(10, 2) 
        NOT NULL 
        CHECK (sales >= 0), 
    quantity 
        INTEGER 
        NOT NULL 
        CHECK (quantity >= 0), 
    discount 
        DECIMAL(3, 2) 
        NOT NULL, 
    profit 
        DECIMAL(10, 2) 
        NOT NULL,
    discount_flag
        TEXT 
        NOT NULL,
    canonical_id 
        TEXT 
        NOT NULL, 
    product_id_std 
        TEXT 
        NOT NULL, 
    flag_percentiles 
        TEXT 
        NOT NULL);



---/ INSERT DATA ke tabel backup clean data
INSERT INTO BACKUP_clean_superstore_orders_2 
SELECT * FROM clean_superstore_orders;

.schema BACKUP_clean_superstore_orders_2 -- cek schema

SELECT * FROM BACKUP_clean_superstore_orders_2; -- cek isi tabel 



---------------------------------------------------------------------------
------------------- CREATE Fact and Dimensions Tables----------------------
---------------------------------------------------------------------------

---/ CREATE FACT TABLE
CREATE TABLE IF NOT EXISTS fact_superstore_orders AS
SELECT
    CAST(strftime('%Y%m%d', order_date) AS INT) AS date_key, -- keys
    product_id_std AS product_key,
    customer_id AS customer_key,
    ship_mode AS shipping_key,
    country || '-' || region || '-' || state || '-' || city || '-' || postal_code AS location_key,
    row_id, -- identifiers
    order_id,
    sales, -- measures
    quantity,
    discount,
    profit,
    CASE    WHEN quantity > 0 THEN sales * 1.0 / quantity -- row-level metrics
            ELSE NULL END AS unit_price, 
    CASE    WHEN sales > 0 THEN profit * 1.0 / sales
            ELSE NULL END AS row_margin,
    discount_flag, -- data flags
    flag_percentiles AS outlier_flag
FROM clean_superstore_orders;



---/ CREATE DIMENSIONS TABLE

---| DIMENSIONS TABLE dim_product
CREATE TABLE IF NOT EXISTS dim_product AS
SELECT DISTINCT
    product_id_std AS product_key,
    product_name,
    category,
    sub_category
FROM clean_superstore_orders;



---| DIMENSIONS TABLE dim_customer
CREATE TABLE IF NOT EXISTS dim_customer AS
SELECT DISTINCT
    customer_id AS customer_key
FROM clean_superstore_orders;



---| DIMENSIONS TABLE dim_location
CREATE TABLE IF NOT EXISTS dim_location AS
SELECT DISTINCT
    country,
    region,
    state,
    city,
    postal_code,
    country || '-' || region || '-' || state || '-' || city || '-' || postal_code AS location_key
FROM clean_superstore_orders;



---| DIMENSIONS TABLE dim_shipping
CREATE TABLE IF NOT EXISTS dim_shipping AS
SELECT DISTINCT
    ship_mode AS shipping_key
FROM clean_superstore_orders;



---| DIMENSIONS TABLE dim_date
CREATE TABLE IF NOT EXISTS dim_date AS
SELECT DISTINCT
    CAST(strftime('%Y%m%d', order_date) AS INT) AS date_key,
    order_date,
    CAST(strftime('%Y', order_date) AS INT) AS year,
    CAST(strftime('%m', order_date) AS INT) AS month,
    CAST(strftime('%d', order_date) AS INT) AS day,
    strftime('%Y-%m', order_date) AS year_month,
    CAST(strftime('%W', order_date) AS INT) AS week,
    CASE    WHEN CAST(strftime('%m', order_date) AS INT) BETWEEN 1 AND 3 THEN 'Q1'
            WHEN CAST(strftime('%m', order_date) AS INT) BETWEEN 4 AND 6 THEN 'Q2'
            WHEN CAST(strftime('%m', order_date) AS INT) BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4' END AS quarter
FROM clean_superstore_orders;



---------------------------------------------------------------------------
--------------------------- CREATE VIEW(s) --------------------------------
---------------------------------------------------------------------------

---| VIEW v_orders_analysis_ready

---| Row-level, clean, safe, filtered
---- excludes hard invalids (already deleted)
---- excludes percentile outliers (outlier_flag = 'OK')
---- keeps row grain
---- exposes only safe row-level metrics

---| used for deep dives, distributions, scatter plots
---- sales vs profit scatter
---- unit price distributions
---- identifying loss-making products
---- regional deep dives
CREATE VIEW IF NOT EXISTS v_orders_analysis_ready AS
SELECT
    f.date_key,
    d.year,
    d.quarter,
    d.year_month,
    d.month,
    f.product_key,
    p.product_name,
    p.category,
    p.sub_category,
    f.customer_key,
    f.location_key,
    l.country,
    l.region,
    l.state,
    l.city,
    f.shipping_key,
    f.order_id,
    f.row_id,
    f.sales,
    f.quantity,
    f.discount,
    f.profit,
    f.unit_price,
    f.row_margin
FROM fact_superstore_orders f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_location l ON f.location_key = l.location_key
WHERE
    f.outlier_flag = 'OK' AND
    f.discount_flag = 'YES';



---| VIEW v_kpi_core

---| Aggregation-safe KPIs
---- margin = SUM(profit) / SUM(sales)
---- no row_margin averaging
---- clean filters already applied

---| used for headline numbers, trends, margins
---- monthly/quarterly trends
---- profit margin over time
---- sales vs profit mismatch
---- executive summary KPIs
---- Power BI cards
---- Tableau KPI tiles
CREATE VIEW IF NOT EXISTS v_kpi_core AS
SELECT
    d.year,
    d.quarter,
    d.year_month,
    p.category,
    p.sub_category,
    l.region,
    l.state,
    COUNT(DISTINCT f.order_id) AS order_count,
    SUM(f.quantity) AS total_quantity,
    SUM(f.sales) AS total_sales,
    SUM(f.profit) AS total_profit,
    CASE    WHEN SUM(f.sales) > 0
            THEN SUM(f.profit) * 1.0 / SUM(f.sales) 
            ELSE NULL END AS profit_margin,
    CASE    WHEN COUNT(DISTINCT f.order_id) > 0
            THEN SUM(f.sales) * 1.0 / COUNT(DISTINCT f.order_id) 
            ELSE NULL END AS aov
FROM fact_superstore_orders f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_location l ON f.location_key = l.location_key
WHERE
    f.outlier_flag = 'OK' AND 
    f.discount_flag = 'YES'
GROUP BY
    d.year,
    d.quarter,
    d.year_month,
    p.category,
    p.sub_category,
    l.region,
    l.state;



---| VIEW v_discount_analysis

---| Discount-focused view

---| used only for discount impact analysis
---- discount vs profit curves
---- finding the “profit cliff”
---- category sensitivity to discounting
---- quantity vs discount analysis
CREATE VIEW IF NOT EXISTS v_discount_analysis AS
SELECT
    d.year,
    d.year_month,
    p.category,
    p.sub_category,
    CASE    WHEN f.discount = 0 THEN '0%'
            WHEN f.discount <= 0.20 THEN '0-20%'
            WHEN f.discount <= 0.40 THEN '20-40%'
            WHEN f.discount <= 0.60 THEN '40-60%'
            ELSE '>60%' END AS discount_level,
    COUNT(*) AS row_count,
    SUM(f.quantity) AS total_quantity,
    SUM(f.sales) AS total_sales,
    SUM(f.profit) AS total_profit,
    CASE    WHEN SUM(f.sales) > 0
            THEN SUM(f.profit) * 1.0 / SUM(f.sales) 
            ELSE NULL END AS profit_margin
FROM fact_superstore_orders f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
WHERE
    f.outlier_flag = 'OK' AND
    f.discount_flag = 'YES'
GROUP BY
    d.year,
    d.year_month,
    p.category,
    p.sub_category,
    discount_level;

.tables



---------------------------------------------------------------------------
----------------------- EXPORT VIEW(s) to CSV -----------------------------
------------------- Running export csv di terminal ------------------------
---------------------------------------------------------------------------

---| Change directory (cd) ke folder spesifik "2. export csv"
PS D:\Salsa\OneDrive\SQL_Files> cd "D:\Salsa\OneDrive\SQL_Files\PORTOFOLIO\Project1\2. export csv"

---| Open database "DB1_Project1.db" yang ada di folder lain
PS D:\Salsa\OneDrive\SQL_Files\PORTOFOLIO\Project1\2. export csv> sqlite3 "D:\Salsa\OneDrive\SQL_Files\PORTOFOLIO\Project1\DB1_Project1.db"

---| Export csv untuk VIEW v_orders_analysis_ready
.mode csv
.headers on
.output orders_analysis_ready.csv
SELECT * FROM v_orders_analysis_ready;
.output stdout

---| Export csv untuk VIEW v_kpi_core
.output kpi_core.csv
SELECT * FROM v_kpi_core;
.output stdout


---| Export csv untuk VIEW v_discount_analysis
.output discount_analysis.csv
SELECT * FROM v_discount_analysis;
.output stdout
.quit

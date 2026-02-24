---/ sqlite - data validation


---/ CREATE TABLE backup tabel clean data
CREATE Table IF NOT EXISTS BACKUP_clean_superstore_orders (
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
        NOT NULL);



---/ INSERT DATA ke tabel backup clean data
INSERT INTO BACKUP_clean_superstore_orders 
SELECT * FROM clean_superstore_orders;
--
SELECT * FROM BACKUP_clean_superstore_orders;



-----------------/ DATA VALIDATION 1 \-----------------
-----------------| GENERAL |---------------------------


---| Cek order_id yang punya lebih dari 1 customer_id
---| Normal: 1 order_id = 1 customer_id
---| Selain itu: anomaly
WITH id_with_multiple_customer AS (
    SELECT order_id, count(DISTINCT customer_id) AS jumlah_customer
    FROM clean_superstore_orders
    GROUP BY order_id
    HAVING jumlah_customer > 1)
SELECT order_id, customer_id
FROM clean_superstore_orders
WHERE order_id IN (
    SELECT order_id FROM id_with_multiple_customer);


SELECT * FROM clean_superstore_orders
WHERE 


-----------------/ DATA VALIDATION 1 \-----------------
------| berunsur tanggal: order_date, ship_date |------

---| Cek DISTINCT tahun di data dengan unsur tanggal
WITH 
    order_year AS (
        SELECT DISTINCT substr(order_date, 1, 4) AS y_order_date
        FROM clean_superstore_orders),
    ship_year AS (
        SELECT DISTINCT substr(ship_date, 1, 4) AS y_ship_date
        FROM clean_superstore_orders)        
SELECT y_order_date, y_ship_date
FROM order_year 
FULL OUTER JOIN ship_year ON y_order_date = y_ship_date
ORDER BY y_ship_date ASC;
 


---| Cek rules 1: 
--- Cek tanggal di masing-masing bulan
--- max 30 hari: bulan 4, 6, 9, 11
--- max 31 hari: bulan 1, 3, 5, 7, 8, 10, 12
--- max 28 / 29: bulan 2 (kabisat 2016, non-kabisat selain 2016)
--- selain itu problem

--// UNTUK order_date
WITH cek_dates AS (
    SELECT DISTINCT
        CAST(substr(order_date, 1, 4) AS INTEGER) AS y_order_date,
        CAST(substr(order_date, 6, 2) AS INTEGER) AS m_order_date,
        CAST(substr(order_date, 9, 2) AS INTEGER) AS d_order_date
    FROM clean_superstore_orders)
SELECT
    y_order_date, 
    m_order_date, 
    max(d_order_date) AS max_date,
    (CASE 
        WHEN max(d_order_date) <= 30 AND m_order_date IN (04, 06, 09, 11) THEN 'OK'
        WHEN max(d_order_date) <= 31 AND m_order_date IN (1, 3, 5, 7, 8, 10, 12) THEN 'OK'
        WHEN max(d_order_date) <= 29 AND y_order_date = 2016 AND m_order_date = 2 THEN 'OK'
        WHEN max(d_order_date) <= 28 AND y_order_date <> 2016 AND m_order_date = 2 THEN 'OK'
        ELSE 'Problem' 
    END) AS status_data
FROM cek_dates 
GROUP BY y_order_date, m_order_date
HAVING status_data <> 'OK'
ORDER BY m_order_date, y_order_date;


--// UNTUK ship_date
WITH cek_dates AS (
    SELECT DISTINCT
        CAST(substr(ship_date, 1, 4) AS INTEGER) AS y_ship_date,
        CAST(substr(ship_date, 6, 2) AS INTEGER) AS m_ship_date,
        CAST(substr(ship_date, 9, 2) AS INTEGER) AS d_ship_date
    FROM clean_superstore_orders)
SELECT
    y_ship_date, 
    m_ship_date, 
    max(d_ship_date) AS max_date,
    (CASE 
        WHEN max(d_ship_date) <= 30 AND m_ship_date IN (04, 06, 09, 11) THEN 'OK'
        WHEN max(d_ship_date) <= 31 AND m_ship_date IN (1, 3, 5, 7, 8, 10, 12) THEN 'OK'
        WHEN max(d_ship_date) <= 29 AND y_ship_date = 2016 AND m_ship_date = 2 THEN 'OK'
        WHEN max(d_ship_date) <= 28 AND y_ship_date <> 2016 AND m_ship_date = 2 THEN 'OK'
        ELSE 'Problem' 
    END) AS status_data
FROM cek_dates 
GROUP BY y_ship_date, m_ship_date
HAVING status_data <> 'OK'
ORDER BY m_ship_date, y_ship_date;



---| Cek rules 2: 
--- order_date < ship_date (Valid, normal shipment)
--- order_date = ship_date (Valid, same day shipment)
--- selain itu problem
SELECT
    order_date, 
    ship_date,
    (CASE 
        WHEN julianday(order_date) < julianday(ship_date) THEN 'OK'
        WHEN julianday(order_date) = julianday(ship_date) THEN 'OK'
        ELSE 'Problem'
    END) AS status_data
FROM clean_superstore_orders
GROUP BY row_id
HAVING status_data <> 'OK'
ORDER BY status_data DESC;


---| Cek rules 3:
--- ship_days = ship_date - order_date 
--- ship_days < 0 is invalid (order_date tidak mungkin lebih dulu dibanding ship_date)
--- ship_days <= 7 hari (normal)
--- ship_days > 7 hari (Flag delay)
SELECT DISTINCT 
    julianday(ship_date) - julianday(order_date) AS ship_days,
    CASE 
        WHEN (julianday(ship_date) - julianday(order_date)) <= 7 THEN 'Normal' 
        ELSE 'Delay'
    END AS status_shipment
FROM clean_superstore_orders
ORDER BY ship_days;


---| Cek rules 4:
-- y_order_date = y_ship_date (Valid)
-- y_ship_date = y_order_date + 1 (Valid, order akhir tahun, shipment awal tahun = beda 1 tahun/PO)
-- y_ship_date > y_order_date + 1 (Invalid, order dan shipment beda lebih dari 1 tahun)
WITH cek_years AS (
    SELECT
        CAST(substr(order_date, 1, 4) AS INTEGER) AS y_order_date,
        CAST(substr(ship_date, 1, 4) AS INTEGER) AS y_ship_date
    FROM clean_superstore_orders
    GROUP BY row_id)
SELECT
    'y_order_date = y_ship_date' AS Problem, 
    sum(CASE WHEN y_order_date = y_ship_date THEN 1 ELSE 0 END),
    round((100.0 * sum(CASE WHEN y_order_date = y_ship_date THEN 1 ELSE 0 END) / (SELECT count(*) FROM clean_superstore_orders)), 2),
    'Valid'
FROM cek_years
UNION ALL
SELECT
    'y_ship_date = 1 + y_order_date',
    sum(CASE WHEN y_ship_date = y_order_date + 1 THEN 1 ELSE 0 END),
    round((100.0 * sum(CASE WHEN y_ship_date = y_order_date + 1 THEN 1 ELSE 0 END) / (SELECT count(*) FROM clean_superstore_orders)), 2),
    'Valid (With Explanation)'
FROM cek_years
UNION ALL
SELECT
    'y_ship_date > 1 + y_order_date',
    sum(CASE WHEN y_ship_date > y_order_date + 1 THEN 1 ELSE 0 END),
    round((100.0 * sum(CASE WHEN y_ship_date > y_order_date + 1 THEN 1 ELSE 0 END) / (SELECT count(*) FROM clean_superstore_orders)), 2),
    'Invalid'
FROM cek_years;

-- Tidak ada data yang bermasalah pada pengecekan tahun di order_date dan ship_date



-----------------/ DATA VALIDATION 2 \-----------------
-------| product_id, category, dan sub_category |------


---| Cek rules 1:
-- pengkodean nama category dan sub_category di product_id
SELECT
    product_id,
    category,
    sub_category,
    (CASE 
        WHEN substr(product_id, 1, 3) = upper(substr(category, 1, 3)) THEN 'OK' 
        ELSE 'Problem' END) AS status_category,
    (CASE
        WHEN substr(product_id, 5, 2) = upper(substr(sub_category, 1, 2)) THEN 'OK' 
        ELSE 'Problem' END) AS status_sub_category
FROM clean_superstore_orders
WHERE 
    status_category = 'Problem' OR 
    status_sub_category = 'Problem';

--- pengkodean category dan sub_category di product_id tidak ada yang bermasalah



-----------------/ DATA VALIDATION 3 \-----------------
-----| country, state, city, postal_code, region |-----



---| Rules 1:
---| postal_code = 1 city (atau city alias)
---| Selain itu cek manual
WITH 
    cek_double_postal_code AS (
        SELECT postal_code, count(DISTINCT city) AS jumlah_city
        FROM clean_superstore_orders
        GROUP BY postal_code HAVING jumlah_city > 1)
SELECT DISTINCT 
    country, state, city, postal_code
FROM clean_superstore_orders
WHERE postal_code IN (SELECT postal_code FROM cek_double_postal_code);



---/ Problem data yang terdeteksi:
-- 1. postal_code = 92024 punya 2 city (San Diego, Encinitas)
--->  seharusnya Encinitas (atau nama alias Leucadia, Olivenhain), bukan San Diego
--->  SOLUTION: update 92024 San Diego ke Encinitas



---/ INPUT KE LOG TABLE
---| 1. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : postal_code punya city > 1
---  attribute : postal_code, city
---  solution : update San Diego to Encinitas
WITH update_postal_code AS (
    SELECT row_id FROM clean_superstore_orders
    WHERE postal_code = 92024 AND city = 'San Diego'
    ORDER BY row_id)
INSERT INTO audit_log 
    (row_id, status_log, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'VALID',
    'postal_code', 
    'postal_code punya city > 1', 
    'update San Diego to Encinitas',
    'clean_superstore_orders', 
    (SELECT count(row_id) FROM clean_superstore_orders)   
FROM update_postal_code;



---| UPDATE DATA PROBLEMATIC (update San Diego to Encinitas)
---- tabel clean data
UPDATE clean_superstore_orders
SET city = 'Encinitas'
WHERE postal_code = 92024 AND city = 'San Diego';



---| Rules 2: 
---| 1 city = 1 state (normal)
---| 1 city > 1 state (valid, but cek dulu)
---| Selain itu cek dengan data external dan cek manual 
---| Result: state-city valid semua (cek manual)
WITH 
    db_double_city AS (
        SELECT city, count(DISTINCT state) AS jumlah_state_db
        FROM clean_superstore_orders
        GROUP BY city HAVING jumlah_state_db > 1),
    ex_double_city AS (
        SELECT city, count(DISTINCT state) AS jumlah_state_ex
        FROM external_state_city
        GROUP BY city HAVING jumlah_state_ex > 1)
SELECT DISTINCT 
    state,
    group_concat(DISTINCT city) 
FROM clean_superstore_orders
GROUP BY state, city
HAVING 
    city IN (SELECT city FROM db_double_city) AND 
    city NOT IN (SELECT city FROM ex_double_city)
ORDER BY state, city;



---| Rules 3: 
---| 1 state = 1 region
---| Selain itu cek manual
---| Result: state-region valid semua
SELECT state, count(DISTINCT region) AS jumlah_region_db
FROM clean_superstore_orders
GROUP BY state
HAVING jumlah_region_db > 1;



-----------------/ DATA VALIDATION 4 \-----------------
-----| product_id, product_name |-----

---| Cek indikasi problem di product_id dan product_name
---| Problem: jumlah baris product_id ≠ product_name
SELECT 
    count(DISTINCT product_id) AS jumlah_id,
    count(DISTINCT product_name) AS jumlah_nama
FROM clean_superstore_orders;

---| Rules 1:
---| 1 product_name = 1 product_id
WITH name_with_multiple_id AS (
    SELECT
        product_name,
        count(DISTINCT product_id) AS id_variants
    FROM clean_superstore_orders
    GROUP BY product_name
    HAVING id_variants > 1)
SELECT DISTINCT
    row_id, product_name, product_id
FROM clean_superstore_orders
WHERE product_name IN (
    SELECT product_name FROM name_with_multiple_id)
ORDER BY product_name, product_id;


---/ Problem data yang terdeteksi:
-- 1. product_name punya > 1 product_id
--    SOLUTION  → flag to name_with multiples_id dan menggunakan canonical_id


---/ INPUT KE LOG TABLE
---| INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : product_name punya > 1 product_id
---  attribute : product_name, product_id
---  solution : flag to name_with multiples_id dan menggunakan canonical_id
WITH update_name_with_multiple_id AS (
    SELECT row_id
    FROM clean_superstore_orders
    WHERE product_name IN (
        SELECT product_name
        FROM clean_superstore_orders
        GROUP BY product_name
        HAVING count(DISTINCT product_id) > 1)
    ORDER BY row_id)
INSERT INTO audit_log 
    (row_id, status_log, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'VALID',
    'product_name, product_id', 
    'product_name punya > 1 product_id', 
    'flag to name_with multiples_id dan menggunakan canonical_id',
    'clean_superstore_orders', 
    (SELECT count(row_id) FROM clean_superstore_orders)   
FROM update_name_with_multiple_id;


--- membuat kolom baru canonical_id
ALTER TABLE clean_superstore_orders
ADD COLUMN canonical_id TEXT;


--- update data canonical_id setelah normalisasi 1 product_name = 1 product_id
WITH 
freq_groups AS (
    SELECT 
        product_name,
        product_id,
        COUNT(*) AS freq
    FROM clean_superstore_orders
    GROUP BY product_name, product_id),
chosen AS (
    SELECT 
        product_name,
        product_id AS canonical_id
    FROM (  SELECT 
                product_name,
                product_id,
                ROW_NUMBER() OVER (
                    PARTITION BY product_name 
                    ORDER BY freq DESC ) AS ranking
            FROM freq_groups )
    WHERE ranking = 1)
UPDATE clean_superstore_orders
SET canonical_id = (
    SELECT c.canonical_id
    FROM chosen c
    WHERE c.product_name = clean_superstore_orders.product_name);


--- cek nama yang punya > 1 canonical_id
WITH name_with_multiple_id AS (
    SELECT
        product_name,
        count(DISTINCT canonical_id) AS id_variants
    FROM clean_superstore_orders
    GROUP BY product_name
    HAVING id_variants > 1)
SELECT DISTINCT product_name, canonical_id
FROM clean_superstore_orders
WHERE product_name IN (
    SELECT product_name FROM name_with_multiple_id)
ORDER BY product_name, canonical_id;


---| Rules 2:
---| 1 (product_id) canonical_id = 1 product_name
WITH 
    id_with_multiple_name AS (
        SELECT 
            canonical_id, 
            count(DISTINCT product_name) AS name_variants
        FROM clean_superstore_orders
        GROUP BY canonical_id
        HAVING name_variants > 1)
SELECT DISTINCT canonical_id, product_name
FROM clean_superstore_orders
WHERE canonical_id IN (
    SELECT canonical_id FROM id_with_multiple_name)
ORDER BY canonical_id ASC;


---/ Problem data yang terdeteksi:
-- 1. canonical_id punya > 1 product_name
--    SOLUTION  → flag to id_with_multiple_name dan menggunakan product_id_std



---/ INPUT KE LOG TABLE
---| INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : canonical_id punya > 1 product_name
---  attribute : canonical_id, product_name
---  solution : flag to name_with multiples_id dan menggunakan product_id_std
WITH update_id_with_multiple_name AS (
    SELECT row_id
    FROM clean_superstore_orders
    WHERE canonical_id IN (
        SELECT canonical_id
        FROM clean_superstore_orders
        GROUP BY canonical_id
        HAVING count(DISTINCT product_name) > 1)
    ORDER BY row_id)
INSERT INTO audit_log 
    (row_id, status_log, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'VALID',
    'canonical_id, product_name', 
    'canonical_id punya > 1 product_name', 
    'flag to id_with_multiple_name dan menggunakan product_id_std',
    'clean_superstore_orders', 
    (SELECT count(row_id) FROM clean_superstore_orders)   
FROM update_id_with_multiple_name;


--- membuat kolom baru product_id_std
ALTER TABLE clean_superstore_orders
ADD COLUMN product_id_std TEXT;


--- update data product_id_std setelah normalisasi 1 (product_id) canonical_id = 1 product_name
WITH 
    problematic_id AS (
        SELECT DISTINCT canonical_id, product_name 
        FROM clean_superstore_orders
        WHERE canonical_id IN (
            SELECT canonical_id FROM clean_superstore_orders
            GROUP BY canonical_id HAVING count(DISTINCT product_name) > 1)
        ORDER BY canonical_id, product_name),
    row_address AS (
        SELECT 
            canonical_id, product_name,
            row_number() OVER (
                PARTITION BY canonical_id 
                ORDER BY product_name) AS rank_id
        FROM problematic_id),
    new_canon_product_id AS (
        SELECT
            canonical_id,
            canonical_id || '_' || rank_id AS new_canonical_id,
            product_name
        FROM row_address
        ORDER BY canonical_id)
UPDATE clean_superstore_orders
SET product_id_std = COALESCE(
    ( SELECT n.new_canonical_id
        FROM new_canon_product_id n
        WHERE n.canonical_id = clean_superstore_orders.canonical_id
          AND n.product_name = clean_superstore_orders.product_name ), canonical_id );


-- cek product_id_std yang punya > 1 nama
WITH 
    id_with_multiple_name AS (
        SELECT 
            product_id_std, 
            count(DISTINCT product_name) AS name_variants
        FROM clean_superstore_orders
        GROUP BY product_id_std
        HAVING name_variants > 1)
SELECT DISTINCT product_id_std, product_name
FROM clean_superstore_orders
WHERE product_id_std IN (
    SELECT product_id_std FROM id_with_multiple_name)
ORDER BY product_id_std ASC;



---| Final check
---| OK = jumlah baris product_id_std = product_name
SELECT 
    count(DISTINCT product_id_std) AS jumlah_product_id,
    count(DISTINCT product_name) AS jumlah_nama
FROM clean_superstore_orders;


-----------------/ DATA VALIDATION 4 \-----------------
---------| profit, sales, quantity, discount |---------


---/ RULES HARD INVALID (DELETE):
---| 1. quantity <= 0
---- Tidak mungkin quantity minus
---| 2. discount < 0 OR discount > 1
---- Tidak mungkin diskon lebih kecil 0 atau lebih besar dari 100%
---| 3. profit > sales
---- profit = sales - cost
---- Dari sudut bisnis retail, mustahil profit > sales karena ini menandakan cost negatif. Oleh karena itu perlu dihapus.
---| 4. profit < -sales
---- profit = sales - cost
---- Problem ini berarti menjual barang yang cost-nya lebih besar dibanding harga barang itu sendiri alias merugi. Hal ini tidak realistis di dunia bisnis.
---| 5. sales = 0 AND quantity >= 1 AND discount < 1 AND profit >= 0
---- Sales tidak masuk akal terhadap quantity & discount. Barang dikirim Tidak free (discount < 100%) Tidak rugi → impossible

WITH invalid_data AS (
    SELECT
        row_id,
        (CASE 
            WHEN quantity <= 0 THEN 'INVALID quantity <= 0'
            WHEN discount < 0 OR discount > 1 THEN 'INVALID discount < 0'
            WHEN profit > sales THEN 'INVALID profit > sales'
            WHEN profit < -sales THEN 'INVALID profit < -sales'
            WHEN sales = 0 AND quantity >= 1 AND discount < 1 AND profit >= 0 THEN 'INVALID Sales'
            ELSE 'Data OK'
        END) reason_invalid
    FROM clean_superstore_orders
    GROUP BY row_id)
SELECT 
    reason_invalid, 
    count(reason_invalid) AS jumlah_invalid
FROM invalid_data
GROUP BY reason_invalid;



---/ Problem data yang terdeteksi:
-- 1. INVALID (profit > sales)
-- 2. INVALID (profit < -sales)
-- 3. INVALID Sales (sales = 0 AND quantity >= 1 AND discount < 1 AND profit >= 0)
--    SOLUTION  → remove invalid data



---/ INPUT KE LOG TABLE
---| 1. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : 3 hal di atas
---  attribute : sales, profit
---  solution : remove invalid data
WITH remove_data AS (
    SELECT
        row_id,
        (CASE 
            WHEN quantity <= 0 THEN 'INVALID quantity <= 0'
            WHEN discount < 0 OR discount > 1 THEN 'INVALID discount < 0'
            WHEN profit > sales THEN 'INVALID profit > sales'
            WHEN profit < -sales THEN 'INVALID profit < -sales'
            WHEN sales = 0 AND quantity >= 1 AND discount < 1 AND profit >= 0 THEN 'INVALID Sales'
            ELSE 0
        END) reason_invalid
    FROM clean_superstore_orders
    GROUP BY row_id
    ORDER BY row_id)
INSERT INTO audit_log 
    (row_id, status_log, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id,
    'VALID', 
    'sales, profit', 
    reason_invalid, 
    'remove invalid data',
    'clean_superstore_orders', 
    (SELECT count(row_id) FROM clean_superstore_orders)   
FROM remove_data
WHERE reason_invalid <> 0;



---| UPDATE DATA PROBLEMATIC (Invalid sales, profit)
---- tabel clean data
DELETE FROM clean_superstore_orders
WHERE 
    quantity <= 0 OR
    discount < 0 OR
    profit > sales OR 
    profit < -sales OR
    sales = 0 AND quantity >= 1 AND discount < 1 AND profit >= 0;



---/ RULES SOFT INVALID / ANOMALY:
--- validasi data berdasarkan percentile data
--- Metriks uji: unit_price, sales, profit, and margin
--- Per sub_category
CREATE VIEW IF NOT EXISTS v_anomaly_by_percentile AS 
WITH 
    base AS (
        SELECT
            clean_superstore_orders.*,
            (sales * 1.0 / quantity) AS unit_price,
            (profit * 1.0 / sales) AS margin
        FROM clean_superstore_orders
        WHERE quantity > 0 AND sales >= 0 ),
    ranked AS (
        SELECT
            base.*,
            ROW_NUMBER() OVER (PARTITION BY sub_category ORDER BY unit_price) AS rank_unit_price,
            ROW_NUMBER() OVER (PARTITION BY sub_category ORDER BY sales) AS rank_sales,
            ROW_NUMBER() OVER (PARTITION BY sub_category ORDER BY profit) AS rank_profit,
            ROW_NUMBER() OVER (PARTITION BY sub_category ORDER BY margin) AS rank_margin,
            COUNT(*) OVER (PARTITION BY sub_category) AS n
        FROM base),
    percentiles AS (
        SELECT
            sub_category,
            MAX(CASE WHEN rank_unit_price = CAST(0.01 * n AS INT) THEN unit_price END) AS p01_unit_price,
            MAX(CASE WHEN rank_unit_price = CAST(0.99 * n AS INT) THEN unit_price END) AS p99_unit_price,
            MAX(CASE WHEN rank_sales = CAST(0.01 * n AS INT) THEN sales END) AS p01_sales,
            MAX(CASE WHEN rank_sales = CAST(0.99 * n AS INT) THEN sales END) AS p99_sales,
            MAX(CASE WHEN rank_profit = CAST(0.01 * n AS INT) THEN profit END) AS p01_profit,
            MAX(CASE WHEN rank_profit = CAST(0.99 * n AS INT) THEN profit END) AS p99_profit,
            MAX(CASE WHEN rank_margin = CAST(0.01 * n AS INT) THEN margin END) AS p01_margin,
            MAX(CASE WHEN rank_margin = CAST(0.99 * n AS INT) THEN margin END) AS p99_margin
        FROM ranked
        GROUP BY sub_category),
    flagged AS (
        SELECT
            ranked.*,
            CASE 
                WHEN unit_price < p01_unit_price THEN 'LOW_OUTLIER unit_price' 
                WHEN unit_price > p99_unit_price THEN 'HIGH_OUTLIER unit_price'
                ELSE 'OK' END AS flag_unit_price,
            CASE 
                WHEN sales < p01_sales THEN 'LOW_OUTLIER sales' 
                WHEN sales > p99_sales THEN 'HIGH_OUTLIER sales' 
                ELSE 'OK' END AS flag_sales,
            CASE 
                WHEN profit < p01_profit THEN 'LOW_OUTLIER profit' 
                WHEN profit > p99_profit THEN 'HIGH_OUTLIER profit' 
                ELSE 'OK' END AS flag_profit,
            CASE 
                WHEN margin < p01_margin THEN 'LOW_OUTLIER margin' 
                WHEN margin > p99_margin THEN 'HIGH_OUTLIER margin' 
                ELSE 'OK' END AS flag_margin
        FROM ranked
        JOIN percentiles
        ON ranked.sub_category = percentiles.sub_category)
SELECT * FROM flagged
GROUP BY row_id
ORDER BY row_id;

-- CEK VIEW v_anomaly_by_percentile
SELECT * FROM v_anomaly_by_percentile 
GROUP BY row_id
HAVING 
    flag_unit_price <> 'OK' OR
    flag_sales <> 'OK' OR
    flag_profit <> 'OK' OR
    flag_margin <> 'OK';



---/ Problem data yang terdeteksi:
-- 1. ANOMALY percentiles unit_price < p01 atau > p99
-- 2. ANOMALY percentiles sales < p01 atau > p99
-- 3. ANOMALY percentiles profit < p01 atau > p99
-- 4. ANOMALY percentiles margin < p01 atau > p99
--    SOLUTION  → flag to: flag_unit_price, flag_sales, flag_profit, flag_margin



---/ INPUT KE LOG TABLE
---| INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : percentiles metriks < p01 atau > p99
---  attribute : unit_price, sales, profit, margin
---  solution : flag to: flag_unit_price, flag_sales, flag_profit, flag_margin
WITH 
    anomaly_group AS (
        SELECT row_id, flag_unit_price AS status_data FROM v_anomaly_by_percentile
        UNION ALL
        SELECT row_id, flag_sales FROM v_anomaly_by_percentile
        UNION ALL
        SELECT row_id, flag_profit FROM v_anomaly_by_percentile
        UNION ALL
        SELECT row_id, flag_margin FROM v_anomaly_by_percentile),
    insert_anomaly AS (
        SELECT row_id, replace(group_concat (status_data), 'OK', '-') AS reasons
        FROM anomaly_group
        GROUP BY row_id
        HAVING group_concat (status_data) <> 'OK,OK,OK,OK'
        ORDER BY row_id)
INSERT INTO audit_log 
    (row_id, status_log, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id,
    'VALID', 
    'unit_price, sales, profit, margin', 
    reasons, 
    'flag to: flag_unit_price, flag_sales, flag_profit, flag_margin',
    'clean_superstore_orders', 
    (SELECT count(row_id) FROM clean_superstore_orders)   
FROM insert_anomaly;



---| UPDATE DATA ANOMALY (by percentiles)
---- tabel clean data


--- membuat kolom baru flag_percentiles
ALTER Table clean_superstore_orders
ADD COLUMN flag_percentiles TEXT;


--- update data flag_percentiles 
WITH 
    anomaly_group AS (
        SELECT row_id, flag_unit_price AS status_data FROM v_anomaly_by_percentile
        UNION ALL
        SELECT row_id, flag_sales FROM v_anomaly_by_percentile
        UNION ALL
        SELECT row_id, flag_profit FROM v_anomaly_by_percentile
        UNION ALL
        SELECT row_id, flag_margin FROM v_anomaly_by_percentile),
    insert_anomaly AS (
        SELECT row_id, replace(group_concat (status_data), 'OK', '-') AS reasons
        FROM anomaly_group
        GROUP BY row_id
        HAVING group_concat (status_data) <> 'OK,OK,OK,OK'
        ORDER BY row_id)
UPDATE clean_superstore_orders
SET flag_percentiles = 
    coalesce(
        (SELECT reasons 
        FROM insert_anomaly
        WHERE clean_superstore_orders.row_id = insert_anomaly.row_id), 
        'OK');




--- cek duplikat berdasarkan all rows (kecuali row_id, )



---/ CEK DATA (duplikat based on all rows, kecuali row_id (pake product_id_std)
---- tabel data clean

---- tidak ada data duplikat di tabel setelah validation
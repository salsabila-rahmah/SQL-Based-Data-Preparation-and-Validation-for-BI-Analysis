---/ sqlite - data cleaning
---/ sqlite - create tabel data raw dan clean



---| Cek isi tabel
SELECT * FROM raw_superstore_orders;
SELECT * FROM clean_superstore_orders;




---/ TAHAP 0 — PERSIAPAN

---| Import file csv to databases
sqlite3 "D:\Salsa\OneDrive\SQL_Files\PORTOFOLIO\Project1\DB1_Project1.db"
.databases
.tables
.mode csv


--- The folder path (D:/......./Superstore_Orders_q1.csv) depends on where you save them

.import "D:/Salsa/OneDrive/SQL_Files/PORTOFOLIO/Project1/Superstore_Orders_q1.csv" csv1
.import "D:/Salsa/OneDrive/SQL_Files/PORTOFOLIO/Project1/Superstore_Orders_q2.csv" csv2
.import "D:/Salsa/OneDrive/SQL_Files/PORTOFOLIO/Project1/raw_state_city.csv" raw_state_city


.schema csv1
.schema csv2
.schema zip_code_csv



---| Cek isi csv1 dan csv2
SELECT * FROM csv1 UNION ALL
SELECT * FROM csv2;



---/ CREATE TABLE untuk raw data
---| All attributes in lowercase no space
CREATE Table IF NOT EXISTS raw_superstore_orders (
    row_id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id TEXT,
    order_date DATE, 
    ship_date DATE, 
    ship_mode TEXT, 
    customer_id TEXT, 
    country TEXT, 
    state TEXT, 
    city TEXT, 
    postal_code TEXT, 
    region TEXT, 
    product_id TEXT, 
    category TEXT, 
    sub_category TEXT, 
    product_name TEXT, 
    sales DECIMAL(10,2), 
    quantity INTEGER, 
    discount DECIMAL(4,2), 
    profit DECIMAL(10,2) );



---/ INSERT DATA ke tabel raw data
---| Rewrite all attributes (instead of select all) karena mau mengubah penamaan (ex: Row ID to row_id)
---| Kolom country, state, city di data import tidak berurutan, jadi perlu diurutkan peletakannya
WITH csv_combined AS (
    SELECT 
        "Row ID",
        "Order ID",
        DATE(substr("Order Date", 7, 4) || '-' || substr("Order Date", 1, 2) || '-' || substr("Order Date", 4, 2)) AS "Order Date",
        DATE(substr("Ship Date", 7, 4) || '-' || substr("Ship Date", 1, 2) || '-' || substr("Ship Date", 4, 2)) AS "Ship Date",
        "Ship Mode",
        "Customer ID",
        "Country",
        "State",
        "City", 
        printf('%05d', "Postal Code"),
        "Region",
        "Product ID", 
        "Category",
        "Sub-Category",
        "Product Name",
        round("Sales", 2), 
        "Quantity",
        "Discount",
        round("Profit",2) FROM csv1
    UNION ALL
    SELECT 
        "Row ID",
        "Order ID",
        DATE(substr("Order Date", 7, 4) || '-' || substr("Order Date", 1, 2) || '-' || substr("Order Date", 4, 2)) AS "Order Date",
        DATE(substr("Ship Date", 7, 4) || '-' || substr("Ship Date", 1, 2) || '-' || substr("Ship Date", 4, 2)) AS "Ship Date",
        "Ship Mode",
        "Customer ID",
        "Country",
        "State",
        "City", 
        printf('%05d', "Postal Code"),
        "Region",
        "Product ID", 
        "Category",
        "Sub-Category",
        "Product Name",
        round("Sales", 2), 
        "Quantity",
        "Discount",
        round("Profit",2) FROM csv2)
INSERT INTO raw_superstore_orders (
        row_id, 
        order_id, 
        order_date, 
        ship_date, 
        ship_mode, 
        customer_id, 
        country, 
        state, 
        city, 
        postal_code, 
        region, 
        product_id, 
        category, 
        sub_category, 
        product_name, 
        sales, 
        quantity, 
        discount, 
        profit)
SELECT * FROM csv_combined;



---/ CREATE TABLE backup tabel raw data (BACKUP_raw_superstore_orders)
---| All attributes in lowercase no space (format sama kaya raw_superstore_orders)
CREATE Table IF NOT EXISTS BACKUP_raw_superstore_orders (
    row_id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id TEXT,
    order_date DATE, 
    ship_date DATE, 
    ship_mode TEXT, 
    customer_id TEXT, 
    country TEXT, 
    state TEXT, 
    city TEXT, 
    postal_code TEXT, 
    region TEXT, 
    product_id TEXT, 
    category TEXT, 
    sub_category TEXT, 
    product_name TEXT, 
    sales DECIMAL(10,2), 
    quantity INTEGER, 
    discount DECIMAL(4,2), 
    profit DECIMAL(10,2) );



---/ INSERT DATA ke BACKUP_raw_superstore_orders
INSERT INTO BACKUP_raw_superstore_orders 
SELECT * FROM raw_superstore_orders;





---/ CREATE TABLE external_state_city
CREATE Table if  NOT exists external_state_city (
    state TEXT,
    city TEXT,
    UNIQUE (state, city) );


---/ INSERT INTO TABLE external_state_city
WITH
    insert_state_city AS (
        SELECT 
            substr("State;City", 1, instr("State;City",';') - 1) AS state,
            substr("State;City", instr("State;City",';') + 1) AS city
        FROM raw_state_city
        ORDER BY state, city)
INSERT INTO external_state_city (State, city)
SELECT state, city FROM insert_state_city;





---| CEK DATA PROBLEMATIC (NULL, blank '', double space, strips) 
---- tabel raw data
WITH cek_issues AS (
    SELECT 
        'row_id' AS attributes,
        SUM(row_id IS NULL) AS "NULL", 
        SUM(trim(row_id) = '') AS "BLANK", 
        SUM(trim(row_id) LIKE '%  %') AS "SPACES",
        SUM(row_id LIKE '%--%') AS "STRIPS"
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'order_id',
        SUM(order_id IS NULL), 
        SUM(trim(order_id) = ''), 
        SUM(trim(order_id) LIKE '%  %'),
        SUM(order_id LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'order_date',
        SUM(order_date IS NULL), 
        SUM(trim(order_date) = ''), 
        SUM(trim(order_date) LIKE '%  %'),
        SUM(order_date LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'ship_date',
        SUM(ship_date IS NULL), 
        SUM(trim(ship_date) = ''), 
        SUM(trim(ship_date) LIKE '%  %'),
        SUM(ship_date LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'ship_mode',
        SUM(ship_mode IS NULL), 
        SUM(trim(ship_mode) = ''), 
        SUM(trim(ship_mode) LIKE '%  %'),
        SUM(ship_mode LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'customer_id',
        SUM(customer_id IS NULL), 
        SUM(trim(customer_id) = ''), 
        SUM(trim(customer_id) LIKE '%  %'),
        SUM(customer_id LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'country',
        SUM(country IS NULL), 
        SUM(trim(country) = ''), 
        SUM(trim(country) LIKE '%  %'),
        SUM(country LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'state',
        SUM(state IS NULL), 
        SUM(trim(state) = ''), 
        SUM(trim(state) LIKE '%  %'),
        SUM(state LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'city',
        SUM(city IS NULL), 
        SUM(trim(city) = ''), 
        SUM(trim(city) LIKE '%  %'),
        SUM(city LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'postal_code',
        SUM(postal_code IS NULL), 
        SUM(trim(postal_code) = ''), 
        SUM(trim(postal_code) LIKE '%  %'),
        SUM(postal_code LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'region',
        SUM(region IS NULL), 
        SUM(trim(region) = ''), 
        SUM(trim(region) LIKE '%  %'),
        SUM(region LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'product_id',
        SUM(product_id IS NULL), 
        SUM(trim(product_id) = ''), 
        SUM(trim(product_id) LIKE '%  %'),
        SUM(product_id LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'category',
        SUM(category IS NULL), 
        SUM(trim(category) = ''), 
        SUM(trim(category) LIKE '%  %'),
        SUM(category LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'sub_category',
        SUM(sub_category IS NULL), 
        SUM(trim(sub_category) = ''), 
        SUM(trim(sub_category) LIKE '%  %'),
        SUM(sub_category LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'product_name',
        SUM(product_name IS NULL), 
        SUM(trim(product_name) = ''), 
        SUM(trim(product_name) LIKE '%  %'),
        SUM(product_name LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'sales',
        SUM(sales IS NULL), 
        SUM(trim(sales) = ''), 
        SUM(trim(sales) LIKE '%  %'),
        SUM(sales LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'quantity',
        SUM(quantity IS NULL), 
        SUM(trim(quantity) = ''), 
        SUM(trim(quantity) LIKE '%  %'),
        SUM(quantity LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'discount',
        SUM(discount IS NULL), 
        SUM(trim(discount) = ''), 
        SUM(trim(discount) LIKE '%  %'),
        SUM(discount LIKE '%--%')
    FROM raw_superstore_orders
    UNION ALL
    SELECT 
        'profit',
        SUM(profit IS NULL), 
        SUM(trim(profit) = ''), 
        SUM(trim(profit) LIKE '%  %'),
        SUM(profit LIKE '%--%')
    FROM raw_superstore_orders)
SELECT * FROM cek_issues
ORDER BY "NULL" DESC, "BLANK" DESC, "SPACES" DESC, "STRIPS" DESC;


---/ Problem data yang terdeteksi:
-- 1. BLANK     → discount, region
--    SOLUTION  → UPDATE ke 'BLANK'
-- 2. STRIPS    → region
--    SOLUTION  → UPDATE ke 'Unknown'
-- 3. SPACES    → product_name
--    SOLUTION  → TRIM column


---/ INPUT KE LOG TABLE
---| 1. INSERT PROBLEMATIC DATA
---  source_table : raw_superstore_orders
---  reason : BLANK
---  attribute : discount
---  solution : flag as BLANK
INSERT INTO audit_log 
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'discount', 
    'BLANK', 
    'flag as BLANK',
    'raw_superstore_orders', 
    (SELECT count(row_id) FROM raw_superstore_orders)   
FROM raw_superstore_orders
GROUP BY row_id
HAVING discount = ''
ORDER BY row_id;


---| 2. INSERT PROBLEMATIC DATA
---  source_table : raw_superstore_orders
---  reason : BLANK
---  attribute : region
---  solution : flag as Unknown
INSERT INTO audit_log 
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'region', 
    'BLANK', 
    'flag as Unknown',
    'raw_superstore_orders', 
    (SELECT count(row_id) FROM raw_superstore_orders)   
FROM raw_superstore_orders
GROUP BY row_id
HAVING region = ''
ORDER BY row_id;


---| 3. INSERT PROBLEMATIC DATA
---  source_table : raw_superstore_orders
---  reason : STRIPS
---  attribute : region
---  solution : flag as Unknown
INSERT INTO audit_log 
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'region', 
    'STRIPS', 
    'flag as Unknown',
    'raw_superstore_orders', 
    (SELECT count(row_id) FROM raw_superstore_orders)   
FROM raw_superstore_orders
GROUP BY row_id
HAVING region LIKE '%--%'
ORDER BY row_id;


---| 4. INSERT PROBLEMATIC DATA
---  source_table : raw_superstore_orders
---  reason : SPACES
---  attribute : product_name
---  solution : replace spaces to a space
INSERT INTO audit_log 
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'product_name', 
    'SPACES', 
    'replace spaces to a space',
    'raw_superstore_orders', 
    (SELECT count(row_id) FROM raw_superstore_orders)   
FROM raw_superstore_orders
GROUP BY row_id
HAVING product_name LIKE '%  %'
ORDER BY row_id;


---| UPDATE DATA PROBLEMATIC (NULL, blank '', double space, strips)
---- tabel raw data
UPDATE raw_superstore_orders
SET 
    discount = CASE 
        WHEN discount = '' THEN 'BLANK'
        ELSE discount END,
    region = CASE 
        WHEN region = '' OR region LIKE '%--%' THEN 'Unknown' 
        ELSE region END,
    product_name = CASE 
        WHEN product_name LIKE '%  %' THEN REPLACE(product_name, '  ', ' ')
        ELSE product_name END;



---/ CREATE TABLE untuk cleaning data
---- With more specific and proper data types for each attributes
CREATE Table IF NOT EXISTS clean_superstore_orders (
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
    quantity INTEGER 
        NOT NULL 
        CHECK (quantity >= 0), 
    discount DECIMAL(3, 2) 
        NOT NULL, 
    profit DECIMAL(10, 2) 
        NOT NULL);



---/ INSERT DATA ke tabel clean data
INSERT INTO clean_superstore_orders
SELECT * FROM raw_superstore_orders;



---/ Cek schema dan isi tabel clean data
.schema clean_superstore_orders;

SELECT * FROM clean_superstore_orders;



---/ TRIM all fields
UPDATE clean_superstore_orders
SET 
    row_id = trim(row_id),
    order_id = trim(order_id),
    order_date = trim(order_date),
    ship_date = trim(ship_date),
    ship_mode = trim(ship_mode),
    customer_id = trim(customer_id),
    country = trim(country),
    state = trim(state),
    city = trim(city),
    postal_code = trim(postal_code),
    region = trim(region),
    product_id = trim(product_id),
    category = trim(category),
    sub_category = trim(sub_category),
    product_name = trim(product_name),
    sales = trim(sales),
    quantity = trim(quantity),
    discount = trim(discount),
    profit = trim(profit);



---| CEK DATA PROBLEMATIC (NULL, blank '', double space, strips) 
---- tabel data clean
WITH cek_issues AS (
    SELECT 
        'row_id' AS attribute,
        SUM(row_id IS NULL) AS issue_null, 
        SUM(trim(row_id) = '') AS issue_blank, 
        SUM(trim(row_id) LIKE '%  %') AS issue_spaces,
        SUM(row_id LIKE '%--%') AS issue_strips
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'order_id',
        SUM(order_id IS NULL), 
        SUM(trim(order_id) = ''), 
        SUM(trim(order_id) LIKE '%  %'),
        SUM(order_id LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'order_date',
        SUM(order_date IS NULL), 
        SUM(trim(order_date) = ''), 
        SUM(trim(order_date) LIKE '%  %'),
        SUM(order_date LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'ship_date',
        SUM(ship_date IS NULL), 
        SUM(trim(ship_date) = ''), 
        SUM(trim(ship_date) LIKE '%  %'),
        SUM(ship_date LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'ship_mode',
        SUM(ship_mode IS NULL), 
        SUM(trim(ship_mode) = ''), 
        SUM(trim(ship_mode) LIKE '%  %'),
        SUM(ship_mode LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'customer_id',
        SUM(customer_id IS NULL), 
        SUM(trim(customer_id) = ''), 
        SUM(trim(customer_id) LIKE '%  %'),
        SUM(customer_id LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'country',
        SUM(country IS NULL), 
        SUM(trim(country) = ''), 
        SUM(trim(country) LIKE '%  %'),
        SUM(country LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'state',
        SUM(state IS NULL), 
        SUM(trim(state) = ''), 
        SUM(trim(state) LIKE '%  %'),
        SUM(state LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'city',
        SUM(city IS NULL), 
        SUM(trim(city) = ''), 
        SUM(trim(city) LIKE '%  %'),
        SUM(city LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'postal_code',
        SUM(postal_code IS NULL), 
        SUM(trim(postal_code) = ''), 
        SUM(trim(postal_code) LIKE '%  %'),
        SUM(postal_code LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'region',
        SUM(region IS NULL), 
        SUM(trim(region) = ''), 
        SUM(trim(region) LIKE '%  %'),
        SUM(region LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'product_id',
        SUM(product_id IS NULL), 
        SUM(trim(product_id) = ''), 
        SUM(trim(product_id) LIKE '%  %'),
        SUM(product_id LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'category',
        SUM(category IS NULL), 
        SUM(trim(category) = ''), 
        SUM(trim(category) LIKE '%  %'),
        SUM(category LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'sub_category',
        SUM(sub_category IS NULL), 
        SUM(trim(sub_category) = ''), 
        SUM(trim(sub_category) LIKE '%  %'),
        SUM(sub_category LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'product_name',
        SUM(product_name IS NULL), 
        SUM(trim(product_name) = ''), 
        SUM(trim(product_name) LIKE '%  %'),
        SUM(product_name LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'sales',
        SUM(sales IS NULL), 
        SUM(trim(sales) = ''), 
        SUM(trim(sales) LIKE '%  %'),
        SUM(sales LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'quantity',
        SUM(quantity IS NULL), 
        SUM(trim(quantity) = ''), 
        SUM(trim(quantity) LIKE '%  %'),
        SUM(quantity LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'discount',
        SUM(discount IS NULL), 
        SUM(trim(discount) = ''), 
        SUM(trim(discount) LIKE '%  %'),
        SUM(discount LIKE '%--%')
    FROM clean_superstore_orders
    UNION ALL
    SELECT 
        'profit',
        SUM(profit IS NULL), 
        SUM(trim(profit) = ''), 
        SUM(trim(profit) LIKE '%  %'),
        SUM(profit LIKE '%--%')
    FROM clean_superstore_orders)
SELECT * FROM cek_issues
ORDER BY issue_null DESC, issue_blank DESC, issue_spaces DESC, issue_null DESC;



---| 16. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : SPACES
---  attribute : product_name
---  solution : replace spaces to a space
INSERT INTO audit_log 
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'product_name', 
    'SPACES', 
    'replace spaces to a space',
    'clean_superstore_orders', 
    (SELECT count(row_id) FROM clean_superstore_orders)   
FROM clean_superstore_orders
GROUP BY row_id
HAVING product_name LIKE '%  %'
ORDER BY row_id;



---| UPDATE DATA PROBLEMATIC (NULL, blank '', double space, strips)
---- tabel clean data
UPDATE clean_superstore_orders
SET product_name = 
    CASE WHEN product_name LIKE '%  %' THEN REPLACE(product_name, '  ', ' ')
    ELSE product_name END;



---/ CEK DATA PROBLEMATIC (duplikat based on all rows, kecuali row_id) 
---- tabel data clean

---| Menghitung row duplikat (ada duplikat → total rows ≠ unique rows)
WITH 
    unique_records AS (
        SELECT * FROM clean_superstore_orders
        GROUP BY 
            order_id, order_date, ship_date, ship_mode, customer_id, country, state, city, postal_code, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit),
    count_unique_records AS (
        SELECT COUNT(*) AS rows_unique 
        FROM unique_records),
    count_all_records AS (
        SELECT COUNT(*) AS rows_total 
        FROM clean_superstore_orders)
SELECT 
    rows_total, 
    rows_unique, 
    (rows_total - rows_unique) AS "total rows duplicate"   
FROM count_unique_records, count_all_records;



---| Menampilkan row_id data yang duplikat (based on all rows, kecuali row_id)
WITH group_data_duplicate AS (
    SELECT 
        group_concat(row_id) AS rows_duplicate, 
        count(row_id) AS total_duplicate,
        clean_superstore_orders.*
    FROM clean_superstore_orders
    GROUP BY 
        order_id, order_date, ship_date, ship_mode, customer_id, country, state, city, postal_code, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit
    HAVING total_duplicate > 1)
SELECT 
    c.row_id,
    d.total_duplicate, 
    d.rows_duplicate
FROM group_data_duplicate d
JOIN clean_superstore_orders c
ON
    d.order_id = c.order_id AND
    d.order_date = c.order_date AND
    d.ship_date = c.ship_date AND
    d.ship_mode = c.ship_mode AND
    d.customer_id = c.customer_id AND
    d.country = c.country AND
    d.state = c.state AND
    d.city = c.city AND
    d.postal_code = c.postal_code AND
    d.region = c.region AND
    d.product_id = c.product_id AND
    d.category = c.category AND
    d.sub_category = c.sub_category AND
    d.product_name = c.product_name AND
    d.sales = c.sales AND
    d.quantity = c.quantity AND
    d.discount = c.discount AND
    d.profit = c.profit
GROUP BY d.rows_duplicate
ORDER BY c.row_id ASC;


---/ Problem data yang terdeteksi:
-- 1. Ada 32 rows data yang duplikat


---/ INPUT KE LOG TABLE
---| 5. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : DUPLICATE DATA
---  attribute : ALL
---  solution : remove duplicate data
WITH group_unique_records AS (
    SELECT * FROM clean_superstore_orders
    GROUP BY 
        order_id, order_date, ship_date, ship_mode, customer_id, country, state, city, postal_code, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit)
INSERT INTO audit_log 
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 'ALL', 'DUPLICATE DATA', 'remove duplicate data', 'clean_superstore_orders', (SELECT count(row_id) FROM clean_superstore_orders)   
FROM clean_superstore_orders
GROUP BY row_id
HAVING row_id NOT IN (
    SELECT row_id FROM group_unique_records);



---| UPDATE DATA PROBLEMATIC (remove duplicate data)
---- tabel data clean
WITH 
    unique_records AS (
        SELECT * FROM clean_superstore_orders
        GROUP BY 
            order_id, order_date, ship_date, ship_mode, customer_id, country, state, city, postal_code, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit)
DELETE FROM clean_superstore_orders
WHERE row_id NOT IN (
    SELECT row_id FROM unique_records);



---/ DATA FORMATTING PER KOLOM
---- FOKUS: cek dan fixing data per kolom agar tidak ada perbedaan format data (
---- misal:
---- 1. data order_id punya ukuran fix 16 karakter
---- 2. data category ada broken name (Tech, technologies, Furni, OfficeSupply)
---- 2. etc



----------------------------------------------------------------------------------------------
-------------------------------------- row_id ------------------------------------------------
----------------------------------------------------------------------------------------------
-- cek jumlah total dan selisih row_id berdasarkan length(row_id)
WITH RECURSIVE 
    full_numbers AS (
        SELECT 1 AS nomor UNION ALL     
        SELECT nomor + 1     
        FROM full_numbers 
        WHERE nomor <= ( SELECT (max(row_id) -1) FROM clean_superstore_orders) ),
    numbers AS (
        SELECT DISTINCT 
            (length(nomor)) AS LEN_nomor,
            count(nomor) AS jumlah_nomor
        FROM full_numbers
        GROUP BY LEN_nomor ),
    row_id_table AS (
        SELECT DISTINCT 
            (length(row_id)) AS LEN_db,
            count(row_id) AS jumlah_db
        FROM clean_superstore_orders
        GROUP BY LEN_db )
SELECT 
    LEN_nomor AS LEN, 
    jumlah_nomor, 
    jumlah_db, 
    (jumlah_nomor - jumlah_db) AS selisih, 
    (SELECT sum(jumlah_nomor)     FROM numbers ) AS total_nomor, 
    (SELECT sum(jumlah_db)     FROM row_id_table ) AS total_db, 
    ( (SELECT sum(jumlah_nomor) FROM numbers) - (SELECT sum(jumlah_db) FROM row_id_table) ) AS total_selisih
FROM numbers 
JOIN row_id_table 
ON LEN_nomor = LEN_db;



-- Cek uniqueness of row_id dan cek row_id yang hilang dan kenapa?
WITH RECURSIVE 
    full_numbers AS (
        SELECT 1 AS nomor UNION ALL
        SELECT nomor + 1
        FROM full_numbers 
        WHERE nomor <= ( SELECT (max(row_id) -1) FROM clean_superstore_orders) ),
    deleted_row_id AS (
        SELECT nomor, row_id
        FROM full_numbers
        FULL OUTER JOIN clean_superstore_orders 
        ON nomor = row_id
        WHERE nomor IS NULL OR row_id IS NULL)
SELECT 
    d.nomor, 
    d.row_id, 
    a.reason
FROM deleted_row_id d
JOIN audit_log a 
ON d.nomor = a.row_id
GROUP BY d.nomor;



----------------------------------------------------------------------------------------------
-------------------------------------- order_id ----------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT order_id FROM clean_superstore_orders;

-- cek jumlah total dan selisih order_id berdasarkan length(order_id)
WITH
    CEK_order_id AS (
        SELECT
            length('XX-NNNN-MMMMMM') AS LEN_real,
            length(order_id) AS LEN_order_id,
            count(order_id) AS jumlah
        FROM clean_superstore_orders
        GROUP BY LEN_order_id)
SELECT * FROM CEK_order_id;

-- cek konsistensi format order_id per huruf/kata
SELECT DISTINCT substr(order_id, 1, 2) AS country_code
FROM clean_superstore_orders; --cek kode negara
SELECT DISTINCT substr(order_id, 3, 1) AS strips1
FROM clean_superstore_orders; --cek strip pemisah 1
SELECT DISTINCT substr(order_id, 4, 4) AS year_code
FROM clean_superstore_orders; --cek kode tahun
SELECT DISTINCT substr(order_id, 8, 1) AS strips2
FROM clean_superstore_orders; --cek strip pemisah 2
SELECT DISTINCT substr(order_id, 9, 6) AS number_code
FROM clean_superstore_orders; --cek kode nomor



----------------------------------------------------------------------------------------------
-------------------------------------- order_date --------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT order_date FROM clean_superstore_orders;

-- cek jumlah total dan selisih order_date berdasarkan length(order_date)
WITH
    CEK_order_date AS (
        SELECT
            length('YYYY-MM-DD') AS LEN_real,
            length(order_date) AS LEN_order_date,
            count(order_date) AS jumlah
        FROM clean_superstore_orders
        GROUP BY
            LEN_order_date
    )
SELECT *
FROM CEK_order_date;

-- cek konsistensi format order_date per huruf/kata
SELECT DISTINCT substr(order_date, 1, 4) AS year_code
FROM clean_superstore_orders
ORDER BY year_code; --cek kode tahun
SELECT DISTINCT substr(order_date, 5, 1) AS strips1
FROM clean_superstore_orders; --cek strip pemisah 1
SELECT DISTINCT substr(order_date, 6, 2) AS month_code
FROM clean_superstore_orders
ORDER BY month_code; --cek kode bulan
SELECT DISTINCT substr(order_date, 8, 1) AS strips2
FROM clean_superstore_orders; --cek strip pemisah 2
SELECT DISTINCT substr(order_date, 9, 2) AS day_code
FROM clean_superstore_orders
ORDER BY day_code; --cek kode hari

----------------------------------------------------------------------------------------------
-------------------------------------- ship_date ---------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT ship_date FROM clean_superstore_orders; 

-- cek jumlah total dan selisih ship_date berdasarkan length(ship_date)
WITH
    CEK_ship_date AS (
        SELECT
            length('YYYY-MM-DD') AS LEN_real,
            length(ship_date) AS LEN_ship_date,
            count(ship_date) AS jumlah
        FROM clean_superstore_orders
        GROUP BY LEN_ship_date )
SELECT * FROM CEK_ship_date;

-- cek konsistensi format ship_date per huruf/kata
SELECT DISTINCT substr(ship_date, 1, 4) AS year_code
FROM clean_superstore_orders
ORDER BY year_code; --cek kode tahun
SELECT DISTINCT substr(ship_date, 5, 1) AS strips1
FROM clean_superstore_orders; --cek strip pemisah 1
SELECT DISTINCT substr(ship_date, 6, 2) AS month_code
FROM clean_superstore_orders
ORDER BY month_code; --cek kode bulan
SELECT DISTINCT substr(ship_date, 8, 1) AS strips2
FROM clean_superstore_orders; --cek strip pemisah 2
SELECT DISTINCT substr(ship_date, 9, 2) AS day_code
FROM clean_superstore_orders
ORDER BY day_code; --cek kode hari

----------------------------------------------------------------------------------------------
-------------------------------------- ship_mode ---------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT ship_mode FROM clean_superstore_orders; 

-- cek jumlah total dan selisih ship_mode berdasarkan length(ship_mode)
WITH
    Cek_ship_mode AS (
        SELECT DISTINCT
            ship_mode,
            length(ship_mode) AS LEN_db
        FROM clean_superstore_orders ),
    Cek_LEN_ship_mode AS (
        SELECT 'Same Day' AS ship_mode, length('Same Day') AS LEN_real UNION ALL
        SELECT 'First Class', length('First Class') UNION ALL
        SELECT 'Second Class', length('Second Class') UNION ALL
        SELECT 'Standard Class', length('Standard Class') )
SELECT a.ship_mode, a.LEN_db, b.LEN_real
FROM Cek_ship_mode a
JOIN Cek_LEN_ship_mode b 
ON a.ship_mode = b.ship_mode;

----------------------------------------------------------------------------------------------
-------------------------------------- customer_id -------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT customer_id FROM clean_superstore_orders; 

-- cek jumlah total dan selisih customer_id berdasarkan length(customer_id)
WITH
    CEK_customer_id AS (
        SELECT
            length('XX-NNNNN') AS LEN_real,
            length(customer_id) AS LEN_customer_id,
            count(customer_id) AS jumlah
        FROM clean_superstore_orders
        GROUP BY LEN_customer_id )
SELECT * FROM CEK_customer_id;

-- cek konsistensi format customer_id per huruf/kata
SELECT DISTINCT substr(customer_id, 1, 2) AS name_code
FROM clean_superstore_orders; --cek kode nama
SELECT DISTINCT substr(customer_id, 3, 1) AS strips1
FROM clean_superstore_orders; --cek strip pemisah 1
SELECT DISTINCT substr(customer_id, 4, 5) AS number_code
FROM clean_superstore_orders; --cek kode nomor



----------------------------------------------------------------------------------------------
-------------------------------------- product_id --------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT product_id FROM clean_superstore_orders;

-- cek jumlah total dan selisih product_id berdasarkan length(product_id)
WITH
    CEK_product_id AS (
        SELECT
            length('XXX-XX-MMMMMMMM') AS LEN_real,
            length(product_id) AS LEN_product_id,
            count(product_id) AS jumlah
        FROM clean_superstore_orders
        GROUP BY LEN_product_id )
SELECT * FROM CEK_product_id;


-- cek konsistensi format product_id per huruf/kata
SELECT DISTINCT substr(product_id, 1, 3) AS categoty_code
FROM clean_superstore_orders; --cek kode kategori
SELECT DISTINCT substr(product_id, 4, 1) AS strips1
FROM clean_superstore_orders; --cek strip pemisah 1
SELECT DISTINCT substr(product_id, 5, 2) AS sub_categoty_code
FROM clean_superstore_orders; --cek kode sub-kategori
SELECT DISTINCT substr(product_id, 7, 1) AS strips2
FROM clean_superstore_orders; --cek strip pemisah 2
SELECT DISTINCT substr(product_id, 8, 8) AS number_code
FROM clean_superstore_orders; --cek kode nomor



----------------------------------------------------------------------------------------------
-------------------------------------- category ----------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT category FROM clean_superstore_orders;


---/ Problem data yang terdeteksi:
-- 1. INCONSISTENT NAME → Tech dan technologies
--    SOLUTION          → replace as one category (Technology)?

-- 2. BROKEN NAME       → Tech, technologies, Furni, OfficeSupply
--    SOLUTION          → rename to Technology, Furniture, Office Supplies


-- Cek similiarity kategori Tech dan technologies untuk memutuskan apakah bisa dilebur mejadi 1 kategori (as Technology) atau tidak?
-- Menghitung data unique-nya dan berapa yang sama (based on product_id, sub_category, product_name)
WITH
    duplikat_product_id AS (
        SELECT count(DISTINCT product_id) AS product_id_sama
        FROM clean_superstore_orders
        WHERE category = 'technologies' AND product_id IN (
            SELECT product_id FROM clean_superstore_orders
            WHERE category = 'Tech') ),
    duplikat_sub_category AS (
        SELECT count(DISTINCT sub_category) AS sub_category_sama
        FROM clean_superstore_orders
        WHERE category = 'technologies' AND sub_category IN (
            SELECT sub_category FROM clean_superstore_orders
            WHERE category = 'Tech') ),
    duplikat_product_name AS (
        SELECT count(DISTINCT product_name) AS product_name_sama
        FROM clean_superstore_orders
        WHERE category = 'technologies' AND product_name IN (
            SELECT product_name FROM clean_superstore_orders
            WHERE category = 'Tech') )
SELECT -- menghitung total data unique gabungan kategori Tech dan technologies
    'Total unique' AS problem,
    count(DISTINCT product_id) AS total_product_id,
    count(DISTINCT sub_category) AS total_sub_category,
    count(DISTINCT product_name) AS total_product_name
FROM clean_superstore_orders
WHERE category IN ('Tech', 'technologies')
UNION ALL
SELECT -- menghitung data duplikat (ada di Tech + technologies sekaligus)
    'Data duplicates' AS problem,
    product_id_sama,
    sub_category_sama,
    product_name_sama
FROM duplikat_product_id, duplikat_sub_category, duplikat_product_name;



-- Menampilkan data duplikat (ada di Tech + technologies sekaligus)
-- based on product_id, sub_category, product_name
WITH
    Cek_Tech AS (
        SELECT category, product_id, sub_category, product_name
        FROM clean_superstore_orders
        WHERE category = 'Tech'),
    Cek_technologies AS (
        SELECT category, product_id, sub_category, product_name
        FROM clean_superstore_orders
        WHERE category = 'technologies')
SELECT DISTINCT
    A.product_id AS Tech_ID,
    B.product_id AS technologies_ID,
    A.sub_category AS Tech_SubCat,
    B.sub_category AS technologies_SubCat,
    A.product_name AS Tech_Name,
    B.product_name AS technologies_Name
FROM Cek_Tech AS A
JOIN Cek_technologies AS B
ON
    A.product_id = B.product_id AND 
    A.sub_category = B.sub_category AND 
    A.product_name = B.product_name;


---/ Hasil pengecekan problem data yang terdeteksi:
---  Kategori Tech dan technologies bisa dilebur jadi 1 kategori


---/ INPUT KE LOG TABLE
---| 6. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : INCONSISTENT NAME (Tech dan technologies = Technology)
---  attribute : category
---  solution : replace as one (Technology)
INSERT INTO audit_log 
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'category', 
    'INCONSISTENT NAME (Tech dan technologies = Technology)', 
    'replace as one (Technology)',
    'clean_superstore_orders', 
    (SELECT count(row_id) FROM clean_superstore_orders)   
FROM clean_superstore_orders
GROUP BY row_id
HAVING category IN ('Tech', 'technologies')
ORDER BY row_id;



---| 7. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : BROKEN NAME (Tech = Technology)
---  attribute : category 
---  solution : rename to Technology
INSERT INTO audit_log
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT
    row_id,
    'category',
    'BROKEN NAME (Tech = Technology)',
    'rename to Technology',
    'clean_superstore_orders',
    (SELECT count(row_id) FROM clean_superstore_orders)
FROM clean_superstore_orders
GROUP BY row_id
HAVING category = 'Tech'
ORDER BY row_id;



---| 8. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : BROKEN NAME (technologies = Technology)
---  attribute : category 
---  solution : rename to Technology
INSERT INTO audit_log
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT
    row_id,
    'category',
    'BROKEN NAME (technologies = Technology)',
    'rename to Technology',
    'clean_superstore_orders',
    (SELECT 
    count(row_id) FROM clean_superstore_orders)
FROM clean_superstore_orders
GROUP BY row_id
HAVING category = 'technologies'
ORDER BY row_id;



---| 9. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : BROKEN NAME (Furni = Furniture)
---  attribute : category 
---  solution : rename to Furniture
INSERT INTO audit_log
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT
    row_id,
    'category',
    'BROKEN NAME (Furni = Furniture)',
    'rename to Furniture',
    'clean_superstore_orders',
    (SELECT count(row_id) FROM clean_superstore_orders)
FROM clean_superstore_orders
GROUP BY row_id
HAVING category = 'Furni'
ORDER BY row_id;



---| 10. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : BROKEN NAME (OfficeSupply = Office Supplies)
---  attribute : category 
---  solution : rename to Office Supplies
INSERT INTO audit_log
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT
    row_id,
    'category',
    'BROKEN NAME (OfficeSupply = Office Supplies)',
    'rename to Office Supplies',
    'clean_superstore_orders',
    (SELECT count(row_id) FROM clean_superstore_orders)
FROM clean_superstore_orders
GROUP BY row_id
HAVING category = 'OfficeSupply'
ORDER BY row_id;



---| UPDATE DATA PROBLEMATIC (BROKEN NAME: Tech, technologies, Furni, OfficeSupply)
---- tabel data clean Technology, Furniture, Office Supplies
UPDATE clean_superstore_orders
SET
    category = CASE 
        WHEN category = 'Tech' THEN 'Technology'
        WHEN category = 'technologies' THEN 'Technology'
        WHEN category = 'Furni' THEN 'Furniture'
        WHEN category = 'OfficeSupply' THEN 'Office Supplies'   
        ELSE category END;



-- cek jumlah total dan selisih category berdasarkan length(category)
WITH
    Cek_category AS (
        SELECT DISTINCT
            category,
            length(category) AS LEN_db,
            count(*) AS jumlah_data
        FROM clean_superstore_orders
        GROUP BY category),
    Cek_LEN_db AS (
        SELECT 'Technology' AS category, length('Technology') AS LEN_real UNION ALL
        SELECT 'Furniture', length('Furniture') UNION ALL
        SELECT 'Office Supplies', length('Office Supplies') )
SELECT 
    a.category, 
    a.LEN_db, 
    b.LEN_real,
    a.jumlah_data,
    (SELECT count(*) FROM clean_superstore_orders) AS total_db
FROM Cek_category a
JOIN Cek_LEN_db b 
ON a.category = b.category;



----------------------------------------------------------------------------------------------
-------------------------------------- sub_category ------------------------------------------
----------------------------------------------------------------------------------------------
SELECT DISTINCT category, sub_category FROM clean_superstore_orders
ORDER BY category, sub_category;

-- cek kemunculan sub_category di masing-masing category
-- cek status jumlah karakter LEN normal vs LEN trim
SELECT 
    category, sub_category, 
    (SELECT CASE
        WHEN count(DISTINCT category) = 1 THEN 'OK'
        ELSE 'duplicate' END) AS status_category_duplicate,
    (SELECT CASE 
        WHEN length(sub_category) <> length(trim(sub_category)) THEN 'Problem'
        ELSE 'OK' END) AS status_LEN_db_real
FROM clean_superstore_orders
GROUP BY sub_category
ORDER BY category, sub_category;



----------------------------------------------------------------------------------------------
-------------------------------------- discount ----------------------------------------------
----------------------------------------------------------------------------------------------

-- cari unique discount
SELECT DISTINCT discount FROM clean_superstore_orders ORDER BY discount;


---/ Problem data yang terdeteksi:
-- 1. Ada discount BLANK
--    SOLUTION → flag origin discount "YES / NO" and change BLANK to 0 


---/ cek significancy data blank. kalau >= 5% dari total data, tidak boleh di-remove
-- harusnya pake clause WHERE discount = 'BLANK', tapi karena udah terlanjut diganti jadi 0 jadinya pake clause WHERE = 'NO' aja. Sama aja hasilnya.
WITH    
    count_blank AS (
        SELECT count(discount_flag) AS blank 
        FROM clean_superstore_orders
        WHERE discount_flag = 'NO'),
    count_total AS (
        SELECT count(discount_flag) AS total 
        FROM clean_superstore_orders)
SELECT 
    cb.blank,
    ct.total,
   round(100.0*cb.blank/ct.total, 2) AS total_percent
FROM count_blank cb, count_total ct;


---/ Hasil pengecekan problem data yang terdeteksi:
---  discount yang BLANK merupakan 7.01% dari total data.
---  Sehingga untuk data discount BLANK tidak dihapus



---/ INPUT KE LOG TABLE
---| 11. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : BLANK
---  attribute : discount
---  solution : flag origin discount "YES / NO" and change BLANK to 0 
INSERT INTO audit_log 
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'discount', 
    'BLANK', 
    'flag origin discount "YES / NO" and change BLANK to 0',
    'clean_superstore_orders', 
    (SELECT count(row_id) FROM clean_superstore_orders)   
FROM clean_superstore_orders
GROUP BY row_id
HAVING discount = 'BLANK'
ORDER BY row_id;



---| ADD COLUMN discount_flag (untuk originality discount flag YES / NO)
-- data discount = 'BLANK' akan diganti menjadi 0
-- YES/NO akan membedakan discount 0 (dari datasets) vs 0 (dari hasil turning BLANK ke 0)
-- originality discount flag YES = discount not BLANK (discount 0 - 0.8 from datasets)
-- originality discount flag NO = discount 'BLANK' yang diubah menjadi 0
ALTER Table clean_superstore_orders ADD COLUMN discount_flag TEXT;


---| UPDATE DATA PROBLEMATIC (BLANK)
-- tabel data clean

-- UPDATE originality discount_flag
UPDATE clean_superstore_orders
SET discount_flag = 
    CASE 
        WHEN discount = 'BLANK' THEN 'NO' 
        ELSE 'YES' END;

-- UPDATE discount BLANK to 0
UPDATE clean_superstore_orders
SET discount = 0
WHERE discount = 'BLANK';



----------------------------------------------------------------------------------------------
---------------------------------------- sales -----------------------------------------------
----------------------------------------------------------------------------------------------

-- cek apakah semua value di sales merupakan real number?
SELECT 
    sales,
    (CASE 
        WHEN sales <> (1.0 * sales) THEN 'Not Real' 
        ELSE 'Real'
    END) AS status_data
FROM clean_superstore_orders
ORDER BY status_data;



-- cek kemungkinan sales yang ada (-), ($), (.), (,)
WITH cek_sales AS (
    SELECT 
        count(sales) AS total_data_db,
        (sum(CASE WHEN sales LIKE '%-%' THEN 1 ELSE 0 END)) AS strips,
        (sum(CASE WHEN sales LIKE '%$%' THEN 1 ELSE 0 END)) AS dollars,
        (sum(CASE WHEN sales LIKE '%,%' THEN 1 ELSE 0 END)) AS commas,
        (sum(CASE WHEN sales LIKE '%.%' THEN 1 ELSE 0 END)) AS titik,
        (sum(CASE WHEN sales NOT LIKE '%.%' OR '%-%' OR '%,%' OR '%$%' THEN 1 ELSE 0 END)) AS full_integer
    FROM clean_superstore_orders)
SELECT cek_sales.*, titik + full_integer AS "total titik and full_integer"
FROM cek_sales;



-- cek sales yang full bilangan bulat tanpa (-), ($), (.), (,)
SELECT DISTINCT sales FROM clean_superstore_orders 
WHERE sales NOT LIKE '%.%' OR '%-%' OR '%,%' OR '%$%'
ORDER BY sales;



-- cek jumlah, min, max, rata-rata berdasarkan kategori - sub-kategori
SELECT 
    category, sub_category,
    round(sum(sales), 2) AS sum_sales,
    min(sales) AS min_sales,
    max(sales) AS max_sales,
    round(avg(sales), 2) AS avg_sales
FROM clean_superstore_orders
GROUP BY category, sub_category;

----------------------------------------------------------------------------------------------
---------------------------------------- quantity --------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT quantity FROM clean_superstore_orders ORDER BY quantity;


-- cek jumlah, min, max, rata-rata berdasarkan kategori - sub-kategori
SELECT DISTINCT 
    category, 
    sub_category, 
    min(quantity) AS min_quantity,
    max(quantity) AS max_quantity,
    sum(quantity) AS total_quantity,
    round(avg(quantity), 0) AS avg_quantity
FROM clean_superstore_orders
GROUP BY category, sub_category;


----------------------------------------------------------------------------------------------
---------------------------------------- profit ----------------------------------------------
----------------------------------------------------------------------------------------------

-- cek apakah semua value di profit merupakan real number?
SELECT 
    profit,
    (CASE 
        WHEN profit <> (1.0 * profit) THEN 'Not Real' 
        ELSE 'Real'
    END) AS status_data
FROM clean_superstore_orders
ORDER BY status_data;



-- cek kemungkinan profit yang ada (-), ($), (.), (,)
WITH cek_profit AS (
    SELECT 
        count(profit) AS total_data_db,
        (sum(CASE WHEN profit LIKE '%-%' THEN 1 ELSE 0 END)) AS strips,
        (sum(CASE WHEN profit LIKE '%$%' THEN 1 ELSE 0 END)) AS dollars,
        (sum(CASE WHEN profit LIKE '%,%' THEN 1 ELSE 0 END)) AS commas,
        (sum(CASE WHEN profit LIKE '%.%' THEN 1 ELSE 0 END)) AS titik,
        (sum(CASE WHEN profit NOT LIKE '%.%' OR '%-%' OR '%,%' OR '%$%' THEN 1 ELSE 0 END)) AS full_integer
    FROM clean_superstore_orders)
SELECT cek_profit.*, titik + full_integer AS "total titik and full_integer"
FROM cek_profit;



-- cek profit < 0 ==> profit yang ada strips
SELECT profit FROM clean_superstore_orders
WHERE profit < 0;

-- hasil pengecekan
-- data strips = data yang profit < 0 (minus sign)


-- cek profit yang full bilangan bulat tanpa (-), ($), (.), (,)
SELECT DISTINCT profit FROM clean_superstore_orders 
WHERE profit NOT LIKE '%.%' OR '%-%' OR '%,%' OR '%$%'
ORDER BY profit;

-- hasil pengecekan
-- semua profit yang bilangan bulat

-- cek jumlah, min, max, rata-rata berdasarkan kategori - sub-kategori
SELECT 
    category, 
    sub_category, 
    round(sum(profit), 2) AS sum_profit,
    min(profit) AS min_profit,
    max(profit) AS max_profit,
    round(avg(profit), 2) AS avg_profit
FROM clean_superstore_orders
GROUP BY category, sub_category;



----------------------------------------------------------------------------------------------
-------------------------------------- country -----------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT country FROM clean_superstore_orders;

-- cek jumlah total dan selisih country berdasarkan length(country)
SELECT DISTINCT
    country,
    length('United States') AS LEN_country_real,
    length(country) AS LEN_country,
    count(*) AS total_db
FROM clean_superstore_orders
GROUP BY country;



----------------------------------------------------------------------------------------------
---------------------------------------- state -----------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT state FROM clean_superstore_orders ORDER BY state;

-- bandingin state db vs state source external
-- kriteria: nama dan LEN state database harus sama dengan data external. selain itu problem.
-- DB_state NULL = state ada di source external, tapi tidak ada di database (it's okay)
-- Tidak semua state di source external harus ada di database
-- Semua state di database harus ada di source external


-- compare state database (db) dengan data state real
-- cek state berdasarkan length(state)
WITH states_real(state) AS (
    VALUES -- from wikipedia 30 Nov 2025
        ('Alabama'), ('Alaska'), ('Arizona'), ('Arkansas'), ('California'), ('Colorado'), ('Connecticut'), ('Delaware'), ('Florida'), ('Georgia'), ('Hawaii'), ('Idaho'), ('Illinois'), ('Indiana'), ('Iowa'), ('Kansas'), ('Kentucky'), ('Louisiana'), ('Maine'), ('Maryland'), ('Massachusetts'), ('Michigan'), ('Minnesota'), ('Mississippi'), ('Missouri'), ('Montana'), ('Nebraska'), ('Nevada'), ('New Hampshire'), ('New Jersey'), ('New Mexico'), ('New York'), ('North Carolina'), ('North Dakota'), ('Ohio'), ('Oklahoma'), ('Oregon'), ('Pennsylvania'), ('Rhode Island'), ('South Carolina'), ('South Dakota'), ('Tennessee'), ('Texas'), ('Utah'), ('Vermont'), ('Virginia'), ('Washington'), ('West Virginia'), ('Wisconsin'), ('Wyoming'), ('District of Columbia') )
SELECT 
    s.state AS state_real, 
    c.state AS state_db,
    (SELECT CASE 
        WHEN s.state = c.state THEN 'OK'
        ELSE 'Problem' END) AS status_name,
    (SELECT CASE 
        WHEN length(s.state) = length(c.state) THEN 'OK'
        ELSE 'Problem' END) AS status_len,
    (SELECT CASE 
        WHEN length(c.state) IS NOT NULL THEN 'OK'
        ELSE 'state is not in the database' END) AS availability_state
FROM states_real s
FULL OUTER JOIN clean_superstore_orders c
ON c.state = s.state
GROUP BY s.state
ORDER BY status_name DESC, status_len DESC, availability_state DESC, state_real ASC;



-- compare state database (db) dengan data state real
-- cek state berdasarkan length(state)
with cek_state AS(
    SELECT DISTINCT
        ex.state AS external_state, 
        db.state AS DB_state, 
        length(db.state) AS LEN_db,
        length(ex.state) AS LEN_external
    FROM clean_superstore_orders db
    FULL OUTER JOIN external_state_city ex
    ON db.state = ex.state)
SELECT 
    (SELECT CASE 
        WHEN DB_state = external_state AND LEN_db = LEN_external THEN 'OK'
        ELSE 'Problem' END) AS status_data,
    cek_state.*
FROM cek_state
WHERE status_data <> 'OK' AND DB_state IS NOT NULL;



---/ Problem data yang terdeteksi:
-- 1. Ada state yang tidak ada di source external 
--    state problematic : District of Columbia
--    SOLUTION → cek manual LEN


-- cek LEN state manual
SELECT DISTINCT 
    state, 
    length(state) AS LEN_db,
    length('District of Columbia') AS LEN_DoC
FROM clean_superstore_orders
WHERE state IN ('District of Columbia');


---/ Hasil pengecekan problem data yang terdeteksi:
---  Secara LEN, penulisan state sudah benar. Bukan problem lagi.



----------------------------------------------------------------------------------------------
----------------------------------------- city -----------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT city FROM clean_superstore_orders ORDER BY city;

-- bandingin city db vs city source external
-- kriteria: nama dan LEN city database harus sama dengan data external. selain itu problem.
-- DB_city NULL = city ada di source external, tapi tidak ada di database (it's okay)
-- Tidak semua city di source external harus ada di database
-- Semua city di database harus ada di source external
WITH cek_city AS(
    SELECT DISTINCT
        ex.city AS external_city, 
        db.city AS DB_city, 
        length(db.city) AS LEN_db,
        length(ex.city) AS LEN_external
    FROM clean_superstore_orders db
    FULL OUTER JOIN external_state_city ex
    ON db.city = ex.city)
SELECT 
    (SELECT CASE 
        WHEN DB_city = external_city AND LEN_db = LEN_external THEN 'OK'
        ELSE 'Problem' END) AS status_data,
    cek_city.*
FROM cek_city
WHERE status_data <> 'OK' AND DB_city IS NOT NULL;



-- cek manual city yang tidak ada di external source berdasarkan trim dan replace spaces
WITH cek_city AS(
    SELECT DISTINCT
        ex.city AS external_city, 
        db.city AS DB_city, 
        length(db.city) AS LEN_db,
        length(ex.city) AS LEN_external
    FROM clean_superstore_orders db
    FULL OUTER JOIN external_state_city ex
    ON db.city = ex.city
    WHERE 
        DB_city <> external_city AND 
        LEN_db <> LEN_external AND 
        DB_city IS NOT NULL)
SELECT
    DB_city,
    length(DB_city) AS LEN_db,
    length(trim(DB_city)) AS LEN_trim,
    length(REPLACE(DB_city, '  ', ' ')) AS LEN_replace
FROM cek_city
WHERE
    LEN_db <> LEN_trim OR
    LEN_db <> LEN_replace;



-- cek jumlah total dan selisih city berdasarkan length(city)
SELECT DISTINCT
    city,
    length(trim(replace(city, '  ', ' '))) AS LEN_real,
    length(city) AS LEN_db,
    (SELECT CASE 
        WHEN length(city) <> length(trim(replace(city, '  ', ' '))) THEN 'Problem'
        ELSE 'OK' END) AS status_LEN,
    count(city) AS total_data_db
FROM clean_superstore_orders
GROUP BY city
ORDER BY status_LEN DESC, city;



----------------------------------------------------------------------------------------------
----------------------------------------- postal_code ----------------------------------------
----------------------------------------------------------------------------------------------


SELECT DISTINCT postal_code FROM clean_superstore_orders;

-- cek jumlah total dan selisih postal_code berdasarkan length(postal_code)
WITH
    CEK_postal_code AS (
        SELECT
            length('NNNNN') AS LEN_real,
            length(postal_code) AS LEN_postal_code,
            count(postal_code) AS jumlah
        FROM clean_superstore_orders
        GROUP BY LEN_postal_code)
SELECT * FROM CEK_postal_code;

-- cek konsistensi format postal_code per digit
SELECT DISTINCT substr(postal_code, 1, 1) AS no_1
FROM clean_superstore_orders ORDER BY no_1; --cek digit 1
SELECT DISTINCT substr(postal_code, 2, 1) AS no_2
FROM clean_superstore_orders ORDER BY no_2; --cek digit 2
SELECT DISTINCT substr(postal_code, 3, 1) AS no_3
FROM clean_superstore_orders ORDER BY no_3; --cek digit 3
SELECT DISTINCT substr(postal_code, 4, 1) AS no_4
FROM clean_superstore_orders ORDER BY no_4; --cek digit 4
SELECT DISTINCT substr(postal_code, 5, 1) AS no_5
FROM clean_superstore_orders ORDER BY no_5; --cek digit 5



----------------------------------------------------------------------------------------------
------------------------------------------- region -------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT region FROM clean_superstore_orders;


---/ Problem data yang terdeteksi:
-- 1. Unknown   → region
--    SOLUTION  → UPDATE ke region valid (South, West, Central, East)


---/ INPUT KE LOG TABLE
---| 12. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : REGION Unknown
---  attribute : region
---  solution : UPDATE ke region valid (South, West, Central, East)
INSERT INTO audit_log 
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'region', 
    'REGION Unknown', 
    'UPDATE ke region valid (South, West, Central, East)',
    'clean_superstore_orders', 
    (SELECT count(row_id) FROM clean_superstore_orders)   
FROM clean_superstore_orders
GROUP BY row_id
HAVING region = 'Unknown'
ORDER BY row_id;



---- CEK DATA SEBELUM/SESUDAH UPDATE DATA INVALID 'Unknown'
WITH 
    valid_region AS (
        SELECT 
            postal_code AS valid_postal_code,
            count(postal_code) AS jumlah_valid
        FROM clean_superstore_orders
        WHERE region <> 'Unknown'
        GROUP BY postal_code),
    unkown_region AS (
        SELECT 
            postal_code AS invalid_postal_code,
            count(postal_code) AS Jumlah_Invalid
        FROM clean_superstore_orders
        WHERE region = 'Unknown'
        GROUP BY postal_code)
SELECT
    valid_postal_code,
    coalesce(jumlah_valid, 0) AS jumlah_valid,
    coalesce(Jumlah_Invalid, 0) AS Jumlah_Invalid,
    coalesce(jumlah_valid, 0) + coalesce(Jumlah_Invalid, 0) AS Total_Data
FROM valid_region
FULL OUTER JOIN unkown_region
ON valid_postal_code = invalid_postal_code
GROUP BY valid_postal_code
ORDER BY valid_postal_code ASC;



---| UPDATE DATA PROBLEMATIC (REGION Unknown to South, West, Central, East)
---- tabel data clean region
WITH valid_region AS (
    SELECT DISTINCT 
        state, postal_code, region
    FROM clean_superstore_orders
    WHERE region <> 'Unknown')
UPDATE clean_superstore_orders AS cso
SET region = (
    SELECT vr.region FROM valid_region AS vr
    WHERE 
        cso.postal_code = vr.postal_code AND 
        cso.state = vr.state)
WHERE cso.region = 'Unknown';



----------------------------------------------------------------------------------------------
------------------------------------ product_name --------------------------------------------
----------------------------------------------------------------------------------------------

SELECT DISTINCT product_name FROM clean_superstore_orders;

-- membuat VIEW untuk details product name per kata
CREATE VIEW IF NOT EXISTS v_product_name_details AS
WITH RECURSIVE
    tokens(row_id, rest, n, token) AS (
        -- base: ambil kata pertama dan sisa kalimat
        SELECT
            row_id,
            TRIM(product_name) AS rest,
            1 AS n,
            CASE
                WHEN instr(TRIM(product_name), ' ') > 0
                    THEN substr(TRIM(product_name), 1, instr(TRIM(product_name), ' ') - 1)
                ELSE TRIM(product_name)
            END AS token
        FROM clean_superstore_orders
        UNION ALL
        -- recursive: dari sisa (rest) ambil kata berikutnya sampai max 10
        SELECT
            row_id,
            LTRIM(SUBSTR(rest, instr(rest, ' ') + 1)) AS rest,
            n + 1 AS n,
            CASE
            WHEN instr(LTRIM(SUBSTR(rest, instr(rest, ' ') + 1)), ' ') > 0
                THEN substr(
                    LTRIM(SUBSTR(rest, instr(rest, ' ') + 1)),
                    1,
                    instr(LTRIM(SUBSTR(rest, instr(rest, ' ') + 1)), ' ') - 1
                    )
            ELSE LTRIM(SUBSTR(rest, instr(rest, ' ') + 1))
            END AS token
        FROM tokens
        WHERE rest LIKE '% %' AND n < 15)
SELECT
  p.row_id, p.category, p.sub_category, p.product_name,
  MAX(CASE WHEN t.n = 1 THEN t.token END) AS word_1,
  MAX(CASE WHEN t.n = 2 THEN t.token END) AS word_2,
  MAX(CASE WHEN t.n = 3 THEN t.token END) AS word_3,
  MAX(CASE WHEN t.n = 4 THEN t.token END) AS word_4,
  MAX(CASE WHEN t.n = 5 THEN t.token END) AS word_5,
  MAX(CASE WHEN t.n = 6 THEN t.token END) AS word_6,
  MAX(CASE WHEN t.n = 7 THEN t.token END) AS word_7,
  MAX(CASE WHEN t.n = 8 THEN t.token END) AS word_8,
  MAX(CASE WHEN t.n = 9 THEN t.token END) AS word_9,
  MAX(CASE WHEN t.n = 10 THEN t.token END) AS word_10,
  MAX(CASE WHEN t.n = 11 THEN t.token END) AS word_11,
  MAX(CASE WHEN t.n = 12 THEN t.token END) AS word_12,
  MAX(CASE WHEN t.n = 13 THEN t.token END) AS word_13,
  MAX(CASE WHEN t.n = 14 THEN t.token END) AS word_14,
  MAX(CASE WHEN t.n = 15 THEN t.token END) AS word_15
FROM clean_superstore_orders p
LEFT JOIN tokens t ON p.row_id = t.row_id
GROUP BY p.row_id
ORDER BY  
    p.category, 
    p.sub_category,
    p.row_id,
    word_1,
    word_2,
    word_3,
    word_4,
    word_5,
    word_6,
    word_7,
    word_8,
    word_9,
    word_10,
    word_11,
    word_12,
    word_13,
    word_14,
    word_15;


-- cek isi VIEW v_product_name_details
SELECT * FROM v_product_name_details;



-- cek details nama produk
SELECT 
    c.product_id,
    coalesce(word_1, '') AS word_1,
    coalesce(word_2, '') AS word_2,
    coalesce(word_3, '') AS word_3,
    coalesce(word_4, '') AS word_4,
    coalesce(word_5, '') AS word_5,
    coalesce(word_6, '') AS word_6,
    coalesce(word_7, '') AS word_7,
    coalesce(word_8, '') AS word_8,
    coalesce(word_9, '') AS word_9,
    coalesce(word_10, '') AS word_10,
    coalesce(word_11, '') AS word_11,
    coalesce(word_12, '') AS word_12,
    coalesce(word_13, '') AS word_13,
    coalesce(word_14, '') AS word_14,
    coalesce(word_15, '') AS word_15
FROM clean_superstore_orders c
JOIN v_product_name_details p ON c.row_id = p.row_id
GROUP BY
    word_1,
    word_2,
    word_3,
    word_4,
    word_5,
    word_6,
    word_7,
    word_8,
    word_9,
    word_10,
    word_11,
    word_12,
    word_13,
    word_14,
    word_15
ORDER BY     
    p.category, p.sub_category, 
    word_1,
    word_2,
    word_3,
    word_4,
    word_5,
    word_6,
    word_7,
    word_8,
    word_9,
    word_10,
    word_11,
    word_12,
    word_13,
    word_14,
    word_15;


----/--------------------------------------------------\--
---/ Cek manual 1850 baris unique data word_1 - word_15 \--- 
--/------------------------------------------------------\--


---/ Problem data yang terdeteksi:
-- 1. INCONSISTENT NAME :
---> High-Back = Highback
---> Low-Back = Lowback 
---> & = and
---> adjustable = Adjustable
---> w/ = with

-- 2. SAME PRODUCT NAME
---> DAX Wood Document Frame. = DAX Wood Document Frame 
---> GBC Standard Plastic Binding Systems Combs = GBC Standard Plastic Binding Systems' Combs


---/ Cek data yang bermasalah : Inconsistent name dan same product name 
SELECT DISTINCT 
    product_name,
    CASE 
        WHEN product_name LIKE '%highb%' THEN 'HIGHBACK'
        WHEN product_name LIKE '%high b%' THEN 'HIGH BACK'
        WHEN product_name LIKE '%low b%' THEN 'LOW BACK'
        WHEN product_name LIKE '% & %' THEN 'AND'
        WHEN product_name LIKE '%w/o%' THEN 'WITHOUT'
        WHEN product_name LIKE '% w/ %' THEN 'WITH'
        WHEN product_name LIKE '%DAX Wood Document Frame.%' THEN 'DAX'
        WHEN product_name LIKE '%GBC Standard Plastic Binding System%' AND product_name <> 'GBC Standard Plastic Binding Systems Combs' THEN 'GBC'
        ELSE 'OK'
    END AS status
FROM clean_superstore_orders
WHERE status <> 'OK'
ORDER BY status;



---/ INPUT KE LOG TABLE
---| 13. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : INCONSISTENT NAME (High-Back, Low-Back, &, w/0, w/)
---  attribute : product_name
---  solution : replace to (High-Back, Low-Back, And, Without , With )
INSERT INTO audit_log 
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'product_name', 
    'INCONSISTENT NAME (high back, low back, &, w/0, w/)', 
    'replace to (High-Back, Low-Back, And, Without , With )',
    'clean_superstore_orders',
    (SELECT count(row_id) FROM clean_superstore_orders)   
FROM clean_superstore_orders
GROUP BY row_id
HAVING 
    product_name LIKE '%highb%'OR
    product_name LIKE '%high b%'OR
    product_name LIKE '%low-b%'OR
    product_name LIKE '%low b%'OR
    product_name LIKE '% & %'OR
    product_name LIKE '%w/o%'OR
    product_name LIKE '%w/%'
ORDER BY row_id;



---/ INPUT KE LOG TABLE
---| 14. INSERT PROBLEMATIC DATA
---  source_table : clean_superstore_orders
---  reason : SAME PRODUCT NAME
---  attribute : product_name
---  solution : replace as one
INSERT INTO audit_log 
    (row_id, attribute, reason, solution, source_table, total_rows)
SELECT 
    row_id, 
    'product_name', 
    'SAME PRODUCT NAME', 
    'replace as one',
    'clean_superstore_orders', 
    (SELECT count(row_id) FROM clean_superstore_orders)   
FROM clean_superstore_orders
GROUP BY row_id
HAVING 
    product_name LIKE '%DAX Wood Document Frame%' OR
    product_name LIKE '%GBC Standard Plastic Binding Systems%'
ORDER BY row_id;


---| UPDATE DATA PROBLEMATIC INCONSISTENT NAME (High-Back, Low-Back, &, w/0, w/)
---- tabel data clean product_name
UPDATE clean_superstore_orders
SET product_name = 
    CASE 
        WHEN product_name LIKE '%highb%' THEN trim(REPLACE(product_name, 'Highback', 'High-Back'))
        WHEN product_name LIKE '%high b%' THEN trim(REPLACE(product_name, 'High Back', 'High-Back'))
        WHEN product_name LIKE '%low b%' THEN trim(REPLACE(product_name, 'Low Back', 'Low-Back'))
        WHEN product_name LIKE '% & %' THEN trim(REPLACE(product_name, ' & ', ' And '))
        WHEN product_name LIKE '%w/o%' THEN trim(REPLACE(product_name, 'w/o', 'Without '))
        WHEN product_name LIKE '% w/%' THEN trim(REPLACE(product_name, 'w/', 'With '))
        WHEN product_name LIKE '%DAX Wood Document Frame%' THEN trim(REPLACE(product_name, '.', ''))
        WHEN product_name LIKE '%GBC Standard Plastic Binding Systems%' THEN 'GBC Standard Plastic Binding Systems Combs'
        ELSE product_name
    END
WHERE 
    product_name LIKE '%highb%'OR
    product_name LIKE '%high b%'OR
    product_name LIKE '%low-b%'OR
    product_name LIKE '%low b%'OR
    product_name LIKE '% & %'OR
    product_name LIKE '%w/o%'OR
    product_name LIKE '% w/%' OR
    product_name LIKE '%DAX Wood Document Frame%' OR
    product_name LIKE '%GBC Standard Plastic Binding Systems%';
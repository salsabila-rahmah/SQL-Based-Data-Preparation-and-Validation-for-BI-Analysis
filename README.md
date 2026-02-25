<h1 align="center">SQL-Based Data Preparation and Validation for BI Analysis</h1>
<div align="justify">



[PROJECT OVERVIEW](#project-overview)
- [1. Datasets](#1-datasets)
- [2. Data Quality Metrics](#2-data-quality-metrics)
- [3. Technical Approach Tools](#3-technical-approach--tools)


[DATA VALIDATION & MODELING PROCESS](#data-validation--modeling-process)
- [1. Structural Cleaning & Normalization](#1-structural-cleaning--normalization)
- [2. Entity Integrity Controls](#2-entity-integrity-controls)
- [3. Business Rule Validation](#3-business-rule-validation)
- [4. Statistical Control](#4-statistical-control)
- [5. Data Modeling](#5-data-modeling)
- [6. Audit & Change Governance](#6-audit--change-governance)
- [7. Analytical Layer](#7-analytical-layer)

<BR>
<h2 align="center">PROJECT OVERVIEW</h2>

Two quarterly sales datasets were consolidated & rebuilt into a controlled analytical layer using SQL. This project focuses on making sure KPIs & profitability analysis are based on structurally sound, logically valid, & statistically controlled data before any BI dashboard is built. All transformations are rule-based & fully traceable. The project covers the full pipeline from raw ingestion to validated output.

- Total processed: 25,234 transactions
- Final validated dataset: 24,735 transactions → Interactive Tableau Public dashboard built from this dataset [[_VIEW HERE_]](https://public.tableau.com/app/profile/salsabila.rahmah/viz/SalesOverviewSuperstoreOrders20142017/SalesOverviewSuperstoreOrders201420170)



#### _1. DATASETS_
- Superstore Sales: The Data Quality Challenge ([_Kaggle_](https://www.kaggle.com/datasets/dataobsession/superstore-sales-the-data-quality-challenge)) as the primary transactional source
- List of U.S. Cities ([_Britannica_](https://www.britannica.com/topic/list-of-cities-and-towns-in-the-United-States-2023068) ─ scraped & cleaned using Google Sheets) for city & postal code validation



#### _2. DATA QUALITY METRICS_
- 25,234 rows consolidated from two sources
- 40 exact duplicate transactions removed
- 459 logically invalid records eliminated
- 1,483 product identity conflicts resolved (canonical mapping)
- 14,988+ category values standardized
- 1,022 statistical outliers flagged (P01/P99 method)
- 100% of changes logged through **audit_log** tables with triggers back up



#### _3. TECHNICAL APPROACH & TOOLS_
This project built using SQL (SQLite) in Visual Studio Code, with dbdiagram.io for ERD design & Google Sheets for supporting data cleanup. The process covers:
- Data cleaning & normalization
- Rule-based transaction validation
- Percentile outlier detection (P01/P99)
- Audit logging with trigger automation
- Star-schema modeling
- CTEs, window functions, joins, & aggregation
- Conditional feature engineering
- BI-ready view creation





<BR>
<h2 align="center">DATA VALIDATION & MODELING PROCESS</h2>


#### _1. STRUCTURAL CLEANING & NORMALIZATION_

The raw dataset had fragmented categories, inconsistent naming formats, missing values, & duplicate rows. Main corrections:
- 1,766 blank discount values standardized
- 2,457 invalid region entries corrected
- 14,988+ category values unified into proper domains (South, West, Central, East)
- 860 inconsistent product name formats standardized
- 63 postal code–city mismatches reconciled
- 40 duplicate rows removed



#### _2. ENTITY INTEGRITY CONTROLS_

The dataset contained identity conflicts that would break aggregation & dimensional modeling. Canonical mapping was implemented to ensure consistent product representation.

- 835 cases where one product_name mapped to multiple product_id
- 648 cases where one canonical_id mapped to multiple product_name

Total entity conflicts resolved: **1,483**


#### _3. BUSINESS RULE VALIDATION_

Transaction-level validation was applied to align with real business logic.

- 352 cases of profit < -sales
- 7 cases of profit > sales
- 100 invalid sales records

Total logically invalid rows removed: **459**

Additional checks performed to prevents incorrect KPI & profitability calculations, included:

- Sales & quantity alignment
- Discount range validation
- Date hierarchy consistency
- Cross-table aggregation checks


#### _4. STATISTICAL CONTROL_
Outliers were identified using percentile thresholds (P01/P99) per sub_category. Outliers remain in the dataset but are clearly labeled to protects aggregate metrics while keeping full transactional history.

- 1,022 rows flagged across unit_price, sales, profit, & margin
- Outliers were flagged, not deleted



#### _5. DATA MODELING_

The ERD was designed after cleaning & validation were completed. The final structure follows a star-schema approach & supports BI reporting ([_see figure_](https://github.com/user-attachments/assets/d0a11b36-4842-4b23-95ed-7d031664c8e4)). Fact & dimension tables were built from the validated dataset to ensure:

- Clean transactional grain
- Standardized dimensions
- Consistent product identifiers
- No duplicate or logically invalid records

<img width="1289" height="814" alt="image" src="https://github.com/user-attachments/assets/d0a11b36-4842-4b23-95ed-7d031664c8e4" />



#### _6. AUDIT & CHANGE GOVERNANCE_
Every step of cleaning, validation, & transformation is tracked for full traceability:
- Actions are recorded in **audit_log** tables & **BACKUP_audit_log**
- Triggers automatically capture updates, deletions, & anomalies into **BACKUP_audit_log** tables
- Each change is linked to a defined rule for full accountability
 

#### _7. ANALYTICAL LAYER_
The final analytical layer provides a BI-ready dataset:
- Primary view: **v_orders_analysis_ready** integrates all cleaned, validated, & standardized data
- Invalid or inconsistent transactions are excluded
- Aggregation-ready attributes are exposed for KPI & profitability analysis
- Supporting views (**v_kpi_core**, **v_discount_analysis**) allow exploration without touching the core dataset


</div>

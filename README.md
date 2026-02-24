<h1 align="center">SQL-Based Data Preparation and Validation for BI Analysis</h1>
<div align="justify">
 

[PROJECT OVERVIEW](#project-overview)
- [DATASETS](#datasets)
- [TOOLS](#tools)
- [SQL & DATA PREPARATION APPROACH](#sql--data-preparation-approach)

[INITIAL DATA ASSESSMENT](#initial-data-assessment)
- [1. MISSING & UNDEFINED VALUES](#1-missing--undefined-values)
- [2. CATEGORICAL & TEXT INCONSISTENCIES](#2-categorical--text-inconsistencies)
- [3. ENTITY INTEGRITY & KEY CONFLICTS](#3-entity-integrity--key-conflicts)
- [4. BUSINESS LOGIC VIOLATIONS](#4-business-logic-violations)
- [5. STATISTICAL ANOMALIES](#5-statistical-anomalies)

[DATA PREPARATION & CONTROL](#data-preparation--control)
- [ENTITY RELATIONSHIP DIAGRAMS (ERD)](#entity-relationship-diagrams-erd)
- [1. STRUCTURAL & ENTITY CONTROLS](#1-structural--entity-controls)
- [2. RULE-BASED TRANSACTION & BUSINESS VALIDATION](#2-rule-based-transaction--business-validation)
- [3. STATISTICAL CONTROL & OUTLIER MANAGEMENT](#3-statistical-control--outlier-management)
- [4. AUDIT & CHANGE GOVERNANCE](#4-audit--change-governance)
- [5. ANALYTICAL LAYER CONTRUCTION](#5-analytical-layer-contruction)

[ANALYTICAL READINESS & IMPACT](#analytical-readiness--impact)


<BR>

<h2 align="center">PROJECT OVERVIEW</h2>

This project prepares raw transactional sales data for accurate KPI and profitability analysis by establishing a validated analytical foundation before BI reporting begins. Using SQL, the dataset was systematically audited and transformed to resolve structural inconsistencies, entity conflicts, business rule violations, and statistical outliers. All transformations follow explicit validation rules to ensure traceability and analytical reliability. The final output is a clean, controlled analytical layer designed for direct use in BI tools.

#### _DATASETS_
- Superstore Sales: The Data Quality Challenge ([_Kaggle_](https://www.kaggle.com/datasets/dataobsession/superstore-sales-the-data-quality-challenge))
- List of U.S. Cities ([_Britannica_](https://www.britannica.com/topic/list-of-cities-and-towns-in-the-United-States-2023068) ─ scraped and cleaned using Google Sheets)

#### _TOOLS_
SQL (SQLite), Visual Studio Code, dbdiagram.io, and Google Sheets

#### _SQL & DATA PREPARATION APPROACH_
 - Data cleaning & normalization
 - Business rules-based validation
 - Percentile-based outlier detection (P01/P99)
 - Audit logging & trigger automation
 - Star-schema modeling
 - CTEs & window functions
 - Multi-table joins & aggregation
 - Conditional feature engineering
 - Analysis-ready view creation
<BR>
<h2 align="center">INITIAL DATA ASSESSMENT</h2>

An initial audit was done to to identify structural inconsistencies, entity conflicts, business rule violations, and statistical anomalies that could distort KPI analysis. All findings were recorded in an **audit_log** table to ensure rule-based validation and full traceability of every update, removal, and anomaly flag.



#### 1. _MISSING & UNDEFINED VALUES_
- Blank **_discount_** and **_region_** fields
- **_region_** values outside the valid domain (South, West, Central, East)


#### 2. _CATEGORICAL & TEXT INCONSISTENCIES_
- **_category_** variations (Tech, technologies, Furni, OfficeSupply)
- **_product_name_** formatting inconsistencies (high back, w/, w/0, &, irregular spacing)
- Duplicate naming formats for the same logical product on **_product_name_** field


#### 3. _ENTITY INTEGRITY & KEY CONFLICTS_
- Fully duplicated transaction records
- **_product_name_** linked to multiple **_product_id_** values
- **_canonical_id_** associated with multiple **_product_name_**
- **_postal_code_** mapped to more than one city


#### 4. _BUSINESS LOGIC VIOLATIONS_
- **_profit_** greater than revenue 
- **_profit_** lower than negative revenue
- Transactional inconsistency 
  

#### 5. _STATISTICAL ANOMALIES_
- Extreme values in **_unit_price_**, **_sales_**, **_profit_**, and **_margin_**
- Detected using P01/P99 percentile thresholds per **_sub_category_**

<br>

<h2 align="center">DATA PREPARATION & CONTROL</h2>

#### _ENTITY RELATIONSHIP DIAGRAMS (ERD)_
The relational structure and key dependencies are documented in the [ERD diagram](https://github.com/user-attachments/assets/0985f28c-56cd-4077-a234-679cf532c77b). It defines fact–dimension relationships, entity boundaries, and normalization logic prior to transformation. The ERD serves as the structural foundation for all cleaning, validation, and analysis.

<img width="1289" height="814" alt="image" src="https://github.com/user-attachments/assets/0985f28c-56cd-4077-a234-679cf532c77b" />





#### 1. _STRUCTURAL & ENTITY CONTROLS_
The first step ensures the raw transactional dataset is structurally sound and entity conflicts are resolved.
Key actions include:
- Aligning schema and data types
- Removing exact duplicate rows
- Standardizing categorical values (**_region_**, **_category_**) and normalizing **_product_name_**
- Resolving multiple **_product_id_** or **_product_name_** through canonical mapping
- Reconciling **_postal_code_** with cities
- Handling nulls and correcting domains

Outcome: a clean, coherent dataset ready for rule-based validation, with every entity uniquely and consistently represented.


#### 2. _RULE-BASED TRANSACTION & BUSINESS VALIDATION_
Once the structure is stable, business rules are enforced to make the data analytically trustworthy.
Checks performed:
- **_profit_** boundaries _(profit > sales, profit < -sales)_
- Transactional consistency _(sales = 0 AND quantity >= 1 AND discount < 1 AND profit >= 0)_
- **_sales_** and **_quantity_** alignment
- **_discount_** range verification
- Date hierarchy checks
- Cross-table aggregation validation
- Violations are flagged and tracked to maintain defensibility, ensuring KPI calculations will reflect true business reality.

Outcome: logically consistent transactions that can safely feed analytical models and BI dashboards.


#### 3. _STATISTICAL CONTROL & OUTLIER MANAGEMENT_
To prevent extreme values from skewing analysis:
- Percentile-based thresholds (P01/P99) were calculated per **_sub_category_**
- Flags applied to **_unit_price_**, **_sales_**, **_profit_**, and **_margin_**
- Outliers remain in the dataset but are clearly labeled

Outcome: a controlled dataset that preserves variation without compromising analytical integrity.


#### 4. _AUDIT & CHANGE GOVERNANCE_
Traceability is built into every step:
- All cleaning, validation, and analysis actions are recorded in **audit_log** tables
- Triggers automatically capture updates, deletions, and anomalies into backup tables
- Each change is linked to a defined rule for full accountability

Outcome: a fully auditable workflow where any modification or exclusion can be traced and justified.



#### 5. _ANALYTICAL LAYER CONTRUCTION_
The final step materializes the analysis-ready dataset for BI consumption:
- Primary view: **v_orders_analysis_ready** integrates all cleaned, validated, and standardized data
- Invalid or inconsistent transactions are excluded
- Aggregation-ready attributes are exposed for KPI and profitability analysis
- Supporting views (**v_kpi_core**, **v_discount_analysis**) allow exploratory analysis without affecting the core dataset

Outcome: a stable, governed, and analysis-ready layer that acts as a single source of truth for BI reporting.



<BR>
<h2 align="center">ANALYTICAL READINESS & IMPACT</h2>

The messy raw sales dataset has been transformed into a BI-ready layer that is structurally consistent, bussiness-rule validated, and statistically controlled. All issues were systematically addressed using SQL, with every change tracked in audit log for full traceability. KPIs can now be calculated directly, without additional adjustments. The resulting dataset delivers reliable, defensible metrics ready for direct use in BI tools, providing a controlled analytical foundation that ensures KPIs and business insights can be trusted.

- **_Clean & consistent data_**: duplicates removed, categories standardized, product IDs normalized, postal codes reconciled
- **_Rule-based transactions_**: profit, sales, discount, and transactional consistency validated to reflect real business logic 
- **_Controlled outliers_**: statistical thresholds applied (P01/P99) and flagged, preserving variation without distorting KPIs
- **_Traceable governance_**: audit logs and triggers link every change to a defined rule for full accountability
- **_Analysis-ready_**: v_orders_analysis_ready as single source of truth for BI reporting, with supporting views for exploration



</div>

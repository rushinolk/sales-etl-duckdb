-- ==============================================================================
-- 1. CTE BASE (Leitura da Camada Silver e Deduplicação)
-- ==============================================================================
CREATE OR REPLACE TEMPORARY VIEW base_limpa AS (
    WITH cte_deduplicada AS (
        SELECT *,
            ROW_NUMBER() OVER(
                PARTITION BY order_id 
                ORDER BY order_date DESC
            ) as rn
        FROM read_parquet('{{input_path}}')
    )
    SELECT * EXCLUDE (rn) 
    FROM cte_deduplicada 
    WHERE rn = 1
);

-- ==============================================================================
-- 2. DIM_CUSTOMER (Dimensão Cliente Atualizada)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id         VARCHAR(10) PRIMARY KEY,
    customer_name       VARCHAR(100),
    customer_segment    VARCHAR(50),
    customer_type       VARCHAR(50),
    region              VARCHAR(50),
    first_purchase_date DATE,
    last_purchase_date  DATE,
    churn_flag          VARCHAR(10) -- Mantendo VARCHAR para 'Yes'/'No' ou '1'/'0'
);

INSERT INTO dim_customer (
    customer_id, customer_name, customer_segment, customer_type, region, 
    first_purchase_date, last_purchase_date, churn_flag
)
SELECT DISTINCT 
    customer_id, 
    customer_name, 
    customer_segment, 
    customer_type, 
    region,
    TRY_CAST(first_purchase_date AS DATE), -- Garantindo que venha como data
    TRY_CAST(last_purchase_date AS DATE),
    churn_flag
FROM base_limpa
ON CONFLICT (customer_id) DO NOTHING;


-- ==============================================================================
-- 3. DIM_PRODUCT (Dimensão Produto)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS dim_product (
    product_id          VARCHAR(10) PRIMARY KEY,
    product_name        VARCHAR(100),
    category            VARCHAR(50),
    sub_category        VARCHAR(50),
    brand               VARCHAR(50)
);

INSERT INTO dim_product (product_id, product_name, category, sub_category, brand)
SELECT DISTINCT 
    product_id, 
    product_name, 
    category, 
    sub_category, 
    brand
FROM base_limpa
ON CONFLICT (product_id) DO NOTHING;

-- ==============================================================================
-- 4. DIM_REPRESENTATIVE (Dimensão Representante)
-- ==============================================================================
CREATE SEQUENCE IF NOT EXISTS seq_representative START 1;

CREATE TABLE IF NOT EXISTS dim_representative (
    rep_id              INTEGER PRIMARY KEY DEFAULT NEXTVAL('seq_representative'),
    sales_rep           VARCHAR(100) UNIQUE
);

INSERT INTO dim_representative (sales_rep)
SELECT DISTINCT sales_rep
FROM base_limpa
ON CONFLICT (sales_rep) DO NOTHING;

-- ==============================================================================
-- 5. DIM_TIME (Dimensão Tempo)
-- ==============================================================================
CREATE SEQUENCE IF NOT EXISTS seq_time START 1;

CREATE TABLE IF NOT EXISTS dim_time (
    time_id             INTEGER PRIMARY KEY DEFAULT NEXTVAL('seq_time'),
    date                DATE UNIQUE,
    day                 INTEGER,
    month               INTEGER,
    year                INTEGER,
    quarter             INTEGER
);

INSERT INTO dim_time (date, day, month, year, quarter)
SELECT DISTINCT 
    CAST(order_date AS DATE) AS date,
    EXTRACT(DAY FROM CAST(order_date AS DATE))::INT AS day,
    EXTRACT(MONTH FROM CAST(order_date AS DATE))::INT AS month,
    EXTRACT(YEAR FROM CAST(order_date AS DATE))::INT AS year,
    EXTRACT(QUARTER FROM CAST(order_date AS DATE))::INT AS quarter
FROM base_limpa
WHERE order_date IS NOT NULL
ON CONFLICT (date) DO NOTHING;
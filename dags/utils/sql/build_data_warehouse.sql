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
        FROM read_csv('{{input_path}}')
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

-- ==============================================================================
-- 2. FACT_ORDER (Tabela Fato e Métricas de Negócio)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS fact_order (
    order_id           BIGINT PRIMARY KEY,
    customer_id        VARCHAR(10) REFERENCES dim_customer(customer_id),
    rep_id             INT REFERENCES dim_representative(rep_id),
    product_id         VARCHAR(10) REFERENCES dim_product(product_id),
    time_id            INT REFERENCES dim_time(time_id),
    sales_channel      VARCHAR(50),
    payment_method     VARCHAR(50),
    quantity           INT,
    unit_price         DECIMAL(12,2),
    discount_pct       DECIMAL(3,2),
    
    -- Colunas Financeiras Originais
    operating_expenses DECIMAL(12,2),
    cash_balance       DECIMAL(12,2),
    debt_balance       DECIMAL(12,2),
    monthly_burn       DECIMAL(12,2),
    
    -- Métricas Calculadas (Passo 5)
    gross_revenue      DECIMAL(12,2),
    net_revenue        DECIMAL(12,2),
    cost_of_goods_sold DECIMAL(12,2),
    gross_profit       DECIMAL(12,2),
    net_income         DECIMAL(12,2) -- Adicionada a métrica de Lucro Líquido
);

INSERT INTO fact_order (
    order_id, customer_id, rep_id, product_id, time_id, 
    sales_channel, payment_method, quantity, unit_price, discount_pct, 
    operating_expenses, cash_balance, debt_balance, monthly_burn,
    gross_revenue, net_revenue, cost_of_goods_sold, gross_profit, net_income
)
SELECT
    r.order_id,
    r.customer_id,
    dr.rep_id,
    r.product_id,
    dt.time_id,
    r.sales_channel,
    r.payment_method,
    r.quantity,
    r.unit_price,
    r.discount_pct,
    r.operating_expenses,
    r.cash_balance,
    r.debt_balance,
    r.monthly_burn,
    
    -- 1. Faturamento Bruto (Quantidade * Preço)
    (r.quantity * r.unit_price) AS gross_revenue,
    
    -- 2. Faturamento Líquido (Aplicando Desconto)
    ((r.quantity * r.unit_price) * (1 - r.discount_pct)) AS net_revenue,
    
    -- 3. Custo dos Produtos Vendidos (Regra de Negócio por Subcategoria)
    CASE 
        WHEN dp.sub_category = 'Smartphones' THEN ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.70
        WHEN dp.sub_category = 'Laptops'     THEN ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.80
        WHEN dp.sub_category = 'Peripherals' THEN ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.40
        ELSE ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.60
    END AS cost_of_goods_sold,
    
    -- 4. Lucro Bruto (Net Revenue - COGS)
    (
        ((r.quantity * r.unit_price) * (1 - r.discount_pct)) -
        (CASE 
            WHEN dp.sub_category = 'Smartphones' THEN ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.70
            WHEN dp.sub_category = 'Laptops'     THEN ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.80
            WHEN dp.sub_category = 'Peripherals' THEN ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.40
            ELSE ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.60
        END)
    ) AS gross_profit,
    
    -- 5. Lucro Líquido (Gross Profit - Despesas Operacionais)
    (
        (
            ((r.quantity * r.unit_price) * (1 - r.discount_pct)) -
            (CASE 
                WHEN dp.sub_category = 'Smartphones' THEN ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.70
                WHEN dp.sub_category = 'Laptops'     THEN ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.80
                WHEN dp.sub_category = 'Peripherals' THEN ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.40
                ELSE ((r.quantity * r.unit_price) * (1 - r.discount_pct)) * 0.60
            END)
        ) - r.operating_expenses
    ) AS net_income

FROM base_limpa r
JOIN dim_representative dr ON dr.sales_rep = r.sales_rep
JOIN dim_time dt           ON dt.date = CAST(r.order_date AS DATE)
JOIN dim_product dp        ON dp.product_id = r.product_id
ON CONFLICT (order_id) DO NOTHING;

-- ==============================================================================
-- 3. VIEWS ANALÍTICAS (Data Marts Prontos para o Tableau)
-- ==============================================================================

-- KPI 1: Resumo Geral de Vendas (Faturamento e Tickets)
CREATE OR REPLACE VIEW view_kpis_gerais AS
SELECT 
    COUNT(order_id) AS qtd_pedidos,
    SUM(quantity) AS total_itens_vendidos,
    SUM(gross_revenue) AS faturamento_bruto_total,
    SUM(net_revenue) AS faturamento_liquido_total,
    AVG(net_revenue) AS ticket_medio,
    AVG(discount_pct) AS desconto_medio
FROM fact_order;

-- KPI 2: Análise de Recorrência de Clientes
CREATE OR REPLACE VIEW view_customer_recurrence AS
SELECT 
    customer_id,
    COUNT(order_id) AS qtd_compras,
    CASE 
        WHEN COUNT(order_id) = 1 THEN 'Novo'
        WHEN COUNT(order_id) > 1 THEN 'Recorrente'
    END AS status_recorrencia
FROM fact_order
GROUP BY customer_id;
-- Exemplo do que seria sua CTE (Common Table Expression) inicial ou a primeira transformação
SELECT
    -- Mantendo as chaves e dimensões
    order_id,
    customer_id,
    customer_name,
    customer_segment,
    customer_type,
    product_id,
    product_name,
    category,
    sub_category,
    brand,
    sales_channel,
    payment_method,
    sales_rep,
    region,

    -- Desmembrando as datas (Passo 4.1)
    order_date,
    EXTRACT(YEAR FROM CAST(order_date AS DATE)) AS order_year,
    EXTRACT(MONTH FROM CAST(order_date AS DATE)) AS order_month,
    EXTRACT(QUARTER FROM CAST(order_date AS DATE)) AS order_quarter,

    -- Mantendo os valores numéricos básicos
    quantity,
    unit_price,
    discount_pct

FROM read_csv_auto("data/raw/eletronics_sales.csv");
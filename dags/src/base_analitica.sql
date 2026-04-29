SELECT 
    *,
    (quantity * unit_price) AS gross_revenue,
    ((quantity * unit_price) * (1 - discount_pct)) AS net_revenue
FROM read_parquet('{{input_path}}');
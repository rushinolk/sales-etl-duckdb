import pendulum
from airflow import DAG
from airflow.decorators import task

import logging
from datetime import timedelta

# Importando os scripts modulares que criamos
from utils.extract import extract
from utils.validate import validate_and_clean_data
from utils.db_engine import execute_and_export_star_schema

# Configuração da DAG
default_args = {
    'owner': 'engenheiro_dados',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(seconds=30),
}

with DAG(
    dag_id='electronics_sales_etl',
    default_args=default_args,
    description='Pipeline de Vendas de Eletrônicos (Silver para Gold via DuckDB)',
    schedule=None,
    start_date=pendulum.datetime(2025,1,1,tz="America/Sao_Paulo"),
    catchup=False,
    tags=['vendas', 'etl', 'duckdb'],
) as dag:

    @task(task_id='extract_raw_data')
    def task_extract():
        URL_DO_GDRIVE = "https://drive.google.com/file/d/1We8h8dQ8n4w-lTYrUPeiIa_hrbdSX2mV/view?usp=drive_link"
        
        caminho_raw = extract(
            data_path="data/bronze",
            source_name="electronics_sales.csv",
            url=URL_DO_GDRIVE
        )
        return caminho_raw

    @task(task_id='validate_and_clean')
    def task_validate(caminho_raw: str):
        caminho_silver = "data/silver/electronics_sales_clean.csv"
        caminho_limpo = validate_and_clean_data(caminho_raw, caminho_silver)
        return caminho_limpo

    @task(task_id='build_data_warehouse')
    def task_build_dw(caminho_silver: str):
        tabelas_e_views = [
            "dim_customer",
            "dim_product",
            "dim_representative",
            "dim_time",
            "fact_order",
            "view_kpis_gerais",
            "view_customer_recurrence"
        ]
        
        arquivos_exportados = execute_and_export_star_schema(
            sql_file_path='/opt/airflow/dags/utils/sql/build_data_warehouse.sql',
            input_data_path=caminho_silver,
            output_folder='data/gold',
            tables_to_export=tabelas_e_views,
            db_path='/opt/airflow/data/gold/data_warehouse.duckdb'
        )
        return arquivos_exportados

    # Orquestração Linear (Sem triângulos esquisitos!)
    caminho_raw = task_extract()
    caminho_silver = task_validate(caminho_raw)
    task_build_dw(caminho_silver)
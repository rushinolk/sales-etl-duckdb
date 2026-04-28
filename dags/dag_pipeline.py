import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.sdk import task




default_args = {
    "depends_on_past" : False,
    "email": ["teste@email.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 3,
    "retry_delay": timedelta(seconds=30),
}


with DAG(
    dag_id="dag_eletronics_pipeline",
    description="Orquestração do projeto de ETL do Desafio 3: eletronics sales",
    default_args=default_args,
    schedule=None,
    start_date=pendulum.datetime(2025,1,1,tz="America/Sao_Paulo"),
    catchup=False,
    tags=["Pratica","Etl"]
) as dag:

import duckdb
import os
import logging

logger = logging.getLogger(__name__)

def execute_and_export_star_schema(
    sql_file_path: str, 
    input_data_path: str, 
    output_folder: str, 
    tables_to_export: list,
    db_path: str = 'data/gold/data_warehouse.duckdb' # <--- A GRANDE MUDANÇA
) -> list:
    """
    Executa scripts SQL em um banco DuckDB persistente e exporta tabelas para Parquet.
    """
    os.makedirs(output_folder, exist_ok=True)
    arquivos_exportados = []

    with open(sql_file_path, 'r', encoding='utf-8') as file:
        raw_query = file.read()
    
    script_sql = raw_query.replace('{{input_path}}', input_data_path)

    try:
        # AGORA ELE CONECTA EM UM ARQUIVO FÍSICO. 
        # Se o arquivo não existir, o DuckDB cria na hora.
        con = duckdb.connect(db_path) 
        
        logger.info(f"Conectado ao DW físico em: {db_path}")
        logger.info(f"Executando script: {sql_file_path}")
        
        con.execute(script_sql)
        
        for table in tables_to_export:
            output_path = os.path.join(output_folder, f"{table}.csv").replace('\\', '/')
            export_query = f"COPY {table} TO '{output_path}' (HEADER, DELIMITER ',');"
            con.execute(export_query)
            
            arquivos_exportados.append(output_path)
            logger.info(f"[OK] Tabela '{table}' salva em: {output_path}")

        con.close()
        return arquivos_exportados
        
    except Exception as e:
        logger.error(f"Erro crítico no processamento do DuckDB: {e}")
        raise
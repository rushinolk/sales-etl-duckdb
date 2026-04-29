import duckdb
import os
import logging

logger = logging.getLogger(__name__)

def execute_sql_file(sql_file_path: str, input_data_path: str, output_data_path: str) -> str:
    """
    Lê um arquivo .sql, injeta o caminho dos dados de origem e salva o resultado.
    """
    os.makedirs(os.path.dirname(output_data_path), exist_ok=True)
    
    # 1. Lê a query do arquivo .sql
    with open(sql_file_path, 'r') as file:
        raw_query = file.read()
    
    # 2. Injeta o caminho do dado na query (substitui o placeholder)
    query_com_dado = raw_query.replace('{{input_path}}', input_data_path)
    
    # 3. Envelopa a query no comando COPY do DuckDB para exportar o resultado
    # Perceba que o Python injeta a regra de negócio DENTRO da instrução de cópia
    final_query = f"COPY ({query_com_dado}) TO '{output_data_path}' (FORMAT PARQUET);"

    try:
        con = duckdb.connect()
        con.execute(final_query)
        con.close()
        
        logger.info(f"Query {sql_file_path} executada. Resultado em: {output_data_path}")
        return output_data_path
        
    except Exception as e:
        logger.error(f"Erro ao executar {sql_file_path}: {e}")
        raise
# Refatoração sugerida para o seu arquivo de validação (Pandas)
import pandas as pd
import logging
import os

logger = logging.getLogger(__name__)

def validate_and_clean_data(file_path: str, output_path: str) -> str:
    """Realiza a limpeza exigida no Passo 3 usando Pandas."""
    try:
        df = pd.read_csv(file_path)
        logger.info(f"Dados carregados: {df.shape[0]} linhas.")

        # 1. Padronização de Strings e IDs
        df['customer_id'] = df['customer_id'].astype(str).str.strip().str.upper()
        df['product_id'] = df['product_id'].astype(str).str.strip().str.upper()
        
        categorical_cols = ['category', 'sub_category', 'sales_channel', 'payment_method', 'region']
        for col in categorical_cols:
            df[col] = df[col].astype(str).str.strip().str.title()

        # 2. Tratamento de Datas
        date_cols = ['order_date', 'first_purchase_date', 'last_purchase_date']
        for col in date_cols:
            df[col] = pd.to_datetime(df[col], errors='coerce')

        # 3. Consistência Numérica (Filtros encadeados são mais limpos)
        df = df[
            (df['quantity'] > 0) & 
            (df['unit_price'] >= 0) & 
            (df['discount_pct'] >= 0) & 
            (df['discount_pct'] <= 1)
        ]

        # 4. Limpeza Final
        df = df.drop_duplicates()
        df = df.dropna(subset=['order_date'])

        # Salva o arquivo limpo para o DuckDB consumir
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        # Sugiro salvar como CSV limpo ou Parquet intermediário
        df.to_csv(output_path, index=False) 
        
        logger.info(f"Dados validados: {df.shape[0]} linhas. Salvo em: {output_path}")
        return output_path

    except Exception as e:
        logger.error(f"Erro na validação: {e}")
        raise
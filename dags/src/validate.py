import pandas as pd
import logging



def default_id(df):
    id_columns = ['customer_id', 'product_id']
    for col in id_columns:
        df[col] = df[col].astype(str).str.strip().str.upper()

def default_categorical(df):
    categorical_columns = ['category', 'sub_category', 'sales_channel', 'payment_method', 'region']
    for col in categorical_columns:
        df[col] = df[col].astype(str).str.strip().str.title()

def default_dates(df):
    date_columns = ['order_date', 'first_purchase_date', 'last_purchase_date']
    for col in date_columns:
        df[col] = pd.to_datetime(df[col], errors='coerce')

def check_quantity(df):
    df = df[df['quantity'] > 0]
    return df

def check_unit_price(df):
    df = df[df['unit_price'] >= 0]
    return df

def check_discount_pct(df):
    df = df[(df['discount_pct'] >= 0) & (df['discount_pct'] <= 1)]
    return df

def check_duplicates(df):
    df = df.drop_duplicates()
    return df

def drop_nulls(df):
    df = df.dropna(subset=['order_date'])
    return df



def validate_and_clean_data(file_path):
    try:
        df = pd.read_csv(file_path)
        logging.info(f"Dados carregados: {df.shape[0]} linhas originais.")

        default_id(df)
        default_categorical(df)
        default_dates(df)

        df = check_quantity(df)
        df = check_unit_price(df)
        df = check_discount_pct(df)
        df = check_duplicates(df)
        df = drop_nulls(df)

        logging.info(f"Dados validados: {df.shape[0]} linhas válidas restantes.")
        
        return df

    except Exception as e:
        logging.error(f"Erro durante a validação: {e}")
        raise 
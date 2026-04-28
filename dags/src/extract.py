import os
import gdown
import pandas as pd
import logging


logging.basicConfig(
    level=logging.INFO,  
    format='%(asctime)s - %(levelname)s - %(message)s', # Formato da mensagem
    datefmt='%Y-%m-%d %H:%M:%S', # Formato da data
    handlers=[
        logging.FileHandler("logs/script_pipeline/pipeline.log"), # Salva o log em um arquivo
        logging.StreamHandler()            # Também exibe o log no console
    ]
)



url =" https://drive.google.com/file/d/1We8h8dQ8n4w-lTYrUPeiIa_hrbdSX2mV/view?usp=drive_link"
data_path = "data/raw/"
source_name = "eletronics_sales.csv"
output = f"{data_path}{source_name}"


def create_folder(path):
    os.makedirs(path, exist_ok=True)
    logging.info(f"Pasta '{path}' garantida (criada ou já existente).")



def download_file(source_name, data_path, url, output):        
    if source_name not in os.listdir(data_path):
        try:
            gdown.download(url, output, quiet=False)
            print(f"Download concluido com sucesso. O arquivo foi salvo em: {output}")
        except Exception as e:
            print(f"Error ao baixar o arquivo: {e}")




def extract():
    create_folder(data_path)
    download_file(source_name, data_path, url, output)

    return output



"""
first_push_data
last_push_data
order_date

"""
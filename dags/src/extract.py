import os
import gdown
import pandas as pd
import logging



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



def extract(data_path, source_name, url):

    output = os.path.join(data_path, source_name)

    create_folder(data_path)
    download_file(source_name, data_path, url, output)

    return output



# 💻 Electronics Sales: End-to-End Data Engineering Pipeline

Pipeline de dados **ELT** construído para extrair, processar e gerar inteligência a partir de um dataset de vendas de eletrônicos. O foco principal foi a criação de uma fundação arquitetural robusta, resiliente a falhas e modularizada, cobrindo desde a ingestão de dados brutos até a modelagem dimensional em um Data Warehouse.

![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Apache Airflow](https://img.shields.io/badge/Airflow-017CEE?style=for-the-badge&logo=Apache%20Airflow&logoColor=white)
![DuckDB](https://img.shields.io/badge/DuckDB-FFF000?style=for-the-badge&logo=duckdb&logoColor=black)
![SQL](https://img.shields.io/badge/SQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)

---

## 📊 Resultados em Destaque

| Métrica | Resultado |
| :--- | :--- |
| 💰 **Faturamento Líquido** | **$ 5,47 Mi** rastreados no período |
| 📈 **Lucro Bruto** | **$ 1,63 Mi** processados após aplicação de COGS por subcategoria |
| 🛒 **Volume de Vendas** | **11 Mil** itens vendidos distribuídos em **7000** pedidos |
| 💳 **Ticket Médio** | **$ 781,85** por pedido |
| 📱 **Top Categorias** | **Smartphones ($ 2,10 Mi)** e **Laptops ($ 1,99 Mi)** |
| ⚠️ **Saúde da Base** | Retenção de **79,21% (Ativos)** contra um **Churn de 20,79%** |

---

## 📐 Arquitetura Medallion (Bronze → Silver → Gold)

Todo o fluxo de dados foi modelado seguindo as melhores práticas de Engenharia de Dados para garantir idempotência e qualidade:

* 🥉 **Camada Bronze (Ingestão)**
  * **Processo:** Download automatizado do dataset bruto via script Python.
  * **Resultado:** Dados brutos preservados em sua forma original para garantir a rastreabilidade da fonte.

* 🥈 **Camada Silver (Limpeza e Validação)**
  * **Processo (Pandas):** Transformação focada em tipagem estrita e consistência.
  * **Resultado:** Padronização de strings, conversão de datas e aplicação de filtros de consistência numérica (ex: remoção de pedidos com quantidades negativas ou descontos inválidos).

* 🥇 **Camada Gold (Analytics & DW)**
  * **Processo (DuckDB + SQL):** Modelagem dimensional em **Star Schema**.
  * **Resultado:** Criação de tabelas de dimensão (Cliente, Produto, Representante, Tempo) e tabela Fato, com regras de negócio complexas (como COGS diferenciado por categoria) calculadas diretamente no banco.

---

## 🏗️ Arquitetura do Pipeline

```text
       DATA SOURCE (CSV via URL)
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│                  CAMADA BRONZE  (Python)                     │
│  extract.py ──► Download e persistência (raw_data.csv)       │
└──────────────────────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│           ORQUESTRAÇÃO: APACHE AIRFLOW (TaskFlow API)        │
│  Orquestração linear modular isolando as falhas por task     │
└──────────────────────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│                  CAMADA SILVER  (Pandas)                     │
│  validate.py ──► Tipagem, Deduplicação e Limpeza Numérica    │
└──────────────────────────────────────────────────────────────┘
           │   (Transferência de estado via Checkpoints de Arquivo)
           ▼
┌──────────────────────────────────────────────────────────────┐
│               CAMADA GOLD / MARTS  (DuckDB + SQL)            │
│  build_data_warehouse.sql ──► Star Schema e Business Logic   │
└──────────────────────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│                  DASHBOARD  (Power BI)                       │
│  Frontend consumindo o Star Schema perfeito (SSOT)           │
└──────────────────────────────────────────────────────────────┘

```
---

## 🛠️ Stack Tecnológica

| Componente | Ferramenta |
| :--- | :--- |
| **Ingestão** | `Python (gdown, os)` |
| **Transformação (Silver)** | `Pandas` |
| **Data Warehouse / Engine** | `DuckDB` |
| **Transformação (Gold)** | `SQL` |
| **Orquestração** | `Apache Airflow` |
| **Dashboard** | `Power BI` |

---

## 💡 Soluções de Engenharia (Destaques)
* **Ingestão Autônoma:** Diferente de processos que dependem de arquivos previamente baixados, este pipeline inicia com o download automático dos dados brutos através de um script especializado, garantindo que o fluxo seja end-to-end desde o primeiro segundo.
* **Checkpoints Físicos e Controle de Memória:** Para evitar a quebra do pipeline por estouro de memória no XCom do Airflow, implementei uma lógica de checkpoints físicos. O Airflow orquestra as tarefas passando apenas os *caminhos dos arquivos* processados, enquanto os dados reais são persistidos em disco a cada etapa, garantindo resiliência e estabilidade.
* **Construção de DW via Código com DuckDB:** Aproveitei a experiência anterior com o DuckDB para construir um Data Warehouse in-process hiper-otimizado. A modelagem Star Schema foi implementada 100% via SQL, garantindo a idempotência através de lógicas de tratamento de conflitos e materialização de views analíticas prontas para o consumo.
* **Single Source of Truth (SSOT):** Toda a inteligência de negócio foi centralizada no backend. Cálculos como Lucro Bruto e margens por categoria foram resolvidos na camada SQL, transformando o dashboard em uma camada de leitura leve e desacoplada, o que facilita a portabilidade para outras ferramentas de visualização sem perda de lógica.

---

## 🚀 Como Executar Localmente

**Pré-requisitos:** Docker Desktop e Astro CLI.

1. **Clone o repositório:**
   ```bash
   git clone [https://github.com/rushinolk/electronics-sales-pipeline.git](https://github.com/rushinolk/electronics-sales-pipeline.git)
   cd electronics-sales-pipeline
   ```

2. **Inicie a Orquestração (Airflow):**
   ```bash
    astro dev start
   ```

3. **Execute o Pipeline:**
   Acesse `http://localhost:8080` (admin/admin), ative a DAG `electronics_sales_etl` e acompanhe o processamento das camadas Bronze, Silver e Gold.

4. **Visualize os Resultados:**
   Os arquivos finais em formato CSV/Parquet estarão disponíveis na pasta `data/gold`, prontos para serem carregados no Power BI ou qualquer ferramenta analítica.

---
### 👨‍💻 Autor
**Arthur Machado Gomes**
* [LinkedIn](https://www.linkedin.com/in/arthur-gomes1/)
* [GitHub](https://github.com/rushinolk)
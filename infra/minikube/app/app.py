import os, time, logging, psycopg2
from psycopg2 import OperationalError


def connect_db():
    # 從 K8s ConfigMap 與 Secret 注入的環境變數讀取配置
    dbname = os.getenv('DB_NAME', 'myapp')
    user = os.getenv('DB_USER', 'postgres')
    password = os.getenv('DB_PASSWORD', 'password123')
    host = os.getenv('DB_HOST', 'postgres-service')  # K8s Service Name
    port = os.getenv('DB_PORT', '5432')

    logging.warning(f'--- 嘗試連線至資料庫: {host} ---')

    while True:
        try:
            conn = psycopg2.connect(
                dbname=dbname,
                user=user,
                password=password,
                host=host,
                port=port,
                connect_timeout=5
            )
            logging.warning('Successfully connected to PostgreSQL!')

            # 執行簡單測試查詢
            cur = conn.cursor()
            cur.execute('SELECT version();')
            record = cur.fetchone()
            logging.warning(f'PostgreSQL Version: {record}')

            cur.close()
            conn.close()
            logging.warning('Connection test passed. Sleeping for 10s...')
            time.sleep(10)  # 保持 Pod 運行，方便你進去查看狀態

        except OperationalError as e:
            logging.error(f' Retrying in 5 seconds...', exc_info=True)
            time.sleep(5)


if __name__ == '__main__':
    connect_db()
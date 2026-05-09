import os, time, logging, psycopg2
from psycopg2 import OperationalError

SLEEP_TIME = 2

def connect_db():
    # TODO 從 K8s ConfigMap 與 Secret 注入的環境變數讀取配置
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
            logging.warning('✅ Successfully connected to PostgreSQL!')

            cur = conn.cursor()
            cur.execute('SELECT version();')
            record = cur.fetchone()
            logging.warning(f'  - PostgreSQL Version: {record}')
            cur.close()
            conn.close()

            logging.warning(f'  - Connection test passed.')
            logging.warning(f'  - Sleeping for {SLEEP_TIME}s...\n\n')
            time.sleep(SLEEP_TIME)

        except OperationalError as e:
            logging.error(f'⚠️ Retrying in {SLEEP_TIME} seconds...', exc_info=True)
            time.sleep(SLEEP_TIME)


if __name__ == '__main__':
    connect_db()
#!/bin/bash

# 1.　一次性校正為目前使用者的權限，確保能夠從 Windows 路徑複製檔案
sudo chown -R $USER:$USER ~/OLTP-OLAP-Unified-DB/docker/airflow

# 2.　從 Windows 路徑複製 DAGs 到 Airflow 容器的對應資料夾
cp -ra /mnt/c/Users/PC/Code/Python/Publish-To-Git/OLTP-OLAP-Unified-DB/dags ~/OLTP-OLAP-Unified-DB/docker/airflow

# 3. 校正為 Airflow 容器需要的權限
sudo chown -R 50000:0 ~/OLTP-OLAP-Unified-DB/docker/airflow
sudo chmod -R 775 ~/OLTP-OLAP-Unified-DB/docker/airflow

echo "✅ DAGs 同步完成並已校正權限 !"
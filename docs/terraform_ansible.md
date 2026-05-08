## *Terraform & Ansible*
```
# Terraform : 負責蓋房子 ( 基礎設施 )
# Ansible : 負責裝潢與佈置 ( 設定檔與應用邏輯 )
```

### *A.　安裝 Terraform*
```
sudo snap install terraform --classic

# return: terraform 1.14.8 from Snapcrafters✪ installed
# 確認安裝成功否: terraform -v
```

<br>

### *~~[ Some Problem ] B.　接管既有服務~~*
```
# 語法：terraform import <資源類型>.<資源名稱> <Docker容器ID或名稱>

docker ps --filter "name=pg-cluster-prometheus-1" --format "{{.ID}}"
terraform import docker_container.prometheus 4468de5345db

terraform import docker_container.grafana pg-cluster-grafana-1
```

<br>

### *C.　確認 Compose 產生的容器標籤，讓 Terraform 欺騙 Docker Compose 的管理機制！*
```
# sudo snap install jq
docker inspect pg-cluster-dev-db-1 --format '{{json .Config.Labels}}' | jq
```

<br>

### *D.　實際玩法*
```
# 進入 terraform 並初始化
terraform init

# 檢視是否有異動
terraform plan

# 確認異動並決定是否復原
terraform apply # 須人為輸入'yes'
terraform apply -auto-approve # 跳過確認環節，直接執行

# 關閉所有已被定義的宣告物件 ( 容器 + 網路 )
terraform destroy -auto-approve

# Terraform 如何自動理清這些模組間的依賴關係
terraform graph

# 測試內容方式
1. terraform console
2. module.monitoring_services.module.generic_worker.docker_container.this["prometheus"].command

# 基於動態參數調整並重啟服務
ansible-playbook -i inventory.ini playbook.yml

# 手動強制觸發情境 (for tags=reload)
ansible-playbook deploy_config.yml --tags reload

# 讓 ansible 指令可以識別 community.docker
# 等同 python 的 pip install ...
ansible-galaxy collection install community.docker
```

<br>
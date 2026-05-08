MAIN_NAME = pg-cluster

COMPOSE_DIR = ./docker-compose.yaml
TERRAFORM_DIR = ./terraform
ANSIBLE_DIR = ./ansible
AIRFLOW_DIR = ./docker/airflow
IoT_DIR = ./docker/iot-platform

SERVICE_PATH = 127.0.0.1
KAFKA_CONN_ALL_JSON := $(wildcard ./docker/iot-platform/config/connectors/source/*.json ./docker/iot-platform/config/connectors/sink/*.json)
TOPIC_FILTER := __consumer_offsets|docker-connect-configs|docker-connect-offsets|docker-connect-status
SCHEMA_FILTER := template

ALL_COMPOSE := $(wildcard ./docker/*/*-compose.yaml ./docker/*/*-compose.yml)

SUB_SERVICES = ./docker/airflow/docker-compose.yaml \
			   ./docker/monitoring/docker-compose.yaml \
			   ./docker/portainer/docker-compose.yaml \
			   ./docker/postgresql/docker-compose.yaml \
			   ./docker/iot-platform/mqtt-compose.yaml \
			   ./docker/iot-platform/kafka-compose.yaml

AIRFLOW_CONTENT = airflow-webserver airflow-scheduler airflow-worker airflow-triggerer redis
MONITORING_CONTENT = grafana prometheus node_exporter postgres_exporter
POSTGRESQL_CONTENT = common-db pgadmin
PORTAINER_CONTENT = portainer
MQTT_CONTENT = mqtt
KAFKA_CONTENT = kafka kafka-connect kafka-ui schema-registry
ELK_CONTENT = elasticsearch logstash kibana

.PHONY: build up down down-v ps rm \
fix-sock db-wait list-configs prune get-chown-all dev-mode prod-mode kafka-chow \
airflow monitoring portainer postgresql mqtt kafka \
setup config infra all destroy graph \
kafka-connect-create kafka-connect-upsert kafka-connect-status \
kafka-connect-clean kafka-topic-clean kafka-schema-clean kafka-all-clean

init:
	@echo "* 進行特定服務 init"
	@echo "[1.1] 正在建立 Airflow 必要目錄 ..."
	mkdir -p $(AIRFLOW_DIR)/config $(AIRFLOW_DIR)/dags $(AIRFLOW_DIR)/logs $(AIRFLOW_DIR)/plugins
	@echo "[1.2] 修正 Airflow 目錄權限, 讓目錄及其子目錄歸屬給 UID 50000 + 確保權限足夠 (rwxr-xr-x)"
	@make prod-mode
	@echo "[1.3] 執行 Airflow 資料庫初始化 ..."
	docker compose -f $(COMPOSE_DIR) up airflow-init

	@echo "[2] 建立 iot-platform 網路"
	docker network inspect pg-cluster_iot_network >/dev/null 2>&1 || \
    docker network create pg-cluster_iot_network

	@echo "[3] 環境預熱完成 ..."

build:
	@echo "* 進行特定服務 build (no-cache)..."
	docker compose -f ./docker/postgresql/docker-compose.yaml build --no-cache
	docker compose -f ./docker/iot-platform/kafka-compose.yaml build --no-cache

up: fix-sock db-wait copy-dag
	@echo "* Notice | 指定單一服務指令 | ex: docker compose -f ./docker-compose.yaml up -d grafana"
	@echo "* Notice | 只針對 Airflow Webserver 更新設定 | ex: docker compose -f ./docker-compose.yaml up -d --no-deps airflow-webserver"
	docker compose -p $(MAIN_NAME) -f $(COMPOSE_DIR) up -d --no-recreate
	@echo "* 啟動完成 ..."

down:
	# 使用 -p 指定專案名稱，或者使用 -f 指定總控檔案
	docker compose -p $(MAIN_NAME) down --remove-orphans

down-v:
	# 使用 -p 指定專案名稱，或者使用 -f 指定總控檔案
	docker compose -p $(MAIN_NAME) down --remove-orphans -v

ps:
	# ! 不使用 | docker compose -p $(MAIN_NAME) ps | -p 指定專案名稱，或 -f 指定總控檔案
	@echo "* 正在搜尋名稱包含 $(MAIN_NAME) 的容器..."
	#docker ps -a --filter "name=$(MAIN_NAME)"
	docker ps -a --filter "name=$(MAIN_NAME)" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

fix-sock:
	sudo chmod 666 /var/run/docker.sock

db-wait:
	@echo "1. 正在啟動資料庫 ..."
	docker compose -f $(COMPOSE_DIR) up -d common-db --no-recreate
	@echo "2. 等待資料庫就緒 ..."
	sleep 10

list-configs:
	@echo "偵測到的子服務設定檔如下："
	@echo "$(ALL_COMPOSE)" | tr ' ' '\n'

prune:
	@echo "清理 build cache + container + image + network + volume"
	docker system prune -a --volumes -f

get-chown-all:
	@echo "回收所有專案權至 $$(whoami)..."
	sudo chown -R $$(whoami):$$(whoami) .

dev-mode:
	@echo "開發模式：IDE 編輯時把權限拿回來"
	sudo chown -R $$(whoami):$$(whoami) $(AIRFLOW_DIR)

prod-mode:
	@echo "運行模式：把權限交還給 Airflow"
	sudo chown -R 50000:0 $(AIRFLOW_DIR)
	sudo chmod -R 775 $(AIRFLOW_DIR)

#kafka-chown:
#	@echo "設定 kafka 擁有顯式持久化資料權限"
#	mkdir -p $(IoT_DIR)/data/kafka_data
#	sudo chown -R 1000:0 $(IoT_DIR)/data/kafka_data
#	sudo chmod -R 775 $(IoT_DIR)/data/kafka_data

copy-dag:
	@echo "將開發 DAGs 複製到 Airflow 容器中的 DAGs 對應資料夾 | 先刪除目錄下所有內容 | 執行複製"
	@make dev-mode
	sudo rm -rf $(AIRFLOW_DIR)/dags/*
	cp -ra ../dags $(AIRFLOW_DIR)
	@make prod-mode
	@echo "DAGs 同步完成並已校正權限 ..."

airflow: fix-sock copy-dag
	@echo "重新啟動 Airflow 相關服務"
	docker compose -f $(COMPOSE_DIR) down $(AIRFLOW_CONTENT) --remove-orphans
	docker compose -f $(COMPOSE_DIR) up -d $(AIRFLOW_CONTENT)

monitoring: fix-sock
	@echo "重新啟動 Monitoring 相關服務"
	docker compose -f $(COMPOSE_DIR) down $(MONITORING_CONTENT) --remove-orphans
	docker compose -f $(COMPOSE_DIR) up -d $(MONITORING_CONTENT)

postgresql: fix-sock
	@echo "重新啟動 Postgresql 相關服務"
	docker compose -f $(COMPOSE_DIR) down $(POSTGRESQL_CONTENT) --remove-orphans
	docker compose -f $(COMPOSE_DIR) up -d $(POSTGRESQL_CONTENT)

portainer: fix-sock
	@echo "重新啟動 Portainer 相關服務"
	docker compose -f $(COMPOSE_DIR) down $(PORTAINER_CONTENT) --remove-orphans
	docker compose -f $(COMPOSE_DIR) up -d $(PORTAINER_CONTENT)

mqtt: fix-sock
	@echo "重新啟動 MQTT 相關服務"
	docker compose -f $(COMPOSE_DIR) down $(MQTT_CONTENT) --remove-orphans
	docker compose -f $(COMPOSE_DIR) up -d $(MQTT_CONTENT)

kafka: fix-sock
	@echo "重新啟動 Kafka 相關服務"
	@#make kafka-chown
	docker compose -f $(COMPOSE_DIR) down $(KAFKA_CONTENT) --remove-orphans
	docker compose -f $(COMPOSE_DIR) up -d $(KAFKA_CONTENT)

elk: fix-sock
	@echo "重新啟動 ELK 相關服務"
	docker compose -f $(COMPOSE_DIR) down $(ELK_CONTENT) --remove-orphans
	docker compose -f $(COMPOSE_DIR) up -d $(ELK_CONTENT)

refresh: fix-sock
	@echo "1. 檢查是否有定義 container 且不為空"
	@if [ -z "$(container)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make refresh container=airflow-webserver"; \
		exit 1; \
	fi
	@echo "2. 更新單一服務 $(container) | 強制砍並重開 | 完全不動其他關聯服務"
	docker compose -f $(COMPOSE_DIR) up -d --force-recreate --no-deps $(container)

rm:
	@echo "* 正在檢查並清理指定的容器..."
	@echo "1. 檢查是否有定義 container 且不為空"
	@if [ -z "$(container)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make rm container=airflow-webserver"; \
		exit 1; \
	fi
	@if [ $$(docker ps -a -q -f name=$(container)) ]; then \
		echo "2.1 偵測到容器，正在執行強制刪除..."; \
		docker rm -f $(container); \
	else \
		echo "2.2 容器不存在，跳過刪除動作"; \
	fi
	@echo "3. 當前集群狀態"
	@make ps

setup:
	@echo "* Initializing Infrastructure ..."
	cd $(TERRAFORM_DIR) && terraform init
	ansible-galaxy collection install community.docker

infra:
	@echo "* Terraform: Deploying Infrastructure ..."
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

config:
	@echo "* Ansible: Applying Configurations ..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini playbook.yml

reload:
	@echo "* Ansible: Applying Configurations ..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini playbook.yml --tags reload

all: infra config
	@echo "* 依賴 Terraform + Ansible 服務全部啟動 ..."

destroy:
	@echo "* Terraform: Destroy Infrastructure ..."
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

graph:
	@echo "* 顯示 Terraform 如何理清模組間依賴關係 ..."
	cd $(TERRAFORM_DIR) && terraform graph

kafka-connect-create:
	@echo "* 根據指定路徑將 Kafka Connection 進行創建設定 ..."
	@for file in $(KAFKA_CONN_ALL_JSON); do \
  		NAME=$$(basename $$file .json); \
		echo "\n# 上傳配置: $$NAME"; \
		curl -s -X POST -H "Content-Type: application/json" \
			--data @$$file \
			http://$(SERVICE_PATH):8083/connectors; \
		echo "\n\n----------------------------------------"; \
	done
	sleep 3
	@echo "\n\n";
	@make kafka-connect-status

kafka-connect-upsert:
	@echo "* 依據指定路徑將 Kafka Connection 進行同步配置 ..."
	@for file in $(KAFKA_CONN_ALL_JSON); do \
		NAME=$$(basename $$file .json); \
		echo "\n# 上傳/同步配置: $$NAME"; \
		cat $$file | jq '.config' | curl -s -X PUT -H "Content-Type: application/json" \
			--data @- \
			http://$(SERVICE_PATH):8083/connectors/$$NAME/config; \
		echo "\n\n----------------------------------------"; \
	done
	sleep 3
	@echo "\n\n";
	@make kafka-connect-status

kafka-connect-status:
	@echo "* 當前 Kafka Connection 運作狀態"
	@for name in $$(curl -s http://$(SERVICE_PATH):8083/connectors | jq -r '.[]'); do \
		STATE=$$(curl -s http://$(SERVICE_PATH):8083/connectors/$$name/status | jq -r '.tasks[0].state // "N/A"'); \
		echo "    # Connector: [ $$name ] -> Status: [ $$STATE ]"; \
	done

kafka-connect-clean:
	@echo "* 移除所有 Kafka Connection 設定 ..."
	@curl -s http://localhost:8083/connectors | jq -r '.[]' | xargs -I {} curl -s -X DELETE http://localhost:8083/connectors/{}
	sleep 3
	@echo "\n\n";
	@make kafka-connect-status

kafka-topic-clean:
	@echo "* 移除指定 Kafka Topics (過濾條件: $(TOPIC_FILTER)) ..."
	@docker exec pg-cluster-kafka-1 kafka-topics --bootstrap-server $(SERVICE_PATH):9092 --list | grep -vE "$(TOPIC_FILTER)" | while read -r topic; do \
		echo "  -> 物理刪除 Topic: $$topic"; \
		docker exec pg-cluster-kafka-1 kafka-topics --bootstrap-server $(SERVICE_PATH):9092 --delete --topic $$topic; \
	done

kafka-schema-clean:
	@echo "* 移除指定 Schema Registry Subjects (過濾條件: $(SCHEMA_FILTER)) ..."
	@curl -s http://$(SERVICE_PATH):8081/subjects | jq -r '.[]' | grep -vE "$(SCHEMA_FILTER)" | while read -r subject; do \
		echo "  -> 銷毀 Schema: $$subject"; \
		curl -s -X DELETE http://$(SERVICE_PATH):8081/subjects/$$subject; \
	done

kafka-all-clean:
	@echo "* 將 kafka 一系列 [topic / sink / source / schema registry] 徹底清乾淨 ..."
	@echo "* [1/3] 正在清理 Kafka Connectors ..."
	@make kafka-connect-clean
	@echo "\n\n";
	@echo "* [2/3] 正在清理 Kafka Topics ..."
	@make kafka-topic-clean
	@echo "\n\n";
	@echo "* [3/3] 正在清理 Schema Registry Subjects ..."
	@make kafka-schema-clean
	@echo "\n\n✅ 所有的狀態已重置"
RELEASE_NAME=my-dev-release
CHART_PATH=./helm/app-stack
VALUES_PATH=./helm/app-stack/values-dev.yaml
ANSIBLE_INI_PATH=./ansible/inventory.ini
ANSIBLE_SCRIPTS_PATH=./ansible/playbooks

.PHONY: test_clean rollback deploy clean build \
status power_manage init apply destroy label_nodes load_images save

app ?= 1

save:
	@echo "* 導出映像檔至 $(TAR_FILE)"
	@if [ -z "$(IMAGE_NAME)" ]; then \
		echo "Error: 必須指定 IMAGE_NAME，ex: make save IMAGE_NAME=my-python-app TAG=v5 TAR_FILE=my-python-app.tar"; \
		exit 1; \
	fi
	@if [ -z "$(TAG)" ]; then \
		echo "Error: 必須指定 TAG，ex: make save IMAGE_NAME=my-python-app TAG=v5 TAR_FILE=my-python-app.tar"; \
		exit 1; \
	fi
	@if [ -z "$(TAR_FILE)" ]; then \
		echo "Error: 必須指定 TAR_FILE，ex: make save IMAGE_NAME=my-python-app TAG=v5 TAR_FILE=my-python-app.tar"; \
		exit 1; \
	fi
	docker save $(IMAGE_NAME):$(TAG) > $(TAR_FILE)

load_images:
	@if [ -z "$(TAR_FILE)" ]; then \
		echo "Error: 必須指定 TAR_FILE，ex: make load_images TAR_FILE=my-python-app.tar"; \
		exit 1; \
	fi
	@for ip in $$(kubectl get nodes -l service-type=app -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'); do \
		echo "--------------------------------------------------"; \
		echo "* 處理節點: $$ip"; \
		echo "* 正在傳輸 $(TAR_FILE)..."; \
		scp $(TAR_FILE) debian@$$ip:~; \
		echo "* 正在匯入至 K3s containerd..."; \
		ssh debian@$$ip "sudo k3s ctr images import ~/$(TAR_FILE)"; \
		echo "* 清理遠端臨時檔案..."; \
		ssh debian@$$ip "rm ~/$(TAR_FILE)"; \
	done
	@echo "* 移除本地 $(TAR_FILE)"
	rm $(TAR_FILE)
	@echo "✅  <make load_images> done."

label_nodes:
	@echo "* 動態指定服務標籤配置 | make label_nodes app=$(app)"
	@# 1. 處理 Master (k3s-node-0)
	kubectl label nodes k3s-node-0 service-type=none --overwrite
	@# 2. 遍歷其餘節點
	@nodes=$$(kubectl get nodes --no-headers -o custom-columns=":metadata.name" | grep -v "k3s-node-0"); \
	count=1; \
	for node in $$nodes; do \
		if [ $$count -le $(app) ]; then \
			echo "Labeling $$node as app"; \
			kubectl label nodes $$node service-type=app --overwrite; \
		else \
			echo "Labeling $$node as service"; \
			kubectl label nodes $$node service-type=service --overwrite; \
		fi; \
		count=$$((count + 1)); \
	done
	@echo "\n* 檢查標籤結果："
	kubectl get nodes -L service-type
	@echo "✅  <make label_nodes> done."

init:
	@echo "* 初始化 terraform 配置"
	cd terraform && \
	terraform init --upgrade
	@echo "✅  <make init> done."

apply:
	@echo "* 安裝 VM 環境"
	cd terraform && \
	terraform apply -auto-approve
	@echo "✅  <make apply> done."

destroy:
	@echo "* 拆除 VM 環境"
	cd terraform && \
	terraform destroy -auto-approve
	@echo "✅  <make destroy> done."

status:
	@echo "* 檢查 k8s 狀態"
	kubectl get nodes -o wide
	kubectl get pods -o wide

power_manage:
	@echo "* 電源管理 action = [stop / reboot]"
	@echo "* 檢查是否有傳入 action 且不為空"
	@if [ -z "$(action)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make power_manage action=stop"; \
		exit 1; \
	fi
	ansible-playbook -i $(ANSIBLE_INI_PATH) $(ANSIBLE_SCRIPTS_PATH)/power_manage.yml -e "action=$(action)" -K
	@echo "✅  <make power_manage> done."

test_clean:
	# 1. 停止 systemd 服務 (如果存在)
	-sudo systemctl stop k3s

	# 2. 執行官方徹底清理腳本 (會處理掛載點、網路介面與檔案)
	-if [ -f /usr/local/bin/k3s-killall.sh ]; then sudo /usr/local/bin/k3s-killall.sh; fi

	# 3. 強制殺掉殘留的 containerd 進程 (K3s 內嵌版)
	-sudo pkill -9 k3s
	-sudo pkill -9 containerd
	-sudo pkill -9 k3s-agent

	# 4. 清理殘留的網路虛擬介面 (避免下次啟動網路衝突)
	-sudo ip link delete cni0
	-sudo ip link delete flannel.1

	@echo "✅ K3s 環境已徹底清理完畢"

build:
	@echo "1. 檢查是否有版本號且不為空"
	@if [ -z "$(ver)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make build ver=v1"; \
		exit 1; \
	fi
	@echo "* 2. 進入 app 目錄"
	cd app && \
	echo "* 3. Build Dockerfile" && \
	docker build -t my-python-app:$(ver) -f ./dockerfile/Dockerfile.app . --no-cache && \
	echo "* 4. Build Done" && \
	docker images | grep my-python-app
	@echo "✅  <make build> done."

clean:
	@echo "* 徹底清除"
	@echo "1. 正在移除 Helm Release"
	helm uninstall $(RELEASE_NAME) || true
	@echo "2. 正在強制移除所有殘留資源 (ConfigMap/Secret/PVC)"
	helm uninstall my-dev-release || true
	kubectl delete configmap app-config --ignore-not-found
	kubectl delete secret db-secret --ignore-not-found
	kubectl delete pvc --all --ignore-not-found
	kubectl delete cm,deployment,service,ingress --all
	@echo "✅  <make clean> done."

deploy:
	@echo "1. 檢查是否有版本號且不為空"
	@if [ -z "$(ver)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make deploy ver=v1"; \
		exit 1; \
	fi

	@# 如果沒有傳入 msg，就用預設訊息
	$(eval MSG=$(if $(msg),"$(msg)","Deploy version $(ver)"))

	@echo "* 僅安裝/更新 (不清理), changeCause: $(msg)"
	helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) \
 		-f $(VALUES_PATH) \
		--set image.tag=$(ver) \
		--set 'annotations.changeCause=$(MSG)'
	@echo "✅  <make deploy> done."

rollback:
	@echo "1. 檢查是否有版本號且不為空"
	@if [ -z "$(ver)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make redeploy ver=v1"; \
		exit 1; \
	fi
	@echo "* 當前設定錯誤 => 進行回滾"
	helm rollback $(RELEASE_NAME) $(ver)
	@echo "✅  <make rollback> done."
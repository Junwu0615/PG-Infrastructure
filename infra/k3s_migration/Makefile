RELEASE_NAME=pg-service-release
CHART_PATH=./helm/app-stack
VALUES_PATH=./helm/app-stack/values-dev.yaml
TERRAFORM_PATH=./bootstrap/terraform
ANSIBLE_INI_PATH=./bootstrap/ansible/inventory.ini
ANSIBLE_SCRIPTS_PATH=./bootstrap/ansible/playbooks

.PHONY: rollback deploy clean build \
load-images save \
status power-manage init apply destroy label-nodes vm_format \
init-gitops


init-gitops:
	@echo "* 一鍵部署基礎設置 ( GitOps )"

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

load-images:
	@if [ -z "$(TAR_FILE)" ]; then \
		echo "Error: 必須指定 TAR_FILE，ex: make load-images TAR_FILE=my-python-app.tar"; \
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
	@echo "✅  <make load-images> done."

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

label-nodes:
	@echo "* 動態指定服務標籤配置 | infra-data=$(infra-data) infra-tools=$(infra-tools)"
	@# 使用 bash 執行整段腳本，避免 /bin/sh 的相容性問題
	@bash -c ' \
		echo "-> 清除 Master 節點配置"; \
		kubectl label nodes k3s-node-0 service-type=none --overwrite; \
		kubectl cordon k3s-node-0; \
		\
		nodes=$$(kubectl get nodes --no-headers -o custom-columns=":metadata.name" | grep -v "k3s-node-0"); \
		\
		for node in $$nodes; do \
			echo "Clearing labels on $$node"; \
			kubectl label nodes $$node service-type- infra-data- infra-tools- --overwrite >/dev/null; \
		done; \
		\
		i=0; \
		node_list=($$nodes); \
		total=$${#node_list[@]}; \
		\
		for node in "$${node_list[@]}"; do \
			if [ $$i -lt $(infra-data) ]; then \
				echo "Labeling $$node as infra-data"; \
				kubectl label nodes $$node service-type=infra-data --overwrite; \
			elif [ $$i -lt $$(( $(infra-data) + $(infra-tools) )) ]; then \
				echo "Labeling $$node as infra-tools"; \
				kubectl label nodes $$node service-type=infra-tools --overwrite; \
			else \
				echo "Labeling $$node as general"; \
				kubectl label nodes $$node service-type=general --overwrite; \
			fi; \
			i=$$((i + 1)); \
		done'
	@echo "\n* 檢查標籤結果："
	@kubectl get nodes -L service-type
	@echo "✅ <make label-nodes> done."

init:
	@echo "* 初始化 terraform 配置"
	cd $(TERRAFORM_PATH) && \
	terraform init --upgrade
	@echo "✅  <make init> done."

apply:
	@echo "* 安裝 VM 環境"
	cd $(TERRAFORM_PATH) && \
	terraform apply -auto-approve -var="VAR_FILE=$(VAR_FILE)" \
	@echo "✅  <make apply> done."

destroy:
	@echo "* 拆除 VM 環境"
	cd $(TERRAFORM_PATH) && \
	terraform destroy -auto-approve
	@echo "✅  <make destroy> done."

status:
	@echo "* 檢查 k8s 狀態"
	kubectl get nodes -o wide
	kubectl get pods -o wide

power-manage:
	@echo "* 電源管理 action = [stop / reboot]"
	@echo "* 檢查是否有傳入 action 且不為空"
	@if [ -z "$(action)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make power-manage action=stop"; \
		exit 1; \
	fi
	ansible-playbook -i $(ANSIBLE_INI_PATH) $(ANSIBLE_SCRIPTS_PATH)/power_manage.yml -e "action=$(action)" -K
	@echo "✅  <make power-manage> done."

vm_format:
	@for vm in $$(sudo virsh list --all --name); do \
		if [ -n "$$vm" ]; then \
			echo "=== 虛擬機: $$vm ==="; \
			vcpu=$$(sudo virsh dumpxml "$$vm" | grep 'vcpu' | sed -e 's/<[^>]*>//g' | xargs); \
			ram_kib=$$(sudo virsh dumpxml "$$vm" | grep 'currentMemory' | sed -e 's/<[^>]*>//g' | xargs); \
			ram_mb=$$((ram_kib / 1024)); \
			disk_path=$$(sudo virsh domblklist "$$vm" | awk 'NR==3 {print $$2}'); \
			if [ -f "$$disk_path" ]; then \
				disk_size=$$(sudo qemu-img info "$$disk_path" | grep 'virtual size' | awk -F'(' '{print $$1}' | awk -F':' '{print $$2}' | xargs); \
			else \
				disk_size="找不到實體磁碟"; \
			fi; \
			echo "  [CPU]  : $$vcpu 核"; \
			echo "  [RAM]  : $$ram_mb MB (~ $$((ram_mb / 1024)) GB)"; \
			echo "  [DISK] : $$disk_size"; \
		fi; \
	done
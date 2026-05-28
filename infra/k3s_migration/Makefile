RELEASE_NAME=pg-service-release
CHART_PATH=./helm/app-stack
VALUES_PATH=./helm/app-stack/values-dev.yaml
TERRAFORM_PATH=./bootstrap/terraform
ANSIBLE_INI_PATH=./bootstrap/ansible/inventory.ini
ANSIBLE_SCRIPTS_PATH=./bootstrap/ansible/playbooks

.PHONY: rollback deploy clean build \
status init apply destroy terraform-list label-nodes vm-format vm-power \
load-images save \
init-gitops


init-gitops:
	@echo "* 一鍵部署基礎設置 ( GitOps Bootstrap Cluster )"
	cd ./infra-live/bootstrap/ && \
	chmod +x cluster/scripts/bootstrap-cluster.sh && \
	./cluster/scripts/bootstrap-cluster.sh

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

init:
	@echo "* 初始化 terraform 配置"
	cd $(TERRAFORM_PATH) && \
	terraform init --upgrade
	@echo "✅  <make init> done."

apply:
	@echo "* 安裝 VM 環境"
	cd $(TERRAFORM_PATH) && \
	terraform apply -auto-approve -var-file="$(VAR_FILE)"
	@echo "✅  <make apply> done."

destroy:
	@echo "* 拆除 VM 環境"
	cd $(TERRAFORM_PATH) && \
	terraform destroy -auto-approve
	@echo "✅  <make destroy> done."

terraform-list:
	@echo "* 確認 Terraform 狀態清單是否缺失"
	cd $(TERRAFORM_PATH) && \
	terraform state list
	@echo "✅  <make state-list> done."

status:
	@echo "* 檢查 k8s 狀態"
	kubectl get nodes -o wide
	kubectl get pods -o wide

vm-power:
	@echo "* VM Power action = [start / stop / reboot / status / force-stop]"

	@if [ -z "$(action)" ]; then \
		echo "Error: ex: make vm-power action=start"; \
		exit 1; \
	fi

	@bash scripts/vm-power.sh $(action)

	@echo "✅  <make vm-power> done."

vm-format:
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
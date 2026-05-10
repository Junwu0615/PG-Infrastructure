RELEASE_NAME=my-dev-release
CHART_PATH=./helm/app-stack
VALUES_PATH=./helm/app-stack/values-dev.yaml
ANSIBLE_INI_PATH=./ansible/hosts.ini
ANSIBLE_SCRIPTS_PATH=./ansible/scripts


# 找實際位置: Get-ChildItem -Path "C:\Program Files" -Filter VBoxManage.exe -Recurse -ErrorAction SilentlyContinue
VBOX_MANAGE = "/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"


.PHONY: shutdown test_clean rollback deploy clean build \
status cluster_up init_nodes deploy_k3s power_manage

status:
	@echo "* 檢查 k8s 狀態"
	kubectl get nodes -o wide
	#kubectl get pods -A
	kubectl get pods -o wide

cluster_up:
	@echo "* 啟動所有 VM ( 透過呼叫 Windows 宿主機指令 )"
	@echo "1. 正在啟動虛擬機..."
	@$(VBOX_MANAGE) startvm "Master" --type headless
	@$(VBOX_MANAGE) startvm "worker1" --type headless
	@$(VBOX_MANAGE) startvm "worker3" --type headless
	@$(VBOX_MANAGE) startvm "worker4" --type headless
	@echo "2. 等待系統開機與 K3s 就緒 ( 40s )..."
	@sleep 40
	@kubectl get nodes -o wide

init_nodes:
	@echo "* 初始化節點"
	ansible-playbook -i $(ANSIBLE_INI_PATH) $(ANSIBLE_SCRIPTS_PATH)/init_nodes.yml
	@echo "✅ <make init_nodes> done."

deploy_k3s:
	@echo "* 部署 k3s"
	ansible-playbook -i $(ANSIBLE_INI_PATH) $(ANSIBLE_SCRIPTS_PATH)/deploy_k3s.yml
	@echo "✅ <make deploy_k3s> done."

power_manage:
	@echo "* 電源管理 action = [stop / reboot]"
	@echo "* 檢查是否有傳入 action 且不為空"
	@if [ -z "$(action)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make power_manage action=stop"; \
		exit 1; \
	fi
	ansible-playbook -i $(ANSIBLE_INI_PATH) $(ANSIBLE_SCRIPTS_PATH)/power_manage.yml -e "action=$(action)" -K
	@echo "✅ <make power_manage> done."

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
	@echo "✅ <make build> done."

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
	@echo "✅ <make clean> done."

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
	@echo "✅ <make deploy> done."

rollback:
	@echo "1. 檢查是否有版本號且不為空"
	@if [ -z "$(ver)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make redeploy ver=v1"; \
		exit 1; \
	fi
	@echo "* 當前設定錯誤 => 進行回滾"
	helm rollback $(RELEASE_NAME) $(ver)
	@echo "✅ <make rollback> done."
RELEASE_NAME=my-dev-release
CHART_PATH=./helm/app-stack
VALUES_PATH=./helm/app-stack/values-dev.yaml

.PHONY: test_clean rollback deploy clean build


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
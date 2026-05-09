RELEASE_NAME=my-dev-release
CHART_PATH=./helm/app-stack
VALUES_PATH=./helm/app-stack/values-dev.yaml

.PHONY: build clean redeploy

build:
	@echo "1. 檢查是否有版本號且不為空"
	@if [ -z "$(ver)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make build ver=v1"; \
		exit 1; \
	fi
	@echo "* 2. 進入 app 目錄 + 切換環境變數 (minikube)"
	cd app && \
	eval $(minikube docker-env) && \
	echo "* 3. Build Dockerfile" && \
	docker build -t my-python-app:$(ver) -f ./dockerfile/Dockerfile.app . --no-cache && \
	echo "* 4. Build Done" && \
	docker images | grep my-python-app

clean:
	@echo "* 徹底清除"
	@echo "1. 正在移除 Helm Release"
	-helm uninstall $(RELEASE_NAME)
	@echo "2. 正在強制移除所有殘留資源 (ConfigMap/Secret/PVC)"
	-kubectl delete configmap app-config
	-kubectl delete secret db-secret
	-kubectl delete pvc --all
	@echo "* 清理完畢"

deploy:
	@echo "* 僅安裝/更新 (不清理)"
	helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) -f $(VALUES_PATH)

redeploy: clean build
	@echo "* 重新部署中"
	helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) -f $(VALUES_PATH)
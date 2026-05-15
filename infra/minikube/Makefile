RELEASE_NAME=my-dev-release
CHART_PATH=./helm/app-stack
VALUES_PATH=./helm/app-stack/values-dev.yaml

.PHONY: image-load build clean deploy redeploy rollback

image-load:
	@echo "* 本地映像檔傳入虛擬環境"
	minikube image load portainer/portainer-ce:2.21.5
	@echo "✅  <make image-load> done."

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
	@echo "* 僅安裝/更新 (不清理)"
	helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) -f $(VALUES_PATH) --set image.tag=$(ver)
	@echo "✅  <make deploy> done."

redeploy: clean build
	@echo "1. 檢查是否有版本號且不為空"
	@if [ -z "$(ver)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make redeploy ver=v1"; \
		exit 1; \
	fi
	@echo "* 重新部署中"
	helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) -f $(VALUES_PATH) --set image.tag=$(ver)
	@echo "✅  <make redeploy> done."

rollback:
	@echo "1. 檢查是否有版本號且不為空"
	@if [ -z "$(ver)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make redeploy ver=v1"; \
		exit 1; \
	fi
	@echo "* 當前設定錯誤 => 進行回滾"
	helm rollback $(RELEASE_NAME) $(ver)
	@echo "✅  <make rollback> done."

prune:
	@echo "* 清理 build cache + container + image + network + volume"
	eval $(minikube docker-env) && \
	docker system prune -a --volumes -f
	@echo "✅  <make prune> done."


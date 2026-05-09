RELEASE_NAME=my-dev-release
CHART_PATH=./helm/app-stack
VALUES_PATH=./helm/app-stack/values-dev.yaml

.PHONY: image_load test_clean

image_load:
	@echo "* 本地映像檔傳入虛擬環境"
	minikube image load portainer/portainer-ce:2.21.5
	@echo "✅ <make image_load> done."

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
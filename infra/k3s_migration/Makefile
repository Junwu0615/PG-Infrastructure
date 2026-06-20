LINUX_USER := pc

# 需與 terraform 變數設定對齊
IOS_IMAGE := debian-12-generic-amd64.qcow2
DEBIAN_IMAGE_URL = https://cloud.debian.org/images/cloud/bookworm/latest/$(IOS_IMAGE)
OS_IMAGE := debian:12-slim
K3S_VIP  := 10.88.0.99

BOOTSTRAP_DIR        := ./bootstrap
FILES_DIR            := $(BOOTSTRAP_DIR)/files
TERRAFORM_PATH       := $(BOOTSTRAP_DIR)/terraform
ANSIBLE_INI_PATH     := $(BOOTSTRAP_DIR)/ansible/inventory.ini
ANSIBLE_ROOT_PATH    := $(BOOTSTRAP_DIR)/ansible
NFS_DIR              := $(FILES_DIR)/nfs_packages
NFS_SERVER_DIR       := $(FILES_DIR)/nfs_server_packages
ISO_DIR              := $(FILES_DIR)/iso_images
KEEPALIVED_DIR       := $(FILES_DIR)/keepalived_packages
K3S_DIR              := $(FILES_DIR)/k3s_packages
INFRA_LIVE_DIR       := ./infra-live

ALL_CHART_DIRS := \
    $(INFRA_LIVE_DIR)/charts/observability/grafana \
    $(INFRA_LIVE_DIR)/charts/observability/prometheus \
    $(INFRA_LIVE_DIR)/charts/observability/prometheus-stack \
    $(INFRA_LIVE_DIR)/charts/observability/loki \
    $(INFRA_LIVE_DIR)/charts/observability/promtail \
    $(INFRA_LIVE_DIR)/charts/observability/tempo \
    $(INFRA_LIVE_DIR)/charts/databases/postgresql \
    $(INFRA_LIVE_DIR)/charts/platform/ingress-nginx \
    $(INFRA_LIVE_DIR)/charts/platform/registry \
    $(INFRA_LIVE_DIR)/charts/platform/harbor \

FILTER_CHART_DIRS := \
	$(INFRA_LIVE_DIR)/charts/observability/prometheus \
	$(INFRA_LIVE_DIR)/charts/observability/harbor \

CHART_DIRS := $(filter-out $(FILTER_CHART_DIRS), $(ALL_CHART_DIRS))

AnsibleParameters :=
SHELL := /bin/bash

.PHONY: apt-source-prepare apt-source-clean trigger-ansible k9s-fav \
init apply destroy output terraform-list \
status k-top label-nodes vm-format vm-power \
root-app init-gitops helm-chart-build $(CHART_DIRS) upgrade-ingress see-secrets


apt-source-prepare: $(ISO_DIR) $(NFS_DIR) $(NFS_SERVER_DIR) $(KEEPALIVED_DIR) $(K3S_DIR)
	@echo "* 透過 Host 網路模式與容器 (${OS_IMAGE}) 動態下載目標 OS 相容套件 ..."

	# 1. 地端預載 $(IOS_IMAGE) 基礎鏡像
	@if [ -z "$$(ls -A $(ISO_DIR))" ]; then \
	   echo "  🚀 正在下載 $(IOS_IMAGE) Cloud Image ..."; \
	   curl -L $(DEBIAN_IMAGE_URL) -o $(ISO_DIR)/$(IOS_IMAGE); \
	else \
	   echo "  📦 IOS IMAGE 離線套件已存在，跳過 ..."; \
	fi

	# 2. 地端預載 $(OS_IMAGE) 的 NFS 客戶端及其完整相依套件
	@if [ -z "$$(ls -A $(NFS_DIR))" ]; then \
		echo "  🚀 正在下載 $(OS_IMAGE) 相容之 NFS 離線套件 ..."; \
		docker run --rm \
			--network host \
			-v $(shell pwd)/$(NFS_DIR):/download \
			${OS_IMAGE} \
			sh -c "apt-get update && apt-get install -y --download-only nfs-common rpcbind && cp /var/cache/apt/archives/*.deb /download/"; \
	else \
		echo "  📦 NFS 離線套件已存在，跳過 ..."; \
	fi


	# 3. 地端預載 $(OS_IMAGE) 的 NFS 服務端（Server）及其完整相依套件
	@if [ -z "$$(ls -A $(NFS_SERVER_DIR))" ]; then \
	   echo "  🚀 正在下載 $(OS_IMAGE) 相容之 NFS Server 離線套件 ..."; \
	   docker run --rm \
	      --network host \
	      -v $(shell pwd)/$(NFS_SERVER_DIR):/download \
	      ${OS_IMAGE} \
	      sh -c "apt-get update && apt-get install -y --download-only nfs-kernel-server && cp /var/cache/apt/archives/*.deb /download/"; \
	else \
	   echo "  📦 NFS Server 離線套件已存在，跳過 ..."; \
	fi

	# 4. 地端預載 $(OS_IMAGE) 的 Keepalived 及其完整相依套件
	@if [ -z "$$(ls -A $(KEEPALIVED_DIR))" ]; then \
		echo "  🚀 正在下載 $(OS_IMAGE) 相容之 Keepalived 離線套件 ..."; \
		docker run --rm \
			--network host \
			-v $(shell pwd)/$(KEEPALIVED_DIR):/download \
			${OS_IMAGE} \
			sh -c "apt-get update && apt-get install -y --download-only keepalived && cp /var/cache/apt/archives/*.deb /download/"; \
	else \
		echo "  📦 Keepalived 離線套件已存在，跳過 ..."; \
	fi

	# 5. 地端預載 K3s 離線安裝腳本與二進位檔 (以 v1.28.2+k3s1 為例，可自行更換版本)
	@if [ -z "$$(ls -A $(K3S_DIR))" ]; then \
		echo "  🚀 正在下載 K3s 離線安裝資源中 ..."; \
		curl -sfL https://get.k3s.io -o $(K3S_DIR)/install.sh; \
		curl -sfL https://github.com/k3s-io/k3s/releases/download/v1.28.2%2Bk3s1/k3s -o $(K3S_DIR)/k3s; \
		chmod +x $(K3S_DIR)/k3s; \
	else \
		echo "  📦 K3s 離線資源已存在，跳過 ..."; \
	fi

	@echo "✅  <make apt-source-prepare> done."

$(ISO_DIR):
	@echo "* 幕等式創建檔案夾: $(ISO_DIR)"
	mkdir -p $(ISO_DIR)

$(NFS_DIR):
	@echo "* 幕等式創建檔案夾: $(NFS_DIR)"
	mkdir -p $(NFS_DIR)

$(NFS_SERVER_DIR):
	@echo "* 幕等式創建檔案夾: $(NFS_SERVER_DIR)"
	mkdir -p $(NFS_SERVER_DIR)

$(KEEPALIVED_DIR):
	@echo "* 幕等式創建檔案夾: $(KEEPALIVED_DIR)"
	mkdir -p $(KEEPALIVED_DIR)

$(K3S_DIR):
	@echo "* 幕等式創建檔案夾: $(K3S_DIR)"
	mkdir -p $(K3S_DIR)

apt-source-clean:
	@echo "* 進行離線資源快取清理 ..."
	rm -rf $(FILES_DIR)/nfs_packages
	rm -rf $(FILES_DIR)/keepalived_packages
	@echo "✅  <make apt-source-clean> done."

k-top:
	@echo "================== [ 節點資源配額預佔狀態 ] =================="
	@kubectl describe nodes | grep -A 20 "Allocated resources" || true && echo && echo && echo
	@echo "================== [ 叢集硬體算力消耗狀態 ] =================="
	@kubectl top nodes || echo "⚠️ 無法取得指標，請檢查 metrics-server 是否正常運行。"
	@echo "✅  <make k-top> done."

init-gitops:
	@echo "* 一鍵部署基礎設置 ( GitOps Bootstrap Cluster )"
	cd $(INFRA_LIVE_DIR)/bootstrap/ && \
	chmod +x cluster/scripts/bootstrap-cluster.sh && \
	./cluster/scripts/bootstrap-cluster.sh
	@echo "✅  <make init-gitops> done."

helm-chart-build: $(CHART_DIRS)
	@echo "✅  <make helm-chart-build> done."

$(CHART_DIRS):
	@echo "* [Vendor Mode] 動態遍歷建置 Helm (Chart.yaml) 依賴 ▶ $@"
	@\
	# ⚡ 冪等性核心邏輯 1：解析並更新 Repository（相容多依賴宣告） \
	LENGTH=$$(yq eval '.dependencies | length' $@/Chart.yaml 2>/dev/null); \
	if [ -n "$$LENGTH" ] && [ "$$LENGTH" -gt 0 ]; then \
	    for i in $$(seq 0 $$(($$LENGTH - 1))); do \
	        REPO_URL=$$(yq eval ".dependencies[$$i].repository" $@/Chart.yaml 2>/dev/null); \
	        REPO_NAME=$$(yq eval ".dependencies[$$i].name" $@/Chart.yaml 2>/dev/null); \
	        if [ -n "$$REPO_URL" ] && [ "$$REPO_URL" != "null" ] && [[ "$$REPO_URL" == http* ]]; then \
	            echo "* 檢查與更新倉庫: $$REPO_NAME ($$REPO_URL)"; \
	            helm repo add $$REPO_NAME $$REPO_URL --force-update > /dev/null 2>&1; \
	        fi; \
	    done; \
	fi; \
	\
	# ⚡ 冪等性核心邏輯 2：下載依賴到 charts/ 目錄 \
	helm dependency build $@ || { echo "❌ $@ 依賴下載失敗 ..."; exit 1; }; \
	\
	# ⚡ 冪等性核心邏輯 3：解包 .tgz 並清理，將 .tgz 轉換為純原始碼目錄，實踐 Git 追蹤的 Vendor 模式 \
	if [ -d "$@/charts" ]; then \
	    echo "* 正在執行依賴目錄 Vendor 化處理 (解包並清理)..."; \
	    for tgz in $@/charts/*.tgz; do \
	        if [ -f "$$tgz" ]; then \
	            tar -xzf "$$tgz" -C $@/charts/ && rm -f "$$tgz"; \
	        fi; \
	    done; \
	fi; \
	\
	# ⚡ 整合邏輯：安全無塵抽離 CRD，並透過 Server-Side Apply 無痛灌入叢集 \
	echo "* 正在從依賴中提取並過濾所有 CRD..."; \
	CRD_FILE=$$(mktemp /tmp/all-crds-XXXXXX.yaml); \
	trap 'rm -f $$CRD_FILE' EXIT; \
	\
	helm template $@ --include-crds | yq eval 'select(.kind == "CustomResourceDefinition")' - > $$CRD_FILE; \
	\
	if [ -s "$$CRD_FILE" ]; then \
	    echo "* 偵測到 CRD 物件，進行 Server-Side Apply 安全同步..."; \
	    kubectl apply -f $$CRD_FILE --server-side --force-conflicts; \
	else \
	    echo "* ℹ️ 該 Chart 無包含任何 CustomResourceDefinition，跳過"; \
	fi

root-app:
	@echo "🚀 開始同步 GitOps 根應用 (root-app) ..."
	@if [ -z "$(ENV)" ]; then \
		echo "Error: 必須指定 ENV，ex: make root-app ENV=homelab-test"; \
		exit 1; \
	fi
	@echo "🔍 正在檢查基礎設施 Webhook 安全防禦狀態 ..."
	@if kubectl get validatingwebhookconfigurations ingress-nginx-$(ENV)-admission >/dev/null 2>&1; then \
		CABUNDLE=$$(kubectl get validatingwebhookconfigurations ingress-nginx-$(ENV)-admission -o jsonpath='{.webhooks[0].clientConfig.caBundle}' 2>/dev/null); \
		if [ -z "$$CABUNDLE" ]; then \
			echo "⚠️ 偵測到 Nginx Webhook 憑證空白！ 主動清除過渡期空殼（會引發 x509 報錯）"; \
			echo "1. 主動清除過渡期空殼 Webhook，確保 ArgoCD 順暢通行 ..."; \
			kubectl delete validatingwebhookconfigurations \
				$$(kubectl get validatingwebhookconfigurations -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -E 'nginx|prometheus') \
				--ignore-not-found 2>/dev/null || true; \
			echo "2. 強制重新觸發 Helm 自帶的憑證生成 Job ..."; \
			kubectl -n ingress-nginx-$(ENV) create job --from=cronjob/ingress-nginx-$(ENV)-admission-patch admission-patch-manual-$$(date +%s) 2>/dev/null || \
			kubectl get pods -n ingress-nginx-$(ENV) -l app.kubernetes.io/component=admission-webhook -o name | xargs kubectl delete 2>/dev/null || true; \
		else \
			echo "✅ Nginx Webhook 憑證 (caBundle) 已就緒，跳過清理流程。"; \
		fi \
	fi

	@echo "📦 正在套用根入口宣告並開啟自動剪枝 ..."
	@kubectl apply -f "$(INFRA_LIVE_DIR)/argocd/root-app.yaml"
	@kubectl patch application homelab-root -n argocd --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true},"syncOptions":["CreateNamespace=true","ServerSideApply=true","PruneLast=true"]}}}' 2>/dev/null || true

	# refresh=hard 能強制 Argo CD 丟棄 Git 快取，重新解析 Kustomization 的註解開關
	@echo "🔄 強制 Argo CD 丟棄快取並精準對齊 (Hard Refresh) ..."
	@kubectl annotate application homelab-root -n argocd argocd.argoproj.io/refresh=hard --overwrite

	@echo "⏳ 正在執行同步與舊資源剪枝 (Prune) 請稍候 ..."
	@kubectl wait --for=jsonpath='{.status.sync.status}'=Synced application/homelab-root -n argocd --timeout=90s || true

	@echo "✅ <make root-app> done."

upgrade-ingress:
	@echo "* 初始化/更新 ingress-nginx"
	kubectl apply -f "${INFRA_LIVE_DIR}/bootstrap/cluster/ingress-nginx/namespace.yaml"
	helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
	  --namespace ingress-nginx \
	  -f "${INFRA_LIVE_DIR}/bootstrap/cluster/ingress-nginx/values.yaml"
	@echo "✅  <make upgrade-ingress> done."

label-nodes:
	@echo "* 動態初始化/更新 K3s 節點 → 按比例注入群組標籤 ( 親合/反親合/汙點防禦 )" && echo

	# 獲取當前叢集中所有的 Agent 節點清單並排序
	$(eval AGENTS := $(shell kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep 'agent' | sort))
	$(eval AGENT_COUNT := $(shell echo "$(AGENTS)" | wc -w))

	@if [ $(AGENT_COUNT) -eq 0 ]; then \
		echo "❌ 錯誤：叢集中未發現任何 k3s-agent 節點！"; \
		exit 1; \
	fi

	# 計算切分點：一半劃分為前端無狀態，一半劃分為後端有狀態
	$(eval MID_POINT := $(shell echo $$(( ($(AGENT_COUNT) + 1) / 2 )) ))

	@echo && echo "* 當前偵測到 Agent 總數: $(AGENT_COUNT) 台，切分臨界點為第 $(MID_POINT) 台。"
	# 循環遍歷節點，動態計算並打上對應的三大類別標籤
	@INDEX=1; \
	for node in $(AGENTS); do \
		echo "  - 正在處理節點: $$node [$$INDEX/$(AGENT_COUNT)]"; \
		\
		# 所有人都是基礎工作節點 \
		kubectl label nodes $$node node-role.kubernetes.io/worker=worker --overwrite >/dev/null 2>&1; \
		\
		if [ $$INDEX -eq 1 ]; then \
			# 🎯 第一台 Agent 永遠作為最前線的流量守門員 \
			echo "   📍 角色指派 -> [邊緣網關 + 無狀態服務] (Edge Ingress & Stateless)"; \
			kubectl label nodes $$node workload-class=stateless --overwrite >/dev/null 2>&1; \
			kubectl label nodes $$node traffic-zone=edge-ingress --overwrite >/dev/null 2>&1; \
			kubectl label nodes $$node hardware-type- --overwrite >/dev/null 2>&1; \
		elif [ $$INDEX -le $(MID_POINT) ]; then \
			# 🎯 前半段的其他 Agent 作為普通無狀態擴容節點 \
			echo "   📍 角色指派 -> [標準無狀態微服務區] (Stateless)"; \
			kubectl label nodes $$node workload-class=stateless --overwrite >/dev/null 2>&1; \
			kubectl label nodes $$node traffic-zone=internal-only --overwrite >/dev/null 2>&1; \
			kubectl label nodes $$node hardware-type- --overwrite >/dev/null 2>&1; \
		else \
			# 🎯 後半段的 Agent 作為高 I/O 有狀態資料庫專區 \
			echo "   📍 角色指派 -> [高 I/O 有狀態資料庫區] (Stateful & High-IO)"; \
			kubectl label nodes $$node workload-class=stateful --overwrite >/dev/null 2>&1; \
#			kubectl label nodes $$node hardware-type=high-io --overwrite >/dev/null 2>&1; \
			kubectl label nodes $$node hardware-type- --overwrite >/dev/null 2>&1; \
			kubectl label nodes $$node traffic-zone- --overwrite >/dev/null 2>&1; \
		fi; \
		INDEX=$$((INDEX + 1)); \
	done

	@echo && echo && echo " ================== [ 節點專屬維運標籤一覽 ] =================="
	@#kubectl get nodes -l node-role.kubernetes.io/worker=worker -L workload-class -L hardware-type -L traffic-zone
	@kubectl get nodes -L workload-class -L hardware-type -L traffic-zone -L kubernetes.io/hostname

	@echo "✅  <make label-nodes> done."

see-secrets:
	@echo "* 檢視 Secrets 明文 (base64 解碼)" && echo
	@if [ -z "$(ENV)" ]; then \
		echo "Error: 必須指定 ENV，ex: make see-secrets ENV=homelab-test"; \
		exit 1; \
	fi
	@echo "* [1] ArgoCD UI 密碼"
	kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d && echo && echo
	@echo "* [2] Gitlab 連線設置 (url + username + password)"
	kubectl get secret gitlab-repo-secret -n argocd -o jsonpath='{.data.url}' | base64 -d && echo && echo
	kubectl get secret gitlab-repo-secret -n argocd -o jsonpath='{.data.username}' | base64 -d && echo && echo
	kubectl get secret gitlab-repo-secret -n argocd -o jsonpath='{.data.password}' | base64 -d && echo && echo
	@echo "* [3] postgresql-credentials → postgres-password"
	kubectl get secret postgresql-credentials -n postgresql-$(ENV) -o jsonpath="{.data.postgres-password}" | base64 -d && echo && echo
	@echo "* [4] postgresql-credentials → password"
	kubectl get secret postgresql-credentials -n postgresql-$(ENV) -o jsonpath="{.data.password}" | base64 -d && echo && echo
	@echo "* [5] postgresql-credentials → replication-password"
	kubectl get secret postgresql-credentials -n postgresql-$(ENV) -o jsonpath="{.data.replication-password}" | base64 -d && echo && echo
	@#echo "* [6] Grafana UI 密碼"
	#kubectl get secret grafana-$(ENV) -n grafana-$(ENV) -o jsonpath="{.data.adminPassword}" | base64 -d && echo && echo
	@echo "✅  <make see-secrets> done."

k9s-fav:
	@echo "* 初始化/更新 k9s 收藏設定"
	@if [ -z "$(ENV)" ]; then \
		echo "Error: 必須指定 ENV，ex: make k9s-fav ENV=homelab-test"; \
		exit 1; \
	fi
	rm -rf /home/$(LINUX_USER)/.local/share/k9s/clusters/default/
	k9s --kubeconfig ~/.kube/config

	sudo cp ./archive/k9s-fav/$(ENV).yaml ~/.local/share/k9s/clusters/default/default/config.yaml
	cat ~/.local/share/k9s/clusters/default/default/config.yaml

	@echo "✅  <make k9s-fav> done."

init:
	@echo "* [Terraform] 初始化配置"
	cd $(TERRAFORM_PATH) && \
	terraform init --upgrade
	@echo "✅  <make init> done."

apply:
	@echo "* [Terraform] 安裝 VM 環境"
	cd $(TERRAFORM_PATH) && \
	terraform apply -auto-approve -var-file="$(VAR_FILE)"
	@echo "✅  <make apply> done."

destroy:
	@echo "* [Terraform] 拆除 VM 環境"
	cd $(TERRAFORM_PATH) && \
	terraform destroy

	@echo "* 清除 SSH 舊指紋 $(K3S_VIP)"
	ssh-keygen -f '/home/$(LINUX_USER)/.ssh/known_hosts' -R '$(K3S_VIP)'
	@echo "✅  <make destroy> done."

output:
	@echo "* [Terraform] 檢視輸出格式"
	cd $(TERRAFORM_PATH) && \
	terraform output
	@echo "✅  <make output> done."

terraform-list:
	@echo "* [Terraform] 確認狀態清單是否缺失"
	cd $(TERRAFORM_PATH) && \
	terraform state list
	@echo "✅  <make state-list> done."

status:
	@echo "* 檢查 k8s 狀態"
	kubectl get nodes -o wide
	kubectl get pods -A -o wide

trigger-ansible:
	@echo "* 觸發指定 Ansible 腳本 ..."
	@if [ -z "$(Files)" ]; then \
		echo "Error: 必須指定服務名稱，ex: make trigger-ansible Files=[xxx.yml]"; \
		exit 1; \
	fi
	ansible-playbook -i $(ANSIBLE_INI_PATH) $(ANSIBLE_ROOT_PATH)/$(Files) $(AnsibleParameters)
	@echo "✅  <make trigger-ansible yml=$(yml)> done."

vm-power:
	@echo "* VM Power action = [start / stop / reboot / status / force-stop]"

	@if [ -z "$(action)" ]; then \
		echo "Error: ex: make vm-power action=start"; \
		exit 1; \
	fi

	@bash archive/scripts/vm-power.sh $(action)

	@echo "✅  <make vm-power> done."

vm-format:
	@printf "\033[1;36m================== [ KVM 虛擬機算力與配置清單 ] ==================\033[0m\n"
	@printf "\033[1;33m%-15s %-10s %-8s %-15s %-20s\033[0m\n" "VM_NAME" "STATUS" "VCPU" "MEMORY" "DISK_SIZE"
	@printf "\033[1;30m----------------------------------------------------------------\033[0m\n"
	@sudo virsh list --all | tail -n +2  | sort -k 2 | awk 'NR>2 {print $$2}' | while read -r vm; do \
	   if [ -n "$$vm" ]; then \
	      status=$$(sudo virsh domstate "$$vm" 2>/dev/null); \
	      if [ "$$status" = "running" ]; then \
	         status_str="\033[1;32mrunning\033[0m"; \
	      else \
	         status_str="\033[1;31m$$status\033[0m"; \
	      fi; \
	      vcpu=$$(sudo virsh dumpxml "$$vm" 2>/dev/null | grep '<vcpu' | sed -e 's/<[^>]*>//g' | xargs); \
	      ram_kib=$$(sudo virsh dumpxml "$$vm" 2>/dev/null | grep '<currentMemory' | sed -e 's/<[^>]*>//g' | xargs); \
	      ram_gb=$$(echo "scale=1; $$ram_kib / 1024 / 1024" | bc 2>/dev/null); \
	      [ -z "$$vcpu" ] && vcpu="-"; \
	      [ -z "$$ram_gb" ] && ram_str="-" || ram_str="$${ram_gb} GB"; \
	      \
	      disk_path=$$(sudo virsh domblklist "$$vm" | grep -v -E "Target|Source|------|$$" | grep -v "\.iso" | awk '{print $$2}' | head -n 1 | xargs); \
	      \
	      if [ -n "$$disk_path" ] && [ -f "$$disk_path" ]; then \
	         disk_size=$$(sudo qemu-img info "$$disk_path" 2>/dev/null | grep 'virtual size' | awk -F'(' '{print $$1}' | awk -F':' '{print $$2}' | xargs); \
	      elif [ -n "$$disk_path" ]; then \
	         disk_size="$$disk_path"; \
	      else \
	         disk_size="無實體磁碟"; \
	      fi; \
	      printf "%-15s %b %-8s %-15s %-20s\n" "$$vm" "$$status_str" "    $$vcpu 核" "    $$ram_str" "    $$disk_size"; \
	   fi; \
	done
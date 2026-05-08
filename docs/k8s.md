## *Kubernetes*

### *K9s*
- #### *A.　安裝方式*
```
curl -sS https://webinstall.dev/k9s | bash

安裝完後，重啟終端機或輸入 source ~/.config/envman/PATH.env 即可生效
```

- #### *B.　使用方式*

```
: ：輸入命令（例如 :pod 看 Pod, :node 看節點）

/ ：過濾關鍵字

d ：Describe（查看詳細描述）

l ：Logs（查看日誌）

esc ：返回上一層
```

<br><br>

### *WSL2 ( Ubuntu ) 安裝 kubectl*
```
# 下載最新穩定版
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# 安裝
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 驗證
kubectl version --client
```

<br><br>

### *MiniKube*
- #### *A.　說明*
```
k8s-manifests 是原始部署本方式
helm 是進階抽象部署方式 => 優先體驗
```

<br>

| 組件 | 實作對應項目 | 核心作用 |
|--:|:--|:--|
| **Pod** | Python 容器 / DB 容器 | K8s 最小調度單位。Pod 內容器共用 Network Namespace，可用 localhost 互相通訊。 |
| **Deployment** | `python-app-deploy.yaml` | 管理 Pod 的狀態、版本與副本數。負責**自我修復 (Self-healing)**，Pod 掛了會自動重啟。 |
| **Service** | `postgres-service` | **穩定入口**。Pod IP 會變，但 Service 提供固定 DNS 名稱，解決服務發現問題。 |
| **Ingress** | `app-ingress.yaml` | **L7 負載均衡器**。根據網域名稱 (Domain) 或路徑 (Path) 將流量導向對應的 Service。 |
| **ConfigMap** | `app-config` | [ 若更新要手動重啟 ] 存放**非敏感配置**（如資料庫主機名）。修改時不需重新構建 Image。 |
| **Secret** | `db-secret` | [ 若更新要手動重啟 ] 存放**敏感資訊**（如密碼）。內容採 Base64 編碼，避免明文外洩。 |
| **PV / PVC** | `postgres-pvc` | **持久化存儲**。PV 是資源池，PVC 是申請單，確保資料不會隨容器消失。 |
| **Helm Chart** | `helm/app-stack/` | **K8s 包管理器**。將多個 YAML 範本化，實現「一套代碼，多種環境配置」。 |
| **Kubectl** | 命令列工具 | 與 K8s API Server 通訊的橋樑，所有操作的起點。 |

<br>


- #### *B.　WSL2 ( Ubuntu ) 安裝 MiniKube*

```
# 1. 下載最新版的 MiniKube 二進位檔
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# 2. 安裝至系統路徑
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 3. 驗證安裝是否成功
minikube version

# 4. 啟動 minikube，指定使用 docker driver
minikube start --driver=docker

# 5. 啟用 Ingress 控制器 # 負載均衡器
minikube addons enable ingress
```

- #### *C.　建立測試腳本 Images*
```
cd infra/minikube/app

# 切換環境變數 (讓 Docker 指向 MiniKube 內部的 Daemon)
eval $(minikube docker-env)

docker build -t my-python-app:v1 .
docker images | grep my-python-app
```

- #### *D.　部署指令*
```
# 安裝 Helm 自動下載配置
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# [1] 啟動/更新 Helm 部署 ( DEV 設置 )
helm upgrade --install my-dev-release ./helm/app-stack -f ./helm/app-stack/values-dev.yaml

# [2.1] 先解除安裝
helm uninstall my-dev-release

# [2.2] 再重新安裝
helm install my-dev-release ./helm/app-stack -f ./helm/app-stack/values-dev.yaml
```


- #### *E.　測試驗證*
```
# 查看目前的 release 列表與版本次數 (REVISION)
helm list

# 查看該 release 的詳細歷史紀錄
helm history my-dev-release

# 檢查服務狀態
kubectl get svc

# ⭐ 找到 pod 名稱
kubectl get pods

# ⭐ 確認 log
kubectl logs -f -l app=python-app --tail=20

# 進入 pod 內部
kubectl exec -it python-app-fd66fdf4c-f8g5d -- ping postgres-service

# 若有動到 configmap.yaml 優雅重啟
kubectl rollout restart deployment python-app

# 確認部署狀態
kubectl get pvc
-- 預期 Bound

# 強制移除節點
kubectl delete pod -l app=postgres
-- 預期 Python Log 會顯示開始報錯重試，直到 K8s 自動把 Postgres Pod 重啟回來後，連線又會恢復。

# 檢查 Service 關聯到的端點 (Endpoints)
kubectl get endpoints postgres-service

# 確認所有組件狀態 (Pod 應該要是 Running)
kubectl get pods,pvc,svc,ingress

# 查看 Python App 的連線日誌 (這驗證了 Service/ConfigMap/Secret)
kubectl logs -f -l app=python-app

# 先取得 minikube ip
minikube ip

# 嘗試從 WSL2 內訪問 (假設你的 Ingress Host 設定為 myapp.local)
curl -H "Host: myapp.local" $(minikube ip)
```

<br><br>


### *K3s*
```
```

<br><br>

### *Kubeadm*
```
```

<br><br><br>
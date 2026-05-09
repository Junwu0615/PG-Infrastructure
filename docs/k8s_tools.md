## *K8s Tools ( WSL2 Ubuntu )*


### *A.　Install K9s*
```
curl -sS https://webinstall.dev/k9s | bash

[1] 安裝完後，重啟終端機
[2] 或輸入 source ~/.config/envman/PATH.env 即可生效
```
    
#### *使用方式*

```
: ：輸入命令（例如 :pod 看 Pod, :node 看節點）
/ ：過濾關鍵字
d ：Describe（查看詳細描述）
l ：Logs（查看日誌）
esc ：返回上一層
```
  
<br>

### *B.　Install kubectl*
```
# 1. 下載最新穩定版
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# 2. 安裝至系統路徑 (賦予 root 權限並設定執行位)
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 3. 清理：刪除當前目錄下的下載檔
rm kubectl

# 4. 驗證
kubectl version --client
```
#### *使用方式*
```
# 確認已被定義的容器 (含不需連線 + 需連線 + ...) 名稱
kubectl get pods
# ⭐ 顯示標籤 ( 虛擬化簡稱 查找方便 )
kubectl get pods --show-labels
# ⭐ 常駐觀察
kubectl get pods -w

# 確認 pvc (儲存) 狀態
kubectl get pvc

# 檢查已被定義的服務 (被連線使用) 狀態
kubectl get svc

    # ⭐ 測試 DNS 解析 ( 容器內使用 )
    nslookup postgres-service

# 確認 ConfigMap 狀態
kubectl get cm

# ⭐ [ 組合技 ] 確認所有組件狀態
kubectl get pods,pvc,svc,ingress,cm

# ⭐ 確認 log ( 可用虛擬化名稱 )
kubectl logs -f -l app=python-app --tail=5

# ⭐ [ 僅開發 ] 將 k8s 服務映射到外部 方便外部系統開發 ; 命令列狀態會常駐，除非退出
kubectl port-forward svc/postgres-service 5432:5432
    # 內部一律採用 postgres-service 來解偶位置不同問題 ; 因為 k8s 的 IP 會浮動 => 高可用性

# ⭐ 進入 pod 內部 (exec)
    kubectl exec -it pod/python-app-fd66fdf4c-s4kxv -- bash
    
    # ⭐ 進階用法: ☄️ 可虛擬化簡稱
    kubectl exec -it $(kubectl get pods -l app=python-app -o name) -- bash
    kubectl exec -it $(kubectl get pods -l app=postgres -o name) -- bash

    # 直接進入 psql 終端機
    kubectl exec -it $(kubectl get pods -l app=postgres -o name) -- psql -U postgres
    
    # 查看儲存資源
    kubectl exec -it $(kubectl get pods -l app=postgres -o name) -- df -h

    # 確認環境變數是否被確實注入(查看敏感訊息...)
    kubectl exec -it $(kubectl get pods -l app=postgres -o name) -- env
    kubectl exec -it $(kubectl get pods -l app=python-app -o name) -- env

☄️ 建議直接透過 Helm 統一管理
    # 若有動到 configmap.yaml 優雅重啟
    kubectl rollout restart deployment python-app

    # 強制移除節點
    kubectl delete pod -l app=postgres
    -- 預期 Python Log 會顯示開始報錯重試，直到 K8s 自動把 Postgres Pod 重啟回來後，連線又會恢復。

# 檢查 Service 關聯到的端點 (Endpoints)
kubectl get endpoints postgres-service

# ⭐ [ 無法虛擬化名稱 ] 檢查具體噴錯原因
kubectl describe pod portainer-59cf9d8764-mg54l

# ⭐ [ 無法虛擬化名稱 ] 刪除目前的 Pod ( Deployment 自動開一個新的並重新拉取 )
kubectl delete pod portainer-59cf9d8764-86m7h
```
  
<br>

### *C.　Install Helm*
```
# 透過管道把下載下來的腳本內容，直接丟給 bash 直譯器去執行，而不在硬碟留下 .sh 檔案
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 可確認被丟到哪去
which helm
```
  
#### *使用方式*
```
# 部署方式 ( 啟動/更新/移除 )
    # ⭐ [1] 啟動/更新 Helm 部署 ( DEV 設置 ) + 外部傳入設定: image tags
    helm upgrade --install my-dev-release ./helm/app-stack -f ./helm/app-stack/values-dev.yaml --set image.tag=v1
    
    # [2.1] 先解除安裝
    helm uninstall my-dev-release
    
    # [2.2] 再重新安裝
    helm install my-dev-release ./helm/app-stack -f ./helm/app-stack/values-dev.yaml
    
# ⭐ 查看目前的 release 列表與版本次數 ( REVISION )
helm list

    # ⭐ 查看該 release 的詳細歷史紀錄
    helm history my-dev-release

# 一次性刪除該 Release 下所有的 Service, Deployment, ConfigMap, Ingress
helm uninstall my-dev-release
```

<br>

### *D.　Install MiniKube*
```
# 1. 下載最新版的 MiniKube 二進位檔
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# 2. 安裝至系統路徑 (同時重新命名為 minikube)
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 3. 清理：刪除當前目錄下的下載檔
rm minikube-linux-amd64

# 4. 驗證
minikube version
```

#### *使用方式*
```
# 若要訪問對外開口的應用
    # 1. 確認取得 minikube ip
    minikube ip
    
    # 2. 嘗試從 WSL2 內訪問 (假設你的 Ingress Host 設定為 myapp.local)
    curl -H "Host: myapp.local" $(minikube ip)
```

<br>

### *D.　[ ⚠️ 實作環境衝突 ] Install K3s*
```
# 建立單節點 ( The Server Node )
    1. 安裝 + 驗證
    curl -sfL https://get.k3s.io | sh -
    k3s --version
    
    2. 解決權限問題
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc
    source ~/.bashrc
    
    3. 修改檔案權限 ( 不加 sudo 也能跑 )
    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    
    4. 啟動 k3s + 確認狀態
    sudo systemctl start k3s
    sudo systemctl status k3s
    
    5. 確認狀態
    kubectl get nodes

    ⭐ * 手動啟動 K3s 伺服器 (診斷模式)    
    sudo k3s server --write-kubeconfig-mode 644 --node-name local-k3s --bind-address 127.0.0.1 --tls-san 127.0.0.1
```

#### *使用方式*
```
```

<br>

### *E.　Install K3d*
```
1. 安裝 + 驗證
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d --version

2. 建立集群 (一鍵搞定) : 建立一個包含 1 個 Server 和 2 個 Worker 的集群
# 集群名稱 = mycluster
k3d cluster create mycluster --agents 2
```

#### *使用方式*
```
```

<br><br><br>
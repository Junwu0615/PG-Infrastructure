## *Kubernetes*

### *A.　WSL2 ( Ubuntu ) Tools *
- ### *a.1.　Install K9s*
    ```
    curl -sS https://webinstall.dev/k9s | bash
    
    [1] 安裝完後，重啟終端機
    [2] 或輸入 source ~/.config/envman/PATH.env 即可生效
    ```
    
- #### *使用方式*

  ```
  : ：輸入命令（例如 :pod 看 Pod, :node 看節點）
  / ：過濾關鍵字
  d ：Describe（查看詳細描述）
  l ：Logs（查看日誌）
  esc ：返回上一層
  ```

- ### *a.2.　Install kubectl*
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
- #### *使用方式*
    ```
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
    ```
  
- ### *a.3.　Install Helm*
    ```
    # 透過管道把下載下來的腳本內容，直接丟給 bash 直譯器去執行，而不在硬碟留下 .sh 檔案
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  
    # 可確認被丟到哪去
    which helm
    ```
  
- #### *使用方式*
    ```
    # 一次性刪除該 Release 下所有的 Service, Deployment, ConfigMap, Ingress
    helm uninstall my-dev-release
    
    # 部署方式 ( 啟動/更新/移除 )
        # [1] 啟動/更新 Helm 部署 ( DEV 設置 )
        helm upgrade --install my-dev-release ./helm/app-stack -f ./helm/app-stack/values-dev.yaml
        
        # [2.1] 先解除安裝
        helm uninstall my-dev-release
        
        # [2.2] 再重新安裝
        helm install my-dev-release ./helm/app-stack -f ./helm/app-stack/values-dev.yaml
        
    # 查看目前的 release 列表與版本次數 (REVISION)
    helm list
    
    # 查看該 release 的詳細歷史紀錄
    helm history my-dev-release
    ```


- ### *a.4.　Install MiniKube*
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


<br><br>

### *MiniKube*
- #### *A.　說明*
    ```
    k8s-manifests : 原始部署方式
    helm : 進階抽象部署方式 => 優先體驗
    ```
    
    | 組件 | 實作對應項目 | 若更新是否自動重啟 Pod | 核心作用 |
    |--:|:--|:--:|:--|
    | **Pod** | Python 容器 / DB 容器 | - | K8s 最小調度單位。Pod 內容器共用 Network Namespace，可用 localhost 互相通訊。 |
    | **Deployment** | `python-app-deploy.yaml` | 自動 ( Image / Env ) | 管理 Pod 的狀態、版本與副本數。負責**自我修復 (Self-healing)**，Pod 掛了會自動重啟。 |
    | **Service** | `postgres-service` | 不需重啟 | **穩定入口**。Pod IP 會變，但 Service 提供固定 DNS 名稱，解決服務發現問題。 |
    | **Ingress** | `app-ingress.yaml` | 不需重啟 | **L7 負載均衡器**。根據網域名稱 (Domain) 或路徑 (Path) 將流量導向對應的 Service。 |
    | **ConfigMap** | `app-config` | 手動重啟 | 存放**非敏感配置**（如資料庫主機名）。修改時不需重新構建 Image。 |
    | **Secret** | `db-secret` | 手動重啟 | 存放**敏感資訊**（如密碼）。內容採 Base64 編碼，避免明文外洩。 |
    | **PV / PVC** | `postgres-pvc` | - | **持久化存儲**。PV 是資源池，PVC 是申請單，確保資料不會隨容器消失。 |
    | **Helm Chart** | `helm/app-stack/` | - | **K8s 包管理器**。將多個 YAML 範本化，實現「一套代碼，多種環境配置」。 |
    | **Kubectl** | 命令列工具 | - | 與 K8s API Server 通訊的橋樑，所有操作的起點。 |

<br>

- #### *B.　Minikube 完整生命週期*
```
# 初始化 (Provisioning)
    [每次] # Start: 指定使用 docker driver
    minikube start --driver=docker
    發生了什麼:
        - 下載 K8s 節點鏡像
        - 建立虛擬環境 (Docker Container)
        - 持久化狀態： MiniKube 會在電腦
            建立 ~/.minikube 資料夾，儲存證書、配置與虛擬硬碟狀態

    [一次性] Addons： 一旦啟用，其設定會紀錄在狀態中，下次啟動時會自動加載    
    # 啟用 Ingress 控制器 # 負載均衡器
    minikube addons enable ingress


# 暫停 + 恢復 (Pause / Unpause)
minikube pause / minikube unpause
重要特點： 正在開發，想暫時釋放 CPU 資源，
    但不想關閉 Pod，這會掛起所有容器進程


# 停止 (Stop)
minikube stop
發生了什麼：優雅地關閉 K8s 控制平面與容器
重要特點：PV/PVC 資料會保留。下次啟動時，只需輸入 minikube start
（不需要再加 driver 或 addons），它會恢復到關閉前的樣子


# 刪除 (Delete) - 徹底關閉
minikube delete
發生了什麼：銷毀虛擬環境，清空所有資源
注意：所有的資料庫資料 (PV) 和配置都會消失
    下次需要重新 minikube start --driver=docker
```

- #### *C.　Makefile Command*
```
# 建構測試腳本映像檔
make build

# 部署指令
make deploy

# 徹底清除
make clean

# 重新部署 ( clean + build + deply )
make redeploy
```

- #### *D.　測試驗證*
```
# 若要訪問對外開口的應用
    # 1. 確認取得 minikube ip
    minikube ip
    
    # 2. 嘗試從 WSL2 內訪問 (假設你的 Ingress Host 設定為 myapp.local)
    curl -H "Host: myapp.local" $(minikube ip)
```

<br><br>


### *K3s*
- #### *A.　K3s 完整生命週期*
```
當從 MiniKube 進化到 K3s + VM 時，生命週期的管理對象會改變：
    - Terraform 階段：負責機器的「生與死」（建立 VM 或銷毀 VM）
    - Ansible 階段：負責機器的「初始化」（安裝 K3s、設定 Ingress）
    - K8s 本身：一旦機器開著，K8s 服務就是常駐的（Daemon），你不再需要手動 start 它
    

```

<br><br>

### *Kubeadm*
```
```

<br><br><br>
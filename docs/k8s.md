## *Kubernetes*

### *A.　K8s Tools ( WSL2 Ubuntu )*
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
  
<br>

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
    # 確認已被定義的容器 (含不需連線 + 需連線 + ...) 名稱
    kubectl get pods
    # ⭐ 常駐觀察
    kubectl get pods -w
  
    # 確認 pvc (儲存) 狀態
    kubectl get pvc
  
    # 檢查已被定義的服務 (被連線使用) 狀態
    kubectl get svc

    # 確認 config 狀態
    kubectl get cm
  
    # ⭐ [ 組合技 ] 確認所有組件狀態
    kubectl get pods,pvc,svc,ingress,cm

    # ⭐ 確認 log
    kubectl logs -f -l app=python-app --tail=5
    
    # ⭐ [ 僅開發 ] 將 k8s 服務映射到外部 方便外部系統開發 ; 命令列狀態會常駐，除非退出
    kubectl port-forward svc/postgres-service 5432:5432
        # 內部一律採用 postgres-service 來解偶位置不同問題 ; 因為 k8s 的 IP 會浮動 => 高可用性
    
    # ⭐ 進入 pod 內部 (exec)
        ☄️ 無法虛擬化簡稱
        kubectl exec -it postgres-db-774b56c954-v8bsf -- bash
        kubectl exec -it pod/python-app-fd66fdf4c-s4kxv -- bash
        
        # ⭐ 進階用法
        kubectl exec -it $(kubectl get pods -l app=postgres -o name) -- psql -U postgres
  
        # 直接進入 psql 終端機
        kubectl exec -it postgres-db-774b56c954-5z6kw -- psql -U postgres
        
        # 查看儲存資源
        kubectl exec -it postgres-db-774b56c954-5z6kw -- df -h
  
        # 確認環境變數是否被確實注入(查看敏感訊息...)
        kubectl exec -it pod/python-app-fd66fdf4c-s4kxv -- env
        kubectl exec -it postgres-db-774b56c954-5z6kw -- env
    
    # 若有動到 configmap.yaml 優雅重啟
    kubectl rollout restart deployment python-app

    # 強制移除節點
    kubectl delete pod -l app=postgres
    -- 預期 Python Log 會顯示開始報錯重試，直到 K8s 自動把 Postgres Pod 重啟回來後，連線又會恢復。
    
    # 檢查 Service 關聯到的端點 (Endpoints)
    kubectl get endpoints postgres-service
    ```
  
<br>

- ### *a.3.　Install Helm*
    ```
    # 透過管道把下載下來的腳本內容，直接丟給 bash 直譯器去執行，而不在硬碟留下 .sh 檔案
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  
    # 可確認被丟到哪去
    which helm
    ```
  
- #### *使用方式*
    ```
    # 部署方式 ( 啟動/更新/移除 )
        # ⭐ [1] 啟動/更新 Helm 部署 ( DEV 設置 )
        helm upgrade --install my-dev-release ./helm/app-stack -f ./helm/app-stack/values-dev.yaml --set image.tag=v1
        
        # [2.1] 先解除安裝
        helm uninstall my-dev-release
        
        # [2.2] 再重新安裝
        helm install my-dev-release ./helm/app-stack -f ./helm/app-stack/values-dev.yaml
        
    # ⭐ 查看目前的 release 列表與版本次數 (REVISION)
    helm list
    
    # ⭐ 查看該 release 的詳細歷史紀錄
    helm history my-dev-release
  
    # ⭐ 一次性刪除該 Release 下所有的 Service, Deployment, ConfigMap, Ingress
    helm uninstall my-dev-release
    ```

<br>

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
- #### *使用方式*
    ```
    # 若要訪問對外開口的應用
        # 1. 確認取得 minikube ip
        minikube ip
        
        # 2. 嘗試從 WSL2 內訪問 (假設你的 Ingress Host 設定為 myapp.local)
        curl -H "Host: myapp.local" $(minikube ip)
    ```

<br><br>

### *B.　MiniKube*
- #### *b.1.　說明*
    ```
    k8s-manifests : 原始部署方式
    helm : 進階抽象部署方式 => 優先體驗
    ```
    
    | 組件 | 對應項目 | 若更新是否自動重啟 Pod | 核心作用 |
    |--:|:--|:--:|:--|
    | **Pod** | Python 容器 / DB 容器 | - | K8s 最小調度單位。Pod 內容器共用 Network Namespace，可用 localhost 互相通訊。 |
    | **Deployment** | `python-app-deploy.yaml` | 自動 ( Image / Env ) | 管理 Pod 的狀態、版本與副本數。負責**自我修復 (Self-healing)**，Pod 掛了會自動重啟。 |
    | **Service** | `db-deploy.yaml` | 不需重啟 | **穩定入口**。Pod IP 會變，但 Service 提供固定 DNS 名稱，解決服務發現問題。 |
    | **Ingress** | `ingress.yaml` | 不需重啟 | **L7 負載均衡器**。根據網域名稱 (Domain) 或路徑 (Path) 將流量導向對應的 Service。 |
    | **ConfigMap** | `configmap.yaml` | 手動重啟 | 存放**非敏感配置**（如資料庫主機名）。修改時不需重新構建 Image。 |
    | **Secret** | `secret.yaml` | 手動重啟 | 存放**敏感資訊**（如密碼）。內容採 Base64 編碼，避免明文外洩。 |
    | **PV / PVC** | `db-pvc.yaml` | - | **持久化存儲**。PV 是資源池，PVC 是申請單，確保資料不會隨容器消失。 |
    | **Helm Chart** | `helm/app-stack/` | - | **K8s 包管理器**。將多個 YAML 範本化，實現「一套代碼，多種環境配置」。 |
    | **Kubectl** | 命令列工具 | - | 與 K8s API Server 通訊的橋樑，所有操作的起點。 |

<br>

- #### *b.2.　Minikube 完整生命週期*
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

- #### *b.3.　Makefile Command*
    ```
    # [Docker] 建構測試腳本映像檔 + 版本號設定 v1
    make build ver=v1
    
    # [Helm] 部署指令 + 指定映像檔 v1
    make deploy ver=v1
  
    # [Helm] 回滾至 Revision 版本1
    make rollback ver=1

    # [Hybrid] 徹底清除
    make clean
    ```

- #### *b.4.　測試驗證*
    ```
    👁️ 測試 1: Pod 故障自癒 ( 模擬服務崩潰 ) 
        # 1. [持續觀察] 整體 pods
        kubectl get pods -w
  
        # 2. [持續觀察] python logs
        kubectl logs -f -l app=python-app --tail=10
  
        # 3. 砍服務
        # K8s 會認為整棟房子都被拆了，所以會重新蓋一棟房子，Pod 名稱會改變（後面的隨機碼會換）
        kubectl delete pod -l app=postgres
  
        # 4. 是否復原 ? ( python 成功連線 + DB 服務恢復 )

    
    👁️ 測試 2: 容器層級故障 ( Docker 逃逸測試 )
        # 1. [持續觀察] 整體 pods ( 含 RESTART 欄位 )
        kubectl get pods -w
  
        # 2. [持續觀察] python logs
        kubectl logs -f -l app=python-app --tail=10
  
        # 3. 砍容器 ( 進入 minikube 內部 ) # RESTART 會計數 +1
        minikube ssh
        docker ps | grep python-worker
  
        # K8s 認為房子（Pod）還在，只是裡面的房客（Container）昏倒了。
        # 它會直接在「原有的房子」裡重啟房客，所以 Pod 名稱保持不變，但 RESTARTS 次數會累加。
        docker stop <CONTAINER_ID>
  
        # 4. 是否復原 ? ( 是否有復原容器 )
  
    👁️ 測試 3: 滾動更新 ( Rolling Update )
        ☄️ helm => 版本控制指揮官
        # 1. 觀察映像檔使用狀態
        docker images | grep "my-python-app"
  
        # 2. 改動 Images => 觀察 k8s 是否有熱重啟 ( 透過 logs 檢視 )
        make build ver=v2
  
        # 3. 更新配置
          - 告訴 helm 當前配置應指向 images v2
          - 直接執行 upgrade 而非 kubectl rollout
          - 幕等性
        make deploy ver=v2
  
        # 4. 觀察映像檔使用狀態
  
    👁️ 測試 4：設定錯誤與回滾 (Rollback)
        ☄️ helm => 版本控制指揮官
        # 1. 查看 Helm 歷史紀錄 ( 確認上一個穩定的 Revision )
        helm history my-dev-release
  
        # 回滾上一版本 (只的是 REVISION 而非 Images 版本)
        make rollback ver=5
  
        # 觀察是否回滾到上一版本
        docker images | grep "my-python-app"
  
    👁️ 測試 5：配置更新自動觸發重啟 (Reloader)
  
  
    👁️ 測試 6：網路層級（Service 斷線測試）
  
  
    👁️ 測試 7：資源限制 (Resource Limit - OOMKilled)
  
  
    👁️ 測試 8：親和性與反親和性 (Anti-Affinity)
  
  
    👁️ 測試 9：存活探針故障 (Liveness Probe Failure)
  
  
    ```

<br><br>


### *C.　K3s*
- #### *c.1.　K3s 完整生命週期*
    ```
    當從 MiniKube 進化到 K3s + VM 時，生命週期的管理對象會改變：
        - Terraform 階段：負責機器的「生與死」（建立 VM 或銷毀 VM）
        - Ansible 階段：負責機器的「初始化」（安裝 K3s、設定 Ingress）
        - K8s 本身：一旦機器開著，K8s 服務就是常駐的（Daemon），你不再需要手動 start 它
    ```

<br><br>

### *D.　Kubeadm*
```
```

<br><br><br>
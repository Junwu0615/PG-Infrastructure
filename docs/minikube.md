## *MiniKube*


#### *A.　說明*
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

#### *B.　Minikube 完整生命週期*
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

#### *C.　Makefile Command*
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

#### *D.　測試驗證*
```
👁️ 測試 1: Pod 故障自癒 ( 模擬服務崩潰 ) 
    1. [持續觀察] 整體 pods
        kubectl get pods -w

    2. [持續觀察] python logs
        kubectl logs -f -l app=python-app --tail=10

    3. 砍服務
        # K8s 會認為整棟房子都被拆了，所以會重新蓋一棟房子，Pod 名稱會改變（後面的隨機碼會換）
        kubectl delete pod -l app=postgres

    4. 是否復原 ? ( python 成功連線 + DB 服務恢復 )


👁️ 測試 2: 容器層級故障 ( 容器逃逸測試 )
    1. [持續觀察] 整體 pods ( 含 RESTART 欄位 )
        kubectl get pods -w

    2. [持續觀察] python logs
        kubectl logs -f -l app=python-app --tail=10

    3. 砍容器 ( 進入 minikube 內部 ) # RESTART 會計數 +1
        minikube ssh
        docker ps | grep python-worker

        # K8s 認為房子（Pod）還在，只是裡面的房客（Container）昏倒了。
        # 它會直接在「原有的房子」裡重啟房客，所以 Pod 名稱保持不變，但 RESTARTS 次數會累加。

        docker stop <CONTAINER_ID>

    4. 是否復原 ? ( 是否有復原容器 )


👁️ 測試 3: 滾動更新 ( Rolling Update )
    ☄️ helm => 版本控制指揮官
    1. 觀察映像檔使用狀態
        docker images | grep "my-python-app"

    2. 改動 Images => 觀察 k8s 是否有熱重啟 ( 透過 logs 檢視 )
        make build ver=v2

    3. 更新配置
        - 告訴 helm 當前配置應指向 images v2
        - 直接執行 upgrade 而非 kubectl rollout
        - 幕等性
        make deploy ver=v2

    4. 觀察映像檔使用狀態


👁️ 測試 4：錯誤與回滾 ( Rollback )
    ☄️ helm => 版本控制指揮官
    1. 查看 Helm 歷史紀錄 ( 確認上一個穩定的 Revision )
        helm history my-dev-release

    2. 回滾上一版本 (只的是 REVISION 而非 Images 版本)
        make rollback ver=5

    3. 觀察是否回滾到上一版本
        docker images | grep "my-python-app"


👁️ 測試 5：配置更新自動觸發重啟 ( Reloader )
    情境：  K8s 原生的 ConfigMap 更新時，Pod 內的環境變數並不會自動改變。通常需要手動重啟 Pod。
           測試將利用開源工具 `Reloader` 實現「改完設定，Pod 自動轉圈圈更新」。

    1.1  安裝 Reloader：
        helm repo add stakater https://stakater.github.io/stakater-charts
        helm install reloader stakater/reloader
    1.2 helm list 可發現多一個服務

    2.  在 Deployment 加入 Annotation：
        在 Deployment Metadata 中加入 `[reloader.stakater.com/auto](https://reloader.stakater.com/auto): "true"`

    3.  修改 ConfigMap：
        kubectl get cm # 確認欲修改的目標
        
        載入當前配置
        kubectl get configmap app-config -o yaml
        
        修改一個連線字串或環境變數 => 測試
        [1] 指令: kubectl edit configmap app-config
        [2] 直接: helm/app-stack/templates/configmap.yaml
        更動 APP_MODE: "dev" => "stage"

    4. 重新更新版本 ( 指令為幕等性 => 異動才會重啟服務 )
        make deploy ver=v4

    5. [持續觀察] 整體 pods ( 含 RESTART 欄位 )
        kubectl get pods -w
        會發現 Pod 觸發了 Rolling Update => 證明了配置聯動更新成功

    6. 確認環境變被更動
        kubectl exec -it $(kubectl get pods -l app=python-app -o name) -- env | grep "APP_MODE"


👁️ [ X ] 測試 6：網路層級（Service 斷線測試）
    情境：  模擬「服務雖然在，但路徑斷了」~
           這能讓你理解 Service (ClusterIP) 是如何透過 iptables/IPVS 進行負載平衡，
           以及當 Service 被刪除時，客戶端會發生什麼事。

    1.  持續請求測試：
        開啟一個臨時 Pod 不斷存取你的 Python App：
        `kubectl run tracer --image=curlimages/curl -i --tty --rm -- sh`
        `while true; do curl -s http://python-app-service:port/health; sleep 1; done`
    2.  刪除 Service：
        `kubectl delete svc python-app-service`
    3.  觀察：
        你會看到 `curl` 開始報錯 (Connection refused)。這模擬了「進入點故障」
    4.  恢復 Service：
        重新執行 `make deploy` 或 `kubectl apply`
    5.  驗證：
        觀察 `curl` 是否在 Service 重建後秒速恢復連線


👁️ [ X ] 測試 7：資源限制 (Resource Limit - OOMKilled)
    情境： 最經典的「抓戰犯」環節。
          當程式碼有 Memory Leak，或是給的資源太小，K8s 會狠心地殺掉它。

    1.  限制資源：
        在 Helm Chart 的 `resources.limits.memory` 設定一個極小值（例如 `50Mi`）
    2.  觸發記憶體壓力：
        在 Python App 寫一個暫時的 API 或是用腳本吃掉記憶體：
    3.  觀察狀態：
        `kubectl get pods`
        你會看到 Pod 狀態變為 **OOMKilled**，然後重啟
    4.  檢查細節：
        `kubectl describe pod <pod-name>`
        在 `Last State` 欄位會明確標註 `Reason: OOMKilled`


👁️ [ X ] 測試 8：親和性與反親和性 (Anti-Affinity)
    目標：  確保你的 DB 與 App 不要住在同一個 Node（避免單一節點損壞時全滅）
    做法：  配置 `podAntiAffinity`，然後觀察 `kubectl get pods -o wide`，
           確認 Pod 是否散佈在不同節點（minikube 可開啟多節點模式 `minikube start -n 2`）


👁️ [ X ] 測試 9：存活探針故障 (Liveness Probe Failure)
    目標：  模擬程式「雖然沒當掉，但死鎖 (Deadlock) 了」
    做法：
           配置 `livenessProbe` 檢查 `/health` 接口
           透過代碼模擬 `/health` 永遠回傳 `500 Error` 或逾時
           觀察 K8s 如何在不刪除 Pod 的情況下，自動「重啟內部容器」來試圖修復它
```


<br><br><br>
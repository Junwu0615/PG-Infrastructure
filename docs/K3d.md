## *K3d*


### *A.　部署框架演進*
```
Evolution: MiniKube ➔ ✅ K3d ➔ K3s ➔ K3s Migration ➔ Kubeadm ➔ GKE

Summary:
    # 👁️ 測試 10 - 14

------

# 開始叢集
k3d cluster start mycluster

# 停止叢集 ( 正常關機 )
k3d cluster stop mycluster

# 刪除叢集（ 所有 Pod, Service, ConfigMap ）
k3d cluster delete mycluster

# 檢查狀態
k3d cluster list

# ⚠️ 實際上線 / 遇到異常斷電 ... 等 ( 大概依賴工具的強壯性ㄌ )
```

<br>

### *B.　測試前準備*
```
1. 獲取存取權限 → 當前使用者可以操作 kubectl
# ⚠️ 若先前用 k3s 改動設定則 ...
    unset KUBECONFIG
    刪除底部設定的 export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    source ~/.bashrc

sudo chmod 644 ~/.kube/config
k3d kubeconfig get mycluster > ~/.kube/config


2.1 建立集群 (一鍵搞定) : 建立一個包含 1 個 Server 和 2 個 Worker 的集群
# 集群名稱 = mycluster
k3d cluster create mycluster --agents 2

⭐ 2.2 動態新增節點
    # 新增一個名為 agent-2 的節點到 mycluster 集群
    k3d node create mycluster-agent-2 --cluster mycluster --role agent
    
    ⭐ # 當節點一直無法成功 換個名稱 因為快取被記錄了 底層問題繞過去
    k3d node create new-worker --cluster mycluster --role agent

    ⭐ # 刪除節點
    k3d node delete k3d-mycluster-agent-2-0
    
    # 重啟節點
    docker restart k3d-mycluster-agent-2-0

3. 驗證節點狀態
kubectl get nodes


4. 建立映像檔 + 傳入虛擬環境 ( mycluster )
make build ver=v4
make image-load ver=v4


5. 啟動 ...
make deploy ver=v4


6. 確認 Python 日誌
kubectl logs -f -l app=python-app --tail=5
```

<br>

### *C.　測試驗證*
```
👁️ 持續觀察 K8s 如何分配任務: kubectl get pods -w -o wide

👁️ 測試 10： Node Affinity ( 指定居所 )
    情境： 希望 Python App 跑在 agent-1，而 Postgres DB 跑在 agent-0
    
    ⭐ 1. 給節點貼標籤 ( 強制 Pod 只能跑在有這個標籤的節點 )
        # 標記 agent-0 為 Postgres 節點 ( service-type=database )
        kubectl label nodes k3d-mycluster-agent-0 service-type=database --overwrite
        
        # 標記 agent-1 為 APP 節點 ( service-type=app )
        kubectl label nodes k3d-mycluster-agent-1 service-type=app --overwrite
        
        # [ 動態創建的名稱很醜 ] 標記 agent-2 為 Portainer 節點 ( service-type=management )
        kubectl label nodes k3d-new-worker-0 service-type=management --overwrite
        
        # ⭐ 刪除標籤方式 一個減號 → ${{標籤}}-
        kubectl label nodes k3d-mycluster-agent-0 service-type-
    
    ⭐ 2. 修改配置
    helm/app-stack/templates/db-deploy.yaml
    
    
👁️ 測試 11： 多節點自癒與調度演習
    1. 關閉節點
    docker stop k3d-mycluster-agent-1
    
    2. 中途發生的事... ( ⚠️ 有容錯等待期 )
    python 從 agent-1 → agent-0
    
    3. 恢復節點
    docker start k3d-mycluster-agent-1
    
    
👁️ 測試 12： Service 的負載平衡與連通性
    情境： 現在 Pod 散落在兩台機器上，我們來驗證 Service 是否能正確導流
    
    1. 進入 Python Pod
    kubectl exec -it $(kubectl get pods -l app=python-app -o name) -- sh
    
    2. 在 Pod 裡面測試連線（ 跨越 agent-1 到 agent-0 ）
    python3 -c "import socket; s = socket.socket(); s.settimeout(5); print(s.connect_ex(('postgres-service', 5432)) == 0)"
    → True ( 成功 )
    

👁️ 測試 13： 自動摘除與恢復
    情境: 環境因素（DB 斷線）導致服務暫時不可用
         K8s 透過 Readiness Probe 幫你把「壞掉的 Pod」屏蔽掉，等它好了再放行
    
    1. 加入 app-deploy.yaml 健康設置 + replica 至少為 2
    
    2. 實時觀察 python log
    kubectl logs -f -l app=python-app --tail=5
    
    3. 砍掉 DB 連線 導致 python 報錯
    kubectl delete pod -l app=postgres
    
    4. 觀察是否恢復狀態 ?
    * python-app-848d7b7889-wgk6w  0/1 Running
        → DB 消失 → Python 腳本連不上 DB → 腳本刪除 /tmp/healthy → 
           K8s 發現檔案沒了 → 把這個 Pod 標記為 Unready (0/1)
    
    * 最後自動復原 ...
    
    
👁️ 測試 14： 零停機更新與回滾 ( Rolling Update & Rollback )
    情境: 更新 python-app 從 v4 到 v5，且在更新過程中，我們持續對 API 發送請求，確保一次失敗都沒有
    
    1. 發布必死的版本 ( 根本沒建立 ver999 ) 
    make deploy ver=999
    
    2. 觀察 kubectl get pods -w -o wide
    python-app-7b67f67f77-52d5t    0/1     ImagePullBackOff  
    python-app-848d7b7889-n7v22    1/1     Running           
    python-app-848d7b7889-wgk6w    1/1     Running           
    
    3. 效果原因 ( # helm/app-stack/templates/app/app-deploy.yaml )
    rollingUpdate:
      maxSurge: 1       # 更新時最多可以多開幾個 Pod # 只允許一個額外的新 Pod 出現嘗試交接，所以不會有無窮無盡的新 Pod 塞爆你的節點
      maxUnavailable: 0 # 更新時最少要維持幾個 Pod 在線 # 強制要求「舊的必須都在，新的才能上」
    
    [ 回滾 4.1 ] 無腦回滾上一版
    kubectl rollout undo deployment python-app
    
    [ 回滾 4.2 ] 檢視歷史紀錄 + 指定回滾版本
    kubectl rollout history deployment python-app
    kubectl rollout undo deployment python-app --to-revision=5
```

<br><br><br>
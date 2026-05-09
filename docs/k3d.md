## *K3s*


### *A.　K3s 完整生命週期*
```
當從 MiniKube 進化到 K3s + VM 時，生命週期的管理對象會改變：
    - Terraform 階段：負責機器的「生與死」（建立 VM 或銷毀 VM）
    - Ansible 階段：負責機器的「初始化」（安裝 K3s、設定 Ingress）
    - K8s 本身：一旦機器開著，K8s 服務就是常駐的（Daemon），你不再需要手動 start 它
```

<br>

### *B.　測試前準備*
```
1. 獲取存取權限 => 當前使用者可以操作 kubectl
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
make image_load ver=v4


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
        
        # ⭐ 刪除標籤方式 一個減號 => ${{標籤}}-
        kubectl label nodes k3d-mycluster-agent-0 service-type-
    
    ⭐ 2. 修改配置
    helm/app-stack/templates/db-deploy.yaml
    
    
👁️ 測試 11： 多節點自癒與調度演習
    1. 關閉節點
    docker stop k3d-mycluster-agent-1
    
    2. 中途發生的事... ( ⚠️ 有容錯等待期 )
    python 從 agent-1 => agent-0
    
    3. 恢復節點
    docker start k3d-mycluster-agent-1
    
    
👁️ 測試 12：Service 的負載平衡與連通性
    情境： 現在 Pod 散落在兩台機器上，我們來驗證 Service 是否能正確導流
    
    1. 進入 Python Pod
    kubectl exec -it python-app -- sh
    
    2. 在 Pod 裡面測試連線（ 跨越 agent-1 到 agent-0 ）
    nc -zv postgres-db-service 5432
```

<br><br><br>
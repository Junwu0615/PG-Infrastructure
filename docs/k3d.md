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

2. 驗證節點狀態
kubectl get nodes

3. 建立映像檔 + 傳入虛擬環境 ( mycluster )
make build ver=v4
make image_load ver=v4

4. 啟動 ...
make deploy ver=v4

5. 確認 Python 日誌
kubectl logs -f -l app=python-app --tail=5
```

<br>

### *C.　測試驗證*
```
👁️ 持續觀察: kubectl get pods -w -o wide

👁️ 測試 10：親和性實踐 ( K3s 多節點必做 )
    情境： 希望 Python App 跑在 VM-2，而 Postgres DB 跑在 VM-1
    
    1. kubectl label node vm-2 type=frontend
    2. python-app-deploy.yaml 加入 nodeSelector
    3. kubectl get pods -o wide
    
👁️ 測試 11：觀察 Pod 散佈
    情境： 有了 3 個節點 => 測試 K8s 如何分配任務

    make deploy ver=v4
    kubectl get pods -o wide
```

<br><br><br>
## *K3s*


### *A.　K3s 完整生命週期*
```
當從 MiniKube 進化到 K3s + VM 時，生命週期的管理對象會改變：
    - Terraform 階段：負責機器的「生與死」（建立 VM 或銷毀 VM）
    - Ansible 階段：負責機器的「初始化」（安裝 K3s、設定 Ingress）
    - K8s 本身：一旦機器開著，K8s 服務就是常駐的（Daemon），你不再需要手動 start 它
    
    
k3d -> k3s
* K3d： 適合開發、測試 Helm 邏輯、練習節點調度
* K3s： 適合部署在虛擬機（VM）或實體機（如 Raspberry Pi）上
* 差異點：
    - 網路： K3s 在真實環境中會接觸到實體網路 IP，你需要處理 Firewall (ufw/iptables)
    - 儲存： K3d 的 Persistent Volume 是掛載 Docker Volume，K3s 則會直接掛載 Linux 主機的目錄
    - 負載平衡： K3s 內建 Service LB，但在實體環境你可能需要搭配 MetalLB 才能獲得真實的 External IP
```

<br>

### *B.　建立單節點 ( The Server Node )*
```
# 獲取存取權限 => 當前使用者可以操作 kubectl
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# 映像檔遷移問題
[1] 暴力解 | 既有映像檔傳入
docker save my-app:v4 | sudo k3s ctr images import -
[2] 建立 Docker Registry 優雅拉取
```

<br>

### *C.　多節點*
```
# 第 1 台
    # 獲取 Token
    sudo cat /var/lib/rancher/k3s/server/node-token
    # 獲取 Server IP
    hostname -I | awk '{print $1}'
    
# 第 2 - N 台
    curl -sfL https://get.k3s.io | K3S_URL=https://<SERVER_IP>:6443 K3S_TOKEN=<NODE_TOKEN> sh -


# 可檢視機器名字出現在列表
kubectl get nodes
```

<br>

### *D.　測試驗證*
```
👁️ 測試 10：親和性實踐 ( K3s 多節點必做 )
    情境： 希望 Python App 跑在 VM-2，而 Postgres DB 跑在 VM-1
    
    1. kubectl label node vm-2 type=frontend
    2. python-app-deploy.yaml 加入 nodeSelector
    3. kubectl get pods -o wide
```

<br><br><br>
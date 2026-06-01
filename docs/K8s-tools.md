## *K8s Tools ( WSL2 Ubuntu )*


### *A.　Install K9s*
```
curl -sS https://webinstall.dev/k9s | bash

[1] 安裝完後，重啟終端機
[2] 或輸入 source ~/.config/envman/PATH.env 即可生效
```
    
#### *>>　使用方式*

```
# 可以搭配工具看記憶體損耗
    # MEM (含 Cache)
    htop
    
    # 首選 ( 拆更細 )
    free -h
    
        ⭐ 動態更新 ( 每 2 秒更新一次 )
        watch -d -n 2 free -hw
        
        # 欄位意思
        # total = used + free + buff/cache (總實體記憶體)
        # shared (共用記憶體) = 有多個不同的應用程式（進程）共同存取、分享的同一塊實體記憶體空間
        # buffers (緩衝區) = 用來存放「準備要寫入磁碟，或者剛從磁碟讀出來」的原始磁碟區塊（Raw Disk Blocks）中介資料
        # swap (交換空間) = 當實體記憶體（RAM）真的完全不夠用時，Linux 拿來「充當臨時記憶體用的硬碟空間」
        # available (可用記憶體) = 「當我的新應用程式（或 K8s Pod）突然啟動時，它實際上能從系統搶到多少記憶體？」
        
        # 核心觀念
        # 1. total ≈ used + available (實體 RAM 內部的兩大陣營)
        # 2. 當 available = 0 且 swap 用盡時 = 系統觸發 OOM 崩潰

    # 前 10 名行程損耗
    ps aux --sort=-%mem | head -n 11
    
    # 手動釋放記憶體
    sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
    
                   total        used        free      shared  buff/cache   available
    Mem:            31Gi        15Gi       7.4Gi        57Mi       8.4Gi        15Gi
    
    $ sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

                   total        used        free      shared  buff/cache   available
    Mem:            31Gi        15Gi        14Gi        57Mi       1.1Gi        15Gi

# 替換集群方式
    * 啟動時餵路徑
    # k9s --kubeconfig ~/.kube/config-k3s
    
    * 軟連結
    # 確認底下文件
    ls ~/.kube
    # 備份原有的預設 config
    mv ~/.kube/config ~/.kube/config.bak
    # 建立軟連結
    ln -s ~/.kube/config-k3s ~/.kube/config

------
# 按 0： 切換到「所有命名空間」
# 輸入:
    pod
    node

------
: ：輸入命令（ 例如 :pod 看 Pod, :node 看節點 ）
/ ：過濾關鍵字
d ：Describe（ 查看詳細描述 ）
l ：Logs（ 查看日誌 ）
esc ：返回上一層
```
  
<br>

### *B.　Install kubectl*
```
# 1. 下載最新穩定版
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# 2. 安裝至系統路徑 ( 賦予 root 權限並設定執行位 )
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 3. 清理：刪除當前目錄下的下載檔
rm kubectl

# 4. 驗證
kubectl version --client
```
#### *>>　使用方式*
```
# 檢視 kubectl 目前生效的最終設定
kubectl config view

# 檢查目前 kubectl 的連線環境狀態
kubectl cluster-info

# 檢查環境變數有沒有確實生效
echo $KUBECONFIG

---

# 確認已被定義的容器 ( 含不需連線 + 需連線 + ... ) 名稱
kubectl get pods
⭐ 顯示標籤 ( 虛擬化簡稱 查找方便 )
kubectl get pods --show-labels

# 無視指定域名 全部顯示
kubectl get pods -A

⭐ 常駐觀察
kubectl get pods -w

# 確認 pvc ( 儲存 ) 狀態
kubectl get pvc

# 確認 節點 狀態
kubectl get nodes

# 確認 crd 狀態 ( 藍圖被註冊進 K8s 系統 )
kubectl get crd

# 檢查已被定義的服務 ( 被連線使用 ) 狀態
kubectl get svc

    ⭐ 測試 DNS 解析 ( 容器內使用 )
    nslookup postgres-service

# 確認 ConfigMap 狀態
kubectl get cm

# 確認 namespaces
kubectl get namespaces

⭐ [ 組合技 ] 確認所有組件狀態
kubectl get pods,pvc,svc,ingress,cm,nodes

⭐ 確認 log ( 可用虛擬化名稱 )
kubectl logs -f -l app=python-app --tail=5

⭐ [ 僅開發 ] 將 k8s 服務映射到外部 方便外部系統開發 ; 命令列狀態會常駐，除非退出
kubectl port-forward svc/postgres-service 5432:5432
    # 內部一律採用 postgres-service 來解偶位置不同問題 ; 因為 k8s 的 IP 會浮動 => 高可用性

⭐ 進入 pod 內部
    kubectl exec -it pod/python-app-fd66fdf4c-s4kxv -- bash
    
    ⭐ 進階用法: ☄️ 可虛擬化簡稱
    kubectl exec -it $(kubectl get pods -l app=python-app -o name) -- bash
    kubectl exec -it $(kubectl get pods -l app=postgres -o name) -- bash

    # 直接進入 psql 終端機
    kubectl exec -it $(kubectl get pods -l app=postgres -o name) -- psql -U postgres
    
    # 查看儲存資源
    kubectl exec -it $(kubectl get pods -l app=postgres -o name) -- df -h

    # 確認環境變數是否被確實注入( 查看敏感訊息... )
    kubectl exec -it $(kubectl get pods -l app=postgres -o name) -- env
    kubectl exec -it $(kubectl get pods -l app=python-app -o name) -- env

☄️ 建議直接透過 Helm 統一管理
    # 若有動到 configmap.yaml 優雅重啟
    kubectl rollout restart deployment python-app

    # 強制移除節點
    kubectl delete pod -l app=postgres
    -- 預期 Python Log 會顯示開始報錯重試，直到 K8s 自動把 Postgres Pod 重啟回來後，連線又會恢復

# 檢查 Service 關聯到的端點 ( Endpoints )
kubectl get endpoints postgres-service

⭐⭐⭐ [ 病歷表 ] 檢查具體噴錯原因
kubectl describe pod portainer-59cf9d8764-mg54l
    # 虛擬化名稱
    kubectl describe pod -l app=portainer

⭐ 刪除目前的 Pod ( Deployment 自動開一個新的並重新拉取 )
kubectl delete pod portainer-59cf9d8764-86m7h
    # 虛擬化名稱
    kubectl delete pod -l app=portainer

# 標籤問題
    # 查看所有標籤
    kubectl get nodes --show-labels
    
    ⭐ # 特定標籤 ( service )
    kubectl get nodes -L service-type
    
⭐ 刪除異常節點 ( 幽靈 )
kubectl delete node <node name>

# ⚠️ 簡化指令
    # 編輯設定檔
    nano ~/.bashrc
    
    # 檔案末尾加入
    alias k='kubectl'
    
    # 生效設定檔
    source ~/.bashrc
    
# [X] ⭐ Ingress 導引 (k3s)
    sudo mkdir -p /var/lib/rancher/k3s/server/manifests/
    sudo rm /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
    sudo cat /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
    sudo nano /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
    kubectl rollout restart deployment/traefik -n kube-system
    kubectl delete pod -n kube-system -l app.kubernetes.io/name=traefik
    kubectl logs -n kube-system -l app.kubernetes.io/name=traefik -f
    
    # 查看 Traefik 是否在 HTTPS (443) 上有回應
    curl -kvI https://gitlab.k8s.local
```
  
<br>

### *C.　Install Helm*
```
# 透過管道把下載下來的腳本內容，直接丟給 bash 直譯器去執行，而不在硬碟留下 .sh 檔案
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 可確認被丟到哪去
which helm
```
  
#### *>>　使用方式*
```
# 部署方式 ( 啟動/更新/移除 )
    ⭐ [1] 啟動/更新 Helm 部署 ( DEV 設置 ) + 外部傳入設定: image tags
    helm upgrade --install my-dev-release ./helm/app-stack -f ./helm/app-stack/values-dev.yaml --set image.tag=v1
    
    # [2.1] 先解除安裝
    helm uninstall my-dev-release
    
    # [2.2] 再重新安裝
    helm install my-dev-release ./helm/app-stack -f ./helm/app-stack/values-dev.yaml
    
⭐ 查看目前的 release 列表與版本次數 ( REVISION )
helm list

    ⭐ 查看該 release 的詳細歷史紀錄
    helm history my-dev-release

# 一次性刪除該 Release 下所有的 Service, Deployment, ConfigMap, Ingress
helm uninstall my-dev-release
```

<br>

### *D.　Install MiniKube*
```
# 1. 下載最新版的 MiniKube 二進位檔
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# 2. 安裝至系統路徑 ( 同時重新命名為 minikube )
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 3. 清理：刪除當前目錄下的下載檔
rm minikube-linux-amd64

# 4. 驗證
minikube version
```

#### *>>　使用方式*
```
# 若要訪問對外開口的應用
    # 1. 確認取得 minikube ip
    minikube ip
    
    # 2. 嘗試從 WSL2 內訪問 ( 假設 Ingress Host 設定為 myapp.local )
    curl -H "Host: myapp.local" $(minikube ip)
```

<br>

### *E.　Install K3d*
```
安裝 + 驗證
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d --version
```

<br>

### *F.　Install K3s*
```
參考說明檔 docs/k3s.md
```

<br>

### *G.　WSL2 ENV. Startup VM*
```
# [手動] VM 網路
    # 1. 初始化  (k3s_net)
    sudo virsh net-define /etc/libvirt/qemu/networks/k3s_net.xml
        
    # 2. 啟動虛擬網路 (k3s_net)
    sudo virsh net-start k3s_net
    
    # 3. 設定網路「開機自動啟動」，避免下次重啟又進鬼打牆循環 (k3s_net)
    sudo virsh net-autostart k3s_net
    
    # 關閉自動啟動 (k3s_net)
    sudo virsh net-autostart k3s_net --disable
    
    # 4. 驗證網路狀態，確保 State 顯示為 active，Autostart 顯示為 yes
    sudo virsh net-list --all
    
    # * 檢視設定
    sudo virsh net-info k3s_net
    
    ⭐ 檢視 dhcp 分配狀態是否如預期
    virsh net-dhcp-leases k3s_net
    
    # * 刪除舊定義 (k3s_net)
        # 1. 強制刪除網卡
        sudo ip link set virbr1 down 2>/dev/null
        sudo ip link delete virbr1 2>/dev/null
        
        # 2. 清理 Libvirt 網路定義
        sudo virsh net-destroy k3s_net 2>/dev/null
        sudo virsh net-undefine k3s_net 2>/dev/null
        
        # 3. 刪除 Libvirt 自動產生的 DHCP/DNS 狀態檔
        sudo rm -rf /var/lib/libvirt/dnsmasq/k3s_net.conf
        sudo rm -rf /var/lib/libvirt/dnsmasq/k3s_net.status
        sudo rm -rf /var/lib/libvirt/network/k3s_net.xml
        
        # 4. 重啟 Libvirt 服務以刷新所有內部狀態
        sudo systemctl restart libvirtd
    
    # * 建立設定檔 (k3s_net)
    sudo cat /etc/libvirt/qemu/networks/k3s_net.xml
    sudo nano /etc/libvirt/qemu/networks/k3s_net.xml
    

# [手動] 固定 VM 網路 IP # 手動 ( terraform 全自動 )
sudo virsh net-edit default
    # 編輯
    <network>
      <name>default</name>
      ...
      <dhcp>
        <range start='192.168.122.2' end='192.168.122.254'/>
        <host mac='52:54:00:00:00:00' name='k3s-node-0' ip='192.168.122.10'/>
      </dhcp>
    </network>


# VM 指令集
    # UI 視窗 
    virt-manager
    
    # 查看所有正在運行的 VM
    sudo virsh list --all
    
    # 查看 VM 詳細規格 ( ex: k3s-node-0 )
    sudo virsh dominfo k3s-node-0
    
    # 查看 VM 日誌 ( ex: k3s-node-0 )
    sudo virsh console k3s-node-0
    
    # 查看 ISO 路徑 ( ex: k3s-node-0 )
    sudo virsh domblklist k3s-node-0
    
    # 重啟裝置 ( ex: k3s-node-0 )
    sudo virsh reset k3s-node-0
    
    # 強制關閉並刪除 libvirt 中殘留的虛擬機定義 ( ex: k3s-node-0 )
    sudo virsh destroy k3s-node-0 || true
    sudo virsh undefine k3s-node-0 || true
```

<br><br><br>
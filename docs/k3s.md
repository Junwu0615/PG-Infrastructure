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
    - 網路： K3s 在真實環境中會接觸到 SSH、實體網路介面、Firewall (ufw/iptables)
    - 儲存： K3d 的 Persistent Volume 是掛載 Docker Volume，K3s 則會直接掛載 Linux 主機的目錄
    - 負載平衡： K3s 內建 Service LB，但在實體環境可能需要搭配 MetalLB 才能獲得真實的 External IP
```

<br>

### *B.　VM 環境準備*
```
選擇 VM 工具
    >> ✅ Oracle VirtualBox ( 開源; 支援 Windows、Linux、macOS )
        - https://www.virtualbox.org/
        
    >> QEMU / KVM ( 開源; Linux 核心原生的虛擬化技術 )
    
    >> VMware Workstation Player ( 個人免費 )
        - https://support.broadcom.com/

作業系統
    >> Ubuntu Server ISO ( 建議 24.04 LTS 版 )
        - https://ubuntu.com/download/server
        
    >> ✅ Debian ISO ( 穩定版 Debian 12; 比 Ubuntu 更輕量，適合當 K3s 節點 )
        - https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso

資源設置 ⚠️ [ 人工 => Terraform + Ansiable ]
    >> 3 台虛擬機: OS: Debian ISO ( 無 GUI 版本，節省資源 )
    >> 硬體分配：
            [1] Master 節點： 2 vCPU, 2GB RAM, 磁碟大小 40GB
            [3] Worker 節點： 1 vCPU, 1GB RAM, 磁碟大小 30GB
    >> 網路模式： 選擇 ✅ Bridge 或 Host-Only，確保 VM 互通且 IP 固化
    
    >> ✅ SSH server
    >> ✅ standard system utilities
    >> ✅ Guest Additions (客體額外功能) ISO ( 共享剪貼簿 / 共享資料夾 / 自動縮放螢幕 / 滑鼠整合... )
    >> ❌ Debian desktop environment
    >> ❌ 無人值守安裝
    
    >> 敏感設置:
        [Master Node] acc: master; pwd: 0000
        [Worker Node] acc: node; pwd: 123456
        

其他
    >> 進階體驗工具： Multipass ( 微型 VM 管理器 ) # ⚠️ 優先 [Terraform + Ansiable]
```



### *B.　建立單節點 ( Master Node )*
```
# 獲取存取權限 => 當前使用者可以操作 kubectl

# 映像檔遷移問題

# Install K3s
curl -sfL https://get.k3s.io | sh -

# 取得加入節點用的 Token
sudo cat /var/lib/rancher/k3s/server/node-token

# 可檢視機器名字出現在列表
kubectl get nodes
```

<br>

### *C.　多節點 ( Worker Node )*
```    
# 第 1 - N 台
curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_IP>:6443 K3S_TOKEN=<NODE_TOKEN> sh -
```

<br>

### *D.　測試驗證*
```
👁️ 測試 15：橫向自動伸縮 (HPA - Horizontal Pod Autoscaler)

👁️ 測試 16：持久化儲存與節點漂移 (PV / PVC / Local Path)

👁️ 測試 17：Ingress 流量入口 (Traefik)
```

<br><br><br>
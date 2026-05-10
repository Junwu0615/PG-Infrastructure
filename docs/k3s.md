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
        [Worker Node] acc: worker; pwd: 123456
        

其他
    >> 進階體驗工具： Multipass ( 微型 VM 管理器 ) # ⚠️ 優先 [Terraform + Ansiable]

    
------
VM 環境測試
    >> ping google.com
    >> 安裝必要工具：sudo, curl, vim
    >> 帳號加入 sudo 權限
        - su -  # 切換成 root ( 當初留空會無法使用; 用 sudo -i 繞過去 )
        - apt update # 更新軟體清單
        - apt install open-vm-tools -y # 可複製貼上 ( 未來直接依賴 SSH 操控; 不再進入 VM )
        - apt install sudo curl vim -y
        - apt install openssh-server -y # 安裝 SSH 伺服器
        - systemctl enable --now ssh # SSH 啟動並設定開機自啟
        - usermod -aG sudo master
        - exit  # 重新登入生效
    >> K3s 必要工具
        - sudo apt install git net-tools htop -y
    
    
Windows SSH 公鑰傳進 VM ( 免密碼登入 )
    >> 產生 SSH Key ( 一路按 Enter 到底 )
        - ssh-keygen -t ed25519
    >> 將 Key 傳送到 VM ( master 改成目標帳號 )
        - cat ~/.ssh/id_ed25519.pub | ssh master@192.168.0.17 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
    >> 手動一步步來
        - master@master:~$ mv ~/.ssh/authorized_keys ~/.ssh/authorized_keys.bak
        - master@master:~$ nano ~/.ssh/authorized_keys
                <金鑰 # cat $HOME\.ssh\id_ed25519.pub # 複製貼上>
        - master@master:~$ cat ~/.ssh/authorized_keys
        - master@master:~$ chmod 700 ~/.ssh
        - master@master:~$ chmod 600 ~/.ssh/authorized_keys
        - master@master:~$ chown -R master:master ~/.ssh
        - master@master:~$ chmod 755 /home/master
        
------
⚠️ 設置 VM 固定 IP 位置
# 既有連線更動
    # 1. 查看目前的連線名稱 ( 有坑: enp0s3 )
    sudo nmcli connection show
    # 應該會看到 "Wired connection 1"
    
    # 2. 修改為靜態 IP (請將 192.168.0.15 改成你想要的 IP)
    sudo nmcli connection modify "Wired connection 1" ifname enp0s3 ipv4.addresses 192.168.0.15/24 ipv4.gateway 192.168.0.1 ipv4.method manual
    
    # 3. 設定 DNS
    sudo nmcli connection modify "Wired connection 1" ifname enp0s3 ipv4.dns "8.8.8.8,1.1.1.1"
    
    # 4. 重新啟動連線以生效
    sudo nmcli connection up "Wired connection 1"

# 刪除既有連線重建
    # 1. 刪除所有現有的有線連線設定
    sudo nmcli connection delete "Wired connection 1"
    
    # 2. 建立一個全新的連線，並直接綁定到 enp0s3
    [手動]
    sudo nmcli connection add type ethernet con-name my-net ifname enp0s3 ipv4.method manual ipv4.addresses 192.168.0.15/24 ipv4.gateway 192.168.0.1 ipv4.dns "8.8.8.8,1.1.1.1"
    [自動獲取 IP]
    sudo nmcli connection add type ethernet con-name my-net ifname enp0s3 ipv4.method auto ipv4.dns "8.8.8.8,1.1.1.1"
    
    # 3. 啟動它
    sudo nmcli connection up my-net


# 確認設定檔布林
cat /etc/NetworkManager/NetworkManager.conf
確認欄位 managed
    # 若是 False ... false => true
    sudo nano /etc/NetworkManager/NetworkManager.conf
    # 重啟服務
    sudo systemctl restart NetworkManager

# ⚠️ 確認 VM 網卡上的真正 IP ( enp0s3 / ens33)
ip addr show enp0s3

# ⚠️ 確認 VM Gateway
ip route

#  ⚠️ 確認 SSH 是否在監聽
sudo ss -tunlp | grep :22

------
ssh username@vm-ip
- 先確認
    - 通常沒防火牆正常: sudo ufw status
    - VM SSH 是否生效: sudo systemctl status ssh
    - 將 IP 位置調整與本地一致
        - [X] sudo nano /etc/network/interfaces
        - [O] ⚠️ 設置 VM 固定 IP 位置
- username = 安裝過程中建立的那個使用者帳號
    - whoami 可確認 ( 可全部固定同一組? )
- vm-ip = 主開發機位置 ( ex: 192.168.0.15 ) or VM 自己設一個位置
    - Master       : ssh master@192.168.0.17
             

⚠️ 設定裝置對外名稱 ( 可覆蓋 ): 
sudo hostnamectl set-hostname master
sudo hostnamectl set-hostname worker1
sudo hostnamectl set-hostname worker2
sudo hostnamectl set-hostname worker3

------
⚠️ Clone Master 前最後一次設定檢查
>> 時區設定
    - sudo timedatectl set-timezone Asia/Taipei
    
>> 停用 Swap ( K3s/K8s 必做 )
    - sudo swapoff -a
    
    # 編輯 /etc/fstab，把包含 swap 的那行開頭加個 # 註釋掉
        - sudo nano /etc/fstab
    
>> 安裝 K3s 所需的最後組件
    - sudo apt install -y nfs-common


開啟 Worker ( ⚠️ Clone Master ) ex: worker1
    >> 修改 IP ( 先確認是否須修正: ip addr show enp0s3 )
        sudo nmcli connection modify net ipv4.addresses 192.168.0.18/24
        sudo nmcli connection up net
    
    >> 修改 Hostname [ 影響用戶顯示: master@<???>:~$ exit ]
        sudo hostnamectl set-hostname worker1
        sudo reboot
        
------ 
* 外部連線清單如下
- K3s Server ( master@master  ): ssh master@192.168.0.17
- K3s Agent  ( master@worker1 ): ssh master@192.168.0.18
- K3s Agent  ( master@worker2 ): ssh master@192.168.0.19
- K3s Agent  ( master@worker3 ): ssh master@192.168.0.20
```

<br>

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

### *D.　環境挑戰*
```
1. 跨機通訊
    >> k3d: 所有東西都在同一個 Docker Network
    >> VM 環境：
        - 防火牆： Master 的 6443 埠 ( API Server ) 必須開給 Worker
        - Kubeconfig： 把 Master 裡的 /etc/rancher/k3s/k3s.yaml 
            拷貝到主開發機 ( Win 11 ) 的 .kube/config，使可直接在 Windows 操控 VM 裡的集群

2. 
```

<br>

### *E.　測試驗證*
```
👁️ 測試 15： 橫向自動伸縮 (HPA - Horizontal Pod Autoscaler)

👁️ 測試 16： 持久化儲存與節點漂移 (PV / PVC / Local Path)

👁️ 測試 17： Ingress 流量入口 (Traefik)
```

<br><br><br>
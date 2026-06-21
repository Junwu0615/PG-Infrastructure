## *K3s*


### *A.　部署框架演進*
```
Evolution: MiniKube ➔ K3d ➔ ✅ K3s ➔ K3s Migration ➔ Kubeadm ➔ GKE

Summary:
    # Ingress 坑: 如何讓對外開放服務打通管道
    # 👁️ 測試 15 - 16

------

當從 MiniKube 進化到 K3s + VM 時，生命週期的管理對象會改變：
    - Terraform 階段：負責機器的「生與死」（ 建立 VM 或銷毀 VM ）
    - Ansible 階段：負責機器的「初始化」（ 安裝 K3s、設定 Ingress ）
    - K8s 本身：一旦機器開著，K8s 服務就是常駐的（ Daemon ），不再需要手動 start 它
    

k3d → k3s
* K3d： 適合開發、測試 Helm 邏輯、練習節點調度
* K3s： 適合部署在 VM 或實體機（ 如 Raspberry Pi ）上
* 差異點：
    - 網路： K3s 在真實環境中會接觸到 SSH、實體網路介面、Firewall ( ufw/iptables )
    - 儲存： K3d 的 Persistent Volume 是掛載 Docker Volume，K3s 則會直接掛載 Linux 主機的目錄
    - 負載平衡： K3s 內建 Service LB，但在實體環境可能需要搭配 MetalLB 才能獲得真實的 External IP
```

<br>

### *B.　創建 VM 環境*
<details>
<summary><b><i> b.1.　Manual </i></b></summary>
<ul>

#### *準備 VM 環境*
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

資源設置 ⚠️ [ 人工 → Terraform + Ansiable ]
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
        [Master] acc: master; pwd: 0000
        [Worker] ⚠️ Clone Master
        

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
    # 若是 False ... false → true
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
    
>> 取消 sudo 密碼認證
    # sudo visudo ( 必須是末尾加上底下這行 / 不然會被蓋掉設定 )
    - master  ALL=(ALL) NOPASSWD:ALL


開啟 Worker ( ⚠️ Clone Master ) ex: worker1
    >> 修改 IP ( 先確認是否須修正: ip addr show enp0s3 )
        sudo nmcli connection modify net ipv4.addresses 192.168.0.18/24
        sudo nmcli connection up net
    
    >> 修改 Hostname [ 影響用戶顯示: master@<???>:~$ exit ]
        sudo hostnamectl set-hostname worker1
        sudo reboot
        
        
⚠️ FIXME
設置讓 VM 定時 Ping 宿主機 ( 因為會遇到"虛擬機網路深度睡眠" )
    >> sudo crontab -e
    >> * * * * * ping -c 1 192.168.0.15 > /dev/null 2>&1
        
------ 
* ✅ 外部連線清單如下
- K3s Server ( master@master  ): ssh master@192.168.0.17
- K3s Agent  ( master@worker1 ): ssh master@192.168.0.18
- K3s Agent  ( master@worker2 ): ssh master@192.168.0.19
- K3s Agent  ( master@worker3 ): ssh master@192.168.0.20
```

<br>

#### *Master / Worker*
```
* 可直接透過 "外部開發機" 用 SSH 依序進入設定配對

1. 設定配對
>> Master
    # Install K3s
    curl -sfL https://get.k3s.io | sh -
    
    # ⚠️ 取得 Token ( Worker TOKEN )
    sudo cat /var/lib/rancher/k3s/server/node-token

>> Worker ( 第 1 - 3 台 )
    curl -sfL https://get.k3s.io | K3S_URL=https://192.168.0.17:6443 K3S_TOKEN=<Worker TOKEN> sh -


2. 打通外部主機 kubectl ( Windows / WSL2 → VM)
    # [Master] 手動複製配置
    sudo cat /var/lib/rancher/k3s/server/k3s.yaml
    
    # [外部開發機] 貼上配置 | 小調整 https://127.0.0.1:6443 → https://192.168.0.17:6443
    nano ~/.kube/config-k3s-vm

    # 獲取存取權限 → 當前使用者可以操作 kubectl
    # 設定 kubectl 識別的 k8s 設定 ( 改為 k3s )
        [短期]
        export KUBECONFIG=~/.kube/config-k3s-vm
        
        [長期]
        echo 'export KUBECONFIG=$HOME/.kube/config-k3s-vm' >> ~/.bashrc
        source ~/.bashrc
    
    # 測試是否監控成功 ( 可檢視機器名字出現在列表 )
    kubectl get nodes -o wide
```

<br>

#### *外部開發機 ( Ansible )*
```
# ⚠️ SSH KEY 傳入
    # 對四台機器執行 (只需執行一次)
    ssh-copy-id master@192.168.0.17
    ssh-copy-id master@192.168.0.18
    ssh-copy-id master@192.168.0.19
    ssh-copy-id master@192.168.0.20

# ⚠️ 統一下發 ping 測試 
ansible all -i ./ansible/inventory.ini -m ping

------
✅ 手動運維 → 代碼定義基礎設施 (IaC) 領域


# 1. 系統健康檢查與環境初始化
ansible-playbook -i ./ansible/inventory.ini ansible/playbooks/init_nodes.yml


# 2. 部署 k3s
    - 在 Master 安裝 K3s 並提取 Token
    - 將 Token 動態發送給所有 Worker
    - 讓所有 Worker 自動加入 Master 形成集群
ansible-playbook -i ./ansible/inventory.ini ansible/playbooks/deploy_k3s.yml

# ✅ 確認整體節點是否都歸對
kubectl get nodes -o wide

$ kubectl get nodes -o wide
NAME      STATUS   ROLES           AGE   VERSION        INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION        CONTAINER-RUNTIME
master    Ready    control-plane   53m   v1.35.4+k3s1   192.168.0.17   <none>        Debian GNU/Linux 13 (trixie)   6.12.86+deb13-amd64   containerd://2.2.3-k3s1
worker1   Ready    <none>          50m   v1.35.4+k3s1   192.168.0.18   <none>        Debian GNU/Linux 13 (trixie)   6.12.86+deb13-amd64   containerd://2.2.3-k3s1
worker2   Ready    <none>          50m   v1.35.4+k3s1   192.168.0.19   <none>        Debian GNU/Linux 13 (trixie)   6.12.86+deb13-amd64   containerd://2.2.3-k3s1
worker3   Ready    <none>          50m   v1.35.4+k3s1   192.168.0.20   <none>        Debian GNU/Linux 13 (trixie)   6.12.86+deb13-amd64   containerd://2.2.3-k3s1


# 3. 部署實際服務測試
make deploy ver=v5
    # 可發現不成功 因為還沒貼在 k3d 設置的標籤

    # 貼標籤 ( 有改動標籤配置 ) | ⚠️ Master 不跑業務
    kubectl label nodes worker1 service-type=app --overwrite
    kubectl label nodes worker2 service-type=app --overwrite
    kubectl label nodes worker3 service-type=service --overwrite
    
    # 確認標籤
    kubectl get nodes -L service-type


# 4. 映像檔遷移問題 ( ImagePullBackOff ) # 速解
[開發機]
    # image 存成 tar 檔
    docker save my-python-app:v5 > my-python-app.tar
    
    # scp 傳給 [APP 標籤 Worker]
    scp my-python-app.tar debian@192.168.122.193:~
    scp my-python-app.tar debian@192.168.122.29:~
    
[APP 標籤 Worker] # 有 2 台
    sudo k3s ctr images import ~/my-python-app.tar
    
# ✅ 確認整體節點分配狀態 | APP 分別丟向 2 個節點 | SERVICE 固定 Worker3
$ kubectl get -w pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE   IP          NODE      NOMINATED NODE   READINESS GATES
portainer-564755cdd-hd8fq      1/1     Running   0          10m   10.42.1.5   worker3   <none>           <none>
postgres-db-64b54dd94b-n5hzk   1/1     Running   0          10m   10.42.1.4   worker3   <none>           <none>
python-app-655f997bbd-sw9dl    1/1     Running   0          58s   10.42.4.4   worker1   <none>           <none>
python-app-655f997bbd-tzs7z    1/1     Running   0          51s   10.42.3.4   worker2   <none>           <none>

# 檢視 logs 
kubectl logs -f -l app=python-app --tail=5
```

</ul>
</details>


<details>
<summary><b><i> b.2.　Auto </i></b></summary>
<ul>

#### *Terraform*
```
* 腳本動作
    >> Terraform 會下載 Debian 鏡像 
        ( OS 映像檔: 使用 Debian 12 Generic Cloud Image # 比 ISO 更快，專為自動化設計 )
    >> 建立 3 台 VM 並透過 cloud-init 寫入你的公鑰
    >> 自動將 IP 寫入 ansible/inventory.ini
    >> 自動執行 Ansible 完成 K3s 叢集


.
├── ansible
│   ├── ansible.cfg          # SSH 與連線優化
│   ├── group_vars
│   │   └── all.yml          # 定義 k3s_token 等變數
│   ├── inventory.ini        # [由 Terraform 自動生成]
│   └── playbooks
│       ├── site.yml         # 總入口腳本 ( 調度 init_nodes + deploy_k3s )
│       ├── init_nodes.yml   # 節點預處理 ( Swap, Bridge )
│       ├── deploy_k3s.yml   # K3s 核心安裝邏輯
│       └── power_manage.yml
└── terraform
    ├── provider.tf          # 定義 Provider 與版本
    ├── main.tf              # 資源定義 ( VM, Disk, Network )
    ├── inventory.tftpl      # 模板供 main.tf 引用
    ├── variables.tf         # 變數定義 ( CPU, RAM, 公鑰路徑 )
    ├── terraform.tfvars     # 實際數值
    ├── cloud_init.cfg       # Cloud-init 模板
    └── outputs.tf           # 定義輸出 IP


------
sudo apt update

# ✅ 建立 Cloud-Init 所需的 ISO 鏡像時，負責產生 ISO 檔案的工具
sudo apt install -y genisoimage

# ✅ 視覺化界面 Virt-Manager ( 直接輸入: 👁️ virt-manager )
sudo apt install -y virt-manager
    # 查看所有正在運行的 VM
    >> sudo virsh list --all
    
    # 查看 VM 詳細規格
    >> sudo virsh dominfo k3s-node-0
    
    # 查看 VM 日誌
    >> sudo virsh console k3s-node-0
    
    # 查看 ISO 路徑
    >> sudo virsh domblklist k3s-node-0
    
    # 重啟裝置
    >> sudo virsh reset k3s-node-0

# ✅ 安裝 Libvirt 虛擬化組件
    # 更新並安裝虛擬化套件
    sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst libvirt-daemon qemu-utils
    
    # 啟動服務
    sudo systemctl start libvirtd
    sudo systemctl enable libvirtd
    
    # 將自己加入權限群組 ( 執行後需登出再登入，或執行 newgrp libvirt )
    sudo usermod -aG libvirt $USER
    sudo usermod -aG kvm $USER
    
------
# ✅ 啟動 libvirtd 服務 ( Terraform 腳本依賴 ... Libvirt 通訊 Socket )
    sudo systemctl enable --now libvirtd
    sudo systemctl status libvirtd

# ✅ 權限設定
    # 確保權限有在 libvirt 群組中
    sudo usermod -aG libvirt $USER
    # 執行後請重新登入或下達以下指令使群組生效
    newgrp libvirt

# ✅ 檢查 Default Pool
    # 確認清單
    sudo virsh pool-list --all
    
    # 若沒啟動
    sudo virsh pool-start default
    
    # 若 pool-list 是空的 
        # 1. 建立存儲目錄並定義 Pool
        sudo mkdir -p /var/lib/libvirt/images
        sudo virsh pool-define-as --name default --type dir --target /var/lib/libvirt/images
        
        # 2. 啟動並設定開機自啟
        sudo virsh pool-start default
        sudo virsh pool-autostart default
        
        # 3. 驗證 (State 應為 running)
        sudo virsh pool-list --all

------
cd terraform

sed -i 's/\r$//' main.tf
sed -i 's/\r$//' cloud_init.cfg

# 初始化/更新
terraform init --upgrade

# 安裝環境
terraform apply -auto-approve

# 拆環境
terraform destroy

------
ssh debian@$(terraform output -raw master_ip)
ssh debian@192.168.122.97
ssh debian@192.168.122.87

# ✅ 測試是否監控成功
echo 'export KUBECONFIG=~/.kube/config-k3s' >> ~/.bashrc
source ~/.bashrc
        
kubectl get nodes
NAME         STATUS   ROLES                AGE     VERSION
k3s-node-0   Ready    control-plane,etcd   3m45s   v1.35.4+k3s1
k3s-node-1   Ready    <none>               3m7s    v1.35.4+k3s1
k3s-node-2   Ready    <none>               3m33s   v1.35.4+k3s1
```

</ul>
</details>

<br>


### *C.　Makefile Command*
```
Terraform:
    # 初始化 terraform 配置
    make init
    
    # 安裝 VM 環境 ( 包括: deploy_k3s.yml + init_nodes.yml ) → SSH 無密碼登入
    make apply VAR_FILE=./terraform.tfvars
    
    # 拆除 VM 環境
    make destroy

Ansible:
    # 檢視狀態 ( pods + nodes )
    make status
    
    # VM 開機 ( K3s 集群 )
    make vm-power action=start
    
    # VM 關機 ( K3s 集群 )
    make vm-power action=stop
    
    # VM 重新啟動 ( K3s 集群 )
    make vm-power action=reboot

Kubectl ( k ):
    # 標籤設置，節點 0 為 Master，接著 2 個節點的 service-type 為 app，其餘為 service
    make label-nodes app=2
    
Helm:
    # [暫時] 塞本地 imags 到 VM
        make save IMAGE_NAME=my-python-app TAG=v5 TAR_FILE=my-python-app.tar
        make load-images TAR_FILE=my-python-app.tar
    
    # 部署 v5 版本測試腳本
    make deploy ver=v5
```

<br>

### *D.　測試驗證*
```
👁️ 持續觀察 K8s 如何分配任務: kubectl get pods -w -o wide

👁️ 測試 15： Ingress 流量入口 ( Traefik )

    * 單一環境連線路徑:

        Chrome Browser <localhost:8080>
        ↓
        
        Windows
        
        ↓  PortProxy <TRANSFER: 80 / 443 / 5432>
        
        WSL2  <172.28.113.34>
        
        ↓  Socat <TRANSFER: 80 / 443 / 5432>
        
        ingress-nginx <10.88.0.20> <LISTEN: 80 / 443 / 5432> 
        ↓
        
        Ingress Rule
        ↓
        
        pod-server
        
        # ⚠️ STEP 1 安裝 ingress-nginx ( 不採用 Traefik )
            # 安裝 ingress-nginx
                # kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml
                
            # 修改 Service 為 NodePort
                # kubectl edit svc ingress-nginx-controller -n ingress-nginx
                # 改配置
                    type: NodePort
                    
                    ports:
                    - appProtocol: http
                        name: http
                        nodePort: 30161
                        port: 80
                        protocol: TCP
                        targetPort: http
                    - appProtocol: https
                        name: https
                        nodePort: 32109
                        port: 443
                        protocol: TCP
                        targetPort: https
                        
            # 驗證: kubectl get svc -n ingress-nginx
            NAME                                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
            ingress-nginx-controller             NodePort    10.43.169.19   <none>        80:30161/TCP,443:32109/TCP   3m43s
        
        # STEP 2 Expose ingress controller
            # Disable Traefik
                # sudo cat /etc/rancher/k3s/config.yaml
                # sudo nano /etc/rancher/k3s/config.yaml
                # sudo systemctl restart k3s
      
        # STEP 3 WSL 開 port forward
            # [不推薦] 手動 # 視窗不能關
                sudo socat TCP-LISTEN:80,fork TCP:10.88.0.20:30161
                sudo socat TCP-LISTEN:443,fork TCP:10.88.0.20:32109
                
            # 背景常駐
                # 安裝 socat
                sudo apt update
                sudo apt install socat -y
                    # 確認安裝狀態
                    $ which socat
                    /usr/bin/socat
                                
                    # WSL2 監聽查詢 ( 預期如下 )
                    $ sudo ss -ltnp | grep :80
                    LISTEN 0      5                   *:80               *:*    users:(("socat",pid=202306,fd=5))
                
                # 建立檔案
                sudo cat /etc/systemd/system/k8s-http-proxy.service
                sudo nano /etc/systemd/system/k8s-http-proxy.service
                
                sudo cat /etc/systemd/system/k8s-https-proxy.service
                sudo nano /etc/systemd/system/k8s-https-proxy.service
                
                # 啟動
                sudo systemctl daemon-reload
                sudo systemctl enable --now k8s-http-proxy
                sudo systemctl enable --now k8s-https-proxy
                    * 重啟
                    sudo systemctl restart k8s-http-proxy
                    sudo systemctl restart k8s-https-proxy
                
                # 驗證 1 # 預期得到 404 Not Found
                curl http://10.88.0.20:30161
                
                # 驗證 2
                systemctl status k8s-http-proxy
                systemctl status k8s-https-proxy
                
                # 驗證 3
                curl http://localhost
                
                * 檢視 ps aux | grep socat
                
                * 關閉 + 停止
                sudo systemctl stop k8s-http-proxy
                sudo systemctl stop k8s-https-proxy
                sudo systemctl disable k8s-http-proxy
                sudo systemctl disable k8s-https-proxy
            
        # STEP 4 Windows → WSL2
            # 先不用 80 改用 8080; 查詢目前是否有被占用; 若無直接往下; 若有進行排除或擇別的port
            netstat -ano | findstr :8080
        
            ⭐ ip addr show eth0 ( 查詢得到: 172.28.113.34 )
            $ ip addr show eth0
            2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
                link/ether 00:15:5d:92:5b:06 brd ff:ff:ff:ff:ff:ff
                inet 172.28.113.34/20 brd 172.28.127.255 scope global eth0
                   valid_lft forever preferred_lft forever
                inet6 fe80::215:5dff:fe92:5b06/64 scope link
                   valid_lft forever preferred_lft forever
            
            # [管理員] Windows Admin PowerShell ( 替換查到 IP )
            netsh interface portproxy add v4tov4 `
                listenaddress=0.0.0.0 `
                listenport=8080 `
                connectaddress=172.28.113.34 `
                connectport=80
                
            netsh interface portproxy add v4tov4 `
                listenaddress=0.0.0.0 `
                listenport=443 `
                connectaddress=172.28.113.34 `
                connectport=443
                
                # 刪除方式
                netsh interface portproxy delete v4tov4 listenport=80 listenaddress=0.0.0.0
                netsh interface portproxy delete v4tov4 listenport=443 listenaddress=0.0.0.0
                
            # 驗證
            PS C:\WINDOWS\system32> netsh interface portproxy show all
            Listen on ipv4:             Connect to ipv4:
            Address         Port        Address         Port
            --------------- ----------  --------------- ----------
            192.168.0.15    8090        172.28.113.34   8090
            192.168.0.15    5100        172.28.113.34   5100
            0.0.0.0         8080        172.28.113.34   80
            
        # STEP 5 修改 Windows Hosts 檔案 ( k3s/archive/win_hosts )
            # 用 [管理員] powershell 叫起來 否則有權限問題
            notepad C:\Windows\System32\drivers\etc\hosts
            
            # 增加底下格式
            127.0.0.1 portainer.k8s.local
        
        # STEP 6 Ingress YAML
        # STEP 7 Test: http://portainer.k8s.local
    
    0. 進行前置作業 ( 單一環境連線路徑 )
    
    1. 檢查 Ingress 狀態
    kubectl get ingress -A
        
    2. 有更新過 ingress ( # helm/app-stack/templates/ingress.yaml ) 則再次部署
    make deploy ver=v5
    
    3.1. 訪問測試
    curl -v -H "Host: portainer.k8s.local" http://10.88.0.20:30161
    
    3.2. 訪問測試
    http://portainer.k8s.local
    
    * 若是觸發防護機制 則砍掉節點讓 k8s 重生它
    kubectl delete pod -l app=portainer


👁️ 測試 16： 高可用單一實例 ( HA Singleton )
    情境: 實現平時只有一個在跑，掛了自動在另一台補上的 HA 候補機制
    於 app/app-deploy.yaml 進行設置
    
    1. 啟動後剩 1 個 python-app 節點再跑
    2. 強制砍節點
    3. 候補即替上 ( 替補上的 pod 非同個節點 )
    
    $ kubectl get pods -w -o wide
    NAME                           READY   STATUS    RESTARTS   AGE   IP          NODE         NOMINATED NODE   READINESS GATES
    portainer-564755cdd-rrd79      1/1     Running   0          47m   10.42.3.3   k3s-node-3   <none>           <none>
    postgres-db-64b54dd94b-8k2lq   1/1     Running   0          47m   10.42.4.3   k3s-node-4   <none>           <none>
    python-app-bd8c7d76-qcvb8      1/1     Running   0          10s   10.42.2.5   k3s-node-2   <none>           <none>
    python-app-bd8c7d76-qcvb8      1/1     Terminating   0          70s   10.42.2.5   k3s-node-2   <none>           <none>
    python-app-bd8c7d76-ggtgj      0/1     Pending       0          0s    <none>      <none>       <none>           <none>
    python-app-bd8c7d76-qcvb8      1/1     Terminating   0          70s   10.42.2.5   k3s-node-2   <none>           <none>
    python-app-bd8c7d76-ggtgj      0/1     Pending       0          0s    <none>      k3s-node-1   <none>           <none>
    python-app-bd8c7d76-ggtgj      0/1     ContainerCreating   0          0s    <none>      k3s-node-1   <none>           <none>
    python-app-bd8c7d76-ggtgj      0/1     Running             0          0s    10.42.1.6   k3s-node-1   <none>           <none>
    python-app-bd8c7d76-ggtgj      1/1     Running             0          6s    10.42.1.6   k3s-node-1   <none>           <none>


👁️ 測試 17： 橫向自動伸縮 ( HPA - Horizontal Pod Autoscaler )


👁️ 測試 18： 持久化儲存與節點漂移 ( PV / PVC / Local Path )
```

<br><br><br>
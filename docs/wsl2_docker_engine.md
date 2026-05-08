## *WSL2 原生 Docker 安裝方式*
### *A.　解除安裝舊版*
```
sudo apt-get remove docker docker-engine docker.io containerd runc
```

<br>

### *B.　安裝 Docker Engine*
```
# 解除安裝舊版
sudo apt-get remove docker docker-engine docker.io containerd runc


# 更新索引 + 安裝依賴
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release


# 加入 Docker 官方 GPG 金鑰
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg


# 設定 Docker 來源儲存庫
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# 更新索引 + 安裝 Docker 核心組件
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

<br>

### *C.　啟動 Docker 並設定權限*
```
# 啟動 Docker 服務
    # 法 1: SysVinit (傳統的腳本管理器)
    sudo service docker start
    # [推薦] 法 2: Systemd (現代 Linux 的總管)
    sudo systemctl start docker

# 將當前使用者加入 docker 群組，允許不使用 sudo 執行 docker 命令
sudo usermod -aG docker $USER

# [可選] 若無設定 systemd，可在 /etc/wsl.conf 加入以下設定：
    - sudo nano /etc/wsl.conf
    - [boot]
      systemd=true
      
# [可選] 如果想每次開機自動啟動 Docker
    # 法 1: 可把啟動指令加到 .bashrc
    echo "sudo service docker start" >> ~/.bashrc
    
    # [優雅] 法 2: 使用 systemd 啟動 (不過 WSL2 預設沒有 systemd，需先安裝並啟用)
    sudo systemctl enable docker
```

<br>

### *D.　停止 Docker Engine*
```
# 1. 停止服務
    # 法 1: sudo service docker stop
    # [推薦] 法 2: sudo systemctl stop docker

# 2. 徹底關閉，連自動觸發都不想要
sudo systemctl stop docker.socket

# 3. 確認沒有任何 docker 相關進程在跑
ps aux | grep docker

# [可選] 如果有設定自動啟動
    # 法 1: 刪除 .bashrc 新增的指令，避免下次打開又啟動
    nano ~/.bashrc
    
    # [優雅] 法 2: 使用 systemd 停止自動啟動
    # sudo systemctl disable docker

# [可選] 重新啟動 Docker 服務
sudo systemctl start docker
```

<br>

### *E.　[可選] 專門針對 WIN 環境的 WSL2 優化設定*
```
WIN + R: %UserProfile% # 打開使用者目錄
add .wslconfig # 在使用者目錄下創建 .wslconfig 文件，加入以下內容
wsl --shutdown # 重啟 WSL2 讓設定生效

htop # 觀察 CPU 資源情況，確保設定生效 (12核心)
free -h # 觀察 Total Memory 資源情況，確保設定生效 (16GB)

⭐ WIN 環境開鏡像後，可能會遇到連線衝突現象
# 1. 查詢 5432 Port 是否被 Windows 佔用
netstat -ano | findstr :5432

# 2. 假設結果如下
  TCP    127.0.0.1:5432         127.0.0.1:5820         FIN_WAIT_2      41120
  TCP    127.0.0.1:5820         127.0.0.1:5432         CLOSE_WAIT      10460

# 3. 強制砍連線
Stop-Process -Id 10460 -Force

# 4. 砍完後 docker 服務需重啟 接著再次測試是否正常
```
```
[wsl2]
# 風險: 記憶體被鎖死，Windows 崩潰
# 實際 RAM 16GB 的話，建議設定為 12GB，留給 Windows 4GB
memory=16GB

# 風險: CPU 被鎖死，Windows 崩潰
# 實際 CPU 8 核的話，建議設定為 6 核，留給 Windows 2 核
processors=12

# 風險: 網路斷連 ; 在鏡像模式下，WSL2 服務會直接暴露在 Windows 的網卡上
    - 優點： WSL2 直接共享 Windows 的 IP 地址，不再需要透過 NAT 轉換，網路延遲幾乎為零。
    - 大坑一（VPN）： 如果你電腦有開 VPN（如公司的 Cisco 或 GlobalProtect），mirrored 模式極大機率會導致 WSL2 徹底斷網。
    - 大坑二（服務衝突）： 如果 Windows 本身已經跑了一個 Postgres (5432 Port)，WSL2 裡的 Postgres 會因為 Port 衝突而啟動失敗（因為它們現在共用同一個 localhost）。
    - 大坑三（防火牆）： Windows Defender 有時會攔截鏡像模式下的流量，導致 Docker 容器間連不上。

# 測試: ping google.com
networkingMode=mirrored 

# 加上這兩行解決 mirrored 模式下常見的網路 Bug
dnsTunneling=true
firewall=true

# 允許從 Windows 直接訪問 WSL2 的 localhost，方便開發測試
localhostForwarding=true

[experimental]
# 自動回收快取記憶體，防止 VMMem 佔用不放
# 利用 Linux 內核的「頁面回收」機制，把沒用到的快取還給 Windows。這反而能保護你的 Windows 不會因為記憶體被 WSL2 鎖死而崩潰
autoMemoryReclaim=gradual

# 讓 WSL2 的磁碟寫入性能更接近原生 Linux
sparseVhd=true
```

<br>
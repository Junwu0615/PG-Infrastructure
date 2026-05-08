## *Kubernetes*

### *K9s*

- #### *A.　安裝方式*
```
curl -sS https://webinstall.dev/k9s | bash

安裝完後，重啟終端機或輸入 source ~/.config/envman/PATH.env 即可生效
```

- #### *B.　使用方式*
```
: ：輸入命令（例如 :pod 看 Pod, :node 看節點）

/ ：過濾關鍵字

d ：Describe（查看詳細描述）

l ：Logs（查看日誌）

esc ：返回上一層
```

<br>

### *MiniKube*
- #### *A.　說明*
```
k8s-manifests 是原始部署本方式
helm 是進階抽象部署方式 => 優先體驗
```

<br>

| K8s 組件 | 實作對應項目 | 核心作用 |
| --: | :-- | :-- | 
| Pod | Python 容器 / DB 容器 | K8s 最小調度單位，一個 Pod 內可跑多個容器，共用 Network Namespace |
| Deployment | python-app-deploy.yaml | 管理 Pod 的狀態、版本與副本數，提供自我修復 (Self-healing) 與滾動更新 |
| Service | postgres-service | 穩定入口。Pod 的 IP 會變，但 Service 的 DNS 名稱（如 db-host）永遠不變 |
| Ingress | app-ingress.yaml | 外部流量進入叢集的 L7 負載均衡器，負責解析網域名稱（Domain） |
| ConfigMap | app-config | 存放環境變數、配置檔。修改時不需重新構建 Image |
| Secret | db-secret | 存放敏感資訊（密碼、金鑰），內容會經過 Base64 編碼保護 |
| PV / PVC | postgres-pvc | 持久化存儲。PV 是真正的硬碟空間，PVC 是向 K8s 提出的「空間申請書」 |
| Helm Chart | helm/app-stack/ | K8s 的軟體包，將上述所有元件打包在一起，支援版本化與參數化 |

<br>



- #### *B.　WSL2 (Ubuntu) 安裝 MiniKube*
```
# 1. 下載最新版的 MiniKube 二進位檔
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# 2. 安裝至系統路徑
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 3. 驗證安裝是否成功
minikube version

# 4. 啟動 minikube，指定使用 docker driver
minikube start --driver=docker

# 5. 啟用 Ingress 控制器 # 負載均衡器
minikube addons enable ingress
```

- #### *C.　建立測試腳本 Images*
```
eval $(minikube docker-env)
docker build -t my-python-app:v1 .
```


- #### *D.　部署指令*
```
helm install my-dev-release ./helm/app-stack -f ./helm/app-stack/values-dev.yaml
```


- #### *E.　測試驗證*
```
kubectl get pvc
# 確認部署狀態 # 預期 Bound

kubectl logs -f deployment/python-app
# 確認 log # 預期 Successfully connected

kubectl delete pod -l app=postgres
# 強制移除節點
# 預期 Python Log 會顯示開始報錯重試，直到 K8s 自動把 Postgres Pod 重啟回來後，連線又會恢復。
```

<br>

### *K3s*

<br>

### *Kubeadm*

<br><br><br>
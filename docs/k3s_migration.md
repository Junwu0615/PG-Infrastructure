## *K3s Migration*

### *A.　結構說明*
```
k3s_migration/
├── Makefile                     # 自動化入口
│
├── bootstrap/                   # 【第一層：純機器初始化】僅由運維手動執行
│   ├── terraform/               # 建立 VM 與基礎網路
│   │   └── ...
│   └── ansible/                 # OS 設定與 k3s 叢集安裝
│       └── ...
│
└── gitops/                      # 【第二層：GitOps 核心】ArgoCD 唯一看管範圍
    │
    ├── argocd-bootstrap/        # ArgoCD 災難復原與初始化入口（手動 kubectl apply -k 這裡）
    │   ├── base/                # 安裝 ArgoCD 官方元件
    │   └── root-apps/           # App-of-Apps 的根節點，負責載入 infrastructure 與 apps
    │       ├── test-root.yaml   # 測試環境的「總開關」
    │       ├── stage-root.yaml
    │       └── prod-root.yaml
    │
    ├── infra/                   # 中間件與基礎設施（Airflow, GitLab, DB）
    │   ├── base/                # 基礎宣告（定義專案、Namespace 等）
    │   │   ├── apache-airflow/  # 這裡只放一個 K8s 原生的 HelmRelease 或 Argo Application 宣告
    │   │   ├── argo-cd/
    │   │   └── postgresql/
    │   └── environments/        # 環境變數覆寫（環境的邊界在這裡收斂！）
    │       ├── test/
    │       │   ├── kustomization.yaml # 組合 base 的服務，並注入 test 的 values
    │       │   ├── airflow-values.yaml
    │       │   └── postgres-values.yaml
    │       ├── stage/
    │       └── prod/
    │
    └── apps/                          # 自定義研業務服務（ cp, inst ）
        ├── base/
        │   ├── inst/                  # 手刻的 K8s Deployment/Service YAML
        │   └── cp/
        └── environments/
            ├── test/
            │   ├── kustomization.yaml
            │   └── patches/           # 測試環境的副本數（replicas）、Ingress 域名修改
            ├── stage/
            └── prod/
```

<br>

### *B.　Makefile Command*
```
Terraform:
    # 初始化 terraform 配置
    make init
    
    # 安裝 VM 環境 ( 包括: deploy_k3s.yml + init_nodes.yml ) => SSH 無密碼登入
    make apply node_num=5 node_cpu=4 node_memory=6144
    
    # 拆除 VM 環境
    make destroy

Ansible:
    # 檢視狀態 ( pods + nodes )
    make status
    
    # VM 關機 ( K3s 集群 )
    make power-manage action=stop
    
    # VM 重新啟動 ( K3s 集群 )
    make power-manage action=reboot

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

### *C.　摸索 ...*
```
# 持續觀察
kubectl get pods -n infra-data -w
kubectl get pods -n infra-monitor -w
kubectl get pods -n infra-tools -w
kubectl get pods -n dev-apps -w


# 建立命名空間
kubectl create namespace infra-data       # => Postgres, Kafka, Airflow
kubectl create namespace infra-monitor    # => Prometheus, Grafana, ELK
kubectl create namespace infra-tools      # => GitLab, Portainer, Vault
kubectl create namespace dev-apps         # => 自定義業務服務: cp, inst 


# 新增官方 Helm 倉庫
    # 新增 gitlab
    helm repo add gitlab https://charts.gitlab.io/
    
    # 新增 bitnami
    helm repo add bitnami https://charts.bitnami.com/bitnami
    
    # 新增 minio 官方倉庫
    helm repo add minio https://charts.min.io/
    
    # 結尾更新
    helm repo update


# 手動過渡期
# 基礎設施基底 ( gitlab + postgresql + airflow )
    # GitLab 內部需要讀取外部 Redis,PostgreSQL,MinIO 的密碼
  
# 1. 建立 K8s Secret: PostgreSQL
kubectl create secret generic gitlab-postgres-pass \
  --namespace infra-tools \
  --from-literal=password="SuperSecurePostgresPassword" \
  --dry-run=client -o yaml | kubectl apply -f -

# 2. 建立 K8s Secret: Redis
kubectl create secret generic gitlab-redis-pass \
  --namespace infra-tools \
  --from-literal=secret="GitLabRedisPassword123" \
  --dry-run=client -o yaml | kubectl apply -f -

# 3. 建立 K8s Secret:  MinIO 物件儲存憑證
kubectl create secret generic gitlab-minio-secret \
  --namespace infra-tools \
  --from-literal=accesskey="minioadmin" \
  --from-literal=secretkey="minioadminpassword" \
  --dry-run=client -o yaml | kubectl apply -f -

# 可讀取已建立密碼
kubectl get secrets -n infra-tools

# 4. 啟動 Redis
helm install gitlab-redis bitnami/redis \
  --namespace infra-tools \
  --set auth.password="GitLabRedisPassword123" \
  --set architecture=standalone \
  --set master.persistence.enabled=false # 測試環境，先不用持久化
  
# 5. 啟動 MinIO
helm install gitlab-minio minio/minio \
  --namespace infra-tools \
  --set rootUser="minioadmin" \
  --set rootPassword="minioadminpassword" \
  --set persistence.enabled=false \
  --set mode=standalone
  
# 6. 啟動 Gitlab
helm install gitlab-infra gitlab/gitlab \
  --namespace infra-tools \
  -f gitops/infra/environments/test/gitlab-values.yaml \
  --version "^9.0.0" \
  --timeout 600s
  


# 啟動 airflow
```

<br><br><br>

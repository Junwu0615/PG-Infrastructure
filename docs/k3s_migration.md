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


# 檢視已建立密碼
kubectl get secrets -n infra-data
kubectl get secrets -n infra-tools

# 檢視密碼明文
kubectl get secret gitlab-postgres-pass -n infra-data -o jsonpath="{.data.password}" | base64 --decode


# 檢視已建立需對外網路服務
kubectl get svc -n infra-tools
kubectl get svc -n infra-data

# 虛擬化名稱檢視 log
kubectl get pods -n infra-tools --show-labels
kubectl logs -n infra-tools -l app=sidekiq
kubectl logs -n infra-tools -l app=webservice
kubectl logs -n infra-tools -l app=migrations


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

# 1. 防呆
# 徹底刪除可能卡死的「內建」Postgres StatefulSet
kubectl delete statefulset gitlab-infra-postgresql -n infra-tools --ignore-not-found=true

# 刪除卡死的 gitlab-infra
kubectl delete jobs -n infra-tools -l release=gitlab-infra

# 2. 建立密碼
kubectl create secret generic gitlab-postgres-pass \
  -n infra-data \
  --from-literal=password="password" \
  --dry-run=client -o yaml | kubectl apply -f -

# 3. 啟動 postgresql
helm install postgres-infra bitnami/postgresql \
  --namespace infra-data \
  --create-namespace \
  -f gitops/infra/environments/test/postgres-values.yaml \
  --no-hooks \
  --timeout 600s

# 4.1 啟動 Gitlab ( 全家桶 | v10 開始需要自行建立全部拆光光 )
helm install gitlab-infra gitlab/gitlab \
  --namespace infra-tools \
  --create-namespace \
  -f gitops/infra/environments/test/gitlab-values.yaml \
  --version "^9.0.0" \
  --no-hooks \
  --timeout 600s

# 4.2 覆蓋升級
helm upgrade gitlab-infra gitlab/gitlab \
  --namespace infra-tools \
  -f gitops/infra/environments/test/gitlab-values.yaml \
  --version "^9.0.0" \
  --force \
  --timeout 600s
  

# 5. 啟動 airflow


# 砍上述一系列依賴設置
# pods
helm uninstall gitlab-infra -n infra-tools
helm uninstall postgres-infra -n infra-data

# pvc
kubectl delete pvc -n infra-data -l app.kubernetes.io/instance=postgres-infra

# secrets
kubectl delete secret -n infra-tools $(kubectl get secrets -n infra-tools -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep '^gitlab-infra-')
kubectl delete secret gitlab-postgres-pass -n infra-tools --ignore-not-found
```

<br><br><br>

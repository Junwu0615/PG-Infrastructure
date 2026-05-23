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
    make apply node_num=3 node_cpu=4 node_memory=8092
    
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
    make label-nodes app=0 infra-data=1 infra-tools=1
    make label-nodes infra-data=1 infra-tools=1
    
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
kubectl get secret gitlab-postgres-pass -n infra-tools -o jsonpath="{.data.password}" | base64 --decode

# 檢視 ConfigMap
kubectl get ConfigMap -n infra-data

# 檢視已建立需對外網路服務
kubectl get svc -n infra-tools
kubectl get svc -n infra-data

# 虛擬化名稱檢視 log
kubectl logs -n infra-data -l app.kubernetes.io/name=postgresql

kubectl get pods -n infra-tools --show-labels
kubectl logs -n infra-tools -l app=gitaly
kubectl logs -n infra-tools -l app=minio
kubectl logs -n infra-tools -l app=sidekiq
kubectl logs -n infra-tools -l app=webservice
kubectl logs -n infra-tools -l app=migrations
kubectl logs -n infra-tools -l app=gitlab-exporter
kubectl logs -n infra-tools -l app=gitlab-shell

# 抓取崩潰日誌
kubectl logs -n infra-tools -l app=webservice -c dependencies

# 病歷表
kubectl describe pod -n infra-tools -l app=migrations
kubectl describe pod -n infra-tools -l app=webservice
kubectl describe pod -n infra-data -l app.kubernetes.io/name=postgresql


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
 
# 2.1.1. 建立 K8s Secret: PostgreSQL # admin
kubectl create secret generic postgres-custom-auth \
--namespace infra-data \
--from-literal=postgres-password='SuperSecurePostgresPassword' \
--from-literal=password='SuperSecurePostgresPassword'
  
# 2.1.2. 建立 K8s Secret: PostgreSQL # gitlab
kubectl create secret generic gitlab-postgres-pass \
  --namespace infra-tools \
  --from-literal=password="SuperSecurePostgresPassword" \
  --dry-run=client -o yaml | kubectl apply -f -

# 2.2. 建立 K8s Secret: Redis
kubectl create secret generic gitlab-redis-pass \
  --namespace infra-tools \
  --from-literal=secret="GitLabRedisPassword123" \
  --dry-run=client -o yaml | kubectl apply -f -

# 2.3. 建立 K8s Secret:  MinIO 物件儲存憑證
kubectl create secret generic gitlab-minio-secret \
  --namespace infra-tools \
  --from-literal=accesskey="minioadmin" \
  --from-literal=secretkey="minioadminpassword" \
  --dry-run=client -o yaml | kubectl apply -f -

# 3.1 套用 ConfigMap + 啟動 postgresql
kubectl apply -f gitops/infra/environments/test/postgres-init-configmap.yaml
helm install postgres-infra bitnami/postgresql \
  --namespace infra-data \
  --create-namespace \
  -f gitops/infra/environments/test/postgres-values.yaml \
  --timeout 600s
  
# 3.2 確認是否吃進初始化檔案
kubectl exec -it -n infra-data sts/postgres-infra-postgresql -- ls -la /docker-entrypoint-initdb.d/
  
# 3.3 測試連線 ( pwd: SuperSecurePostgresPassword )
kubectl exec -it postgres-infra-postgresql-0 -n infra-data \
    -- psql -U gitlab -d gitlabhq_production

# 4.1 啟動 Gitlab ( 全家桶 | v10 開始需要自行建立全部拆光光 )
helm install gitlab-infra gitlab/gitlab \
  --namespace infra-tools \
  --create-namespace \
  -f gitops/infra/environments/test/gitlab-values.yaml \
  --version "^9.0.0" \
  --timeout 600s

# 4.2 覆蓋升級
helm upgrade gitlab-infra gitlab/gitlab \
  --namespace infra-tools \
  -f gitops/infra/environments/test/gitlab-values.yaml \
  --version "^9.0.0" \
  --force \
  --timeout 600s
  
# 4.3 確認能訪問 UI
    # 查看 Service 指向哪個 Port
    kubectl get svc -n infra-tools gitlab-infra-webservice-default -o jsonpath='{.spec.ports}'
    
    # 先確認能否訪問 再建立穩定 Ingress
    kubectl port-forward -n infra-tools svc/gitlab-infra-webservice-default 8090:8181
    
    # 查看 ingress 設置 ( K3s 是否有啟動 Traefik # 預設 )
    kubectl get pods -n kube-system | grep traefik
    
    # [管理員 powershell] 增加路徑 # 統一由 Master 轉發
    notepad C:\Windows\System32\drivers\etc\hosts
    192.168.122.153 gitlab.k3s.local
    
    # 查看 Traefik 實際偵測到的路由 ( ADDRESS 有值 )
    kubectl get ingress -n infra-tools
    
    # 訪問測試
    http://gitlab.k3s.local
    
    # 確認是否確實收到請求
    kubectl logs -n kube-system -l app.kubernetes.io/name=traefik -f

# 5. 啟動 airflow


# 砍上述一系列依賴設置
# pods
helm uninstall gitlab-infra -n infra-tools
helm uninstall postgres-infra -n infra-data

# pvc
kubectl delete pvc -n infra-data --all

# secrets
kubectl delete secret -n infra-tools $(kubectl get secrets -n infra-tools -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep '^gitlab-infra-') --ignore-not-found
kubectl delete secret gitlab-postgres-pass -n infra-tools --ignore-not-found
```

<br><br><br>

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
    └── applications/                          # 自定義研業務服務（ cp, inst ）
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
    make apply VAR_FILE=./env_tfvars/test.tfvars
    
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
    # 標籤設置
    kubectl label nodes k3s-node-0 service-type=none --overwrite
    kubectl label nodes k3s-node-1 service-type=infra-data --overwrite
    kubectl label nodes k3s-node-2 service-type=infra-tools --overwrite
    kubectl get nodes -L service-type
    
Helm:
```

<br>

### *C.　遷移過程*

<details>
<summary><b><i>　c.1.　摸索 ( gitlab / postgresql ) </i></b></summary>
<ul>

```
* --- 持續觀察 --- *
kubectl get pods -n infra-data -w
kubectl get pods -n infra-monitor -w
kubectl get pods -n infra-tools -w
kubectl get pods -n dev-apps -w
```
---
```
* --- 新增官方 Helm 倉庫 --- *

# 新增 gitlab
helm repo add gitlab https://charts.gitlab.io/

# 新增 bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami

# 新增 minio 官方倉庫
helm repo add minio https://charts.min.io/

# 結尾更新
helm repo update
```
---
```
* --- 建立命名空間 --- *

kubectl create namespace infra-data       # => Postgres, Kafka, Airflow
kubectl create namespace infra-monitor    # => Prometheus, Grafana, ELK
kubectl create namespace infra-tools      # => GitLab, Portainer, Vault
kubectl create namespace dev-apps         # => 自定義業務服務: cp, inst 
```
---
```
* --- 常見操作 --- *

# 檢視已建立密碼
kubectl get secrets -n infra-data
kubectl get secrets -n infra-tools

# 檢視密碼明文
kubectl get secret gitlab-postgres-pass -n infra-tools -o jsonpath="{.data.password}" | base64 --decode

# 檢視 ConfigMap
kubectl get ConfigMap -n infra-data

# 檢視 ingress
kubectl get ingress -n infra-tools

# 檢視 ingressroute
kubectl get ingressroute -n infra-tools

# ...
kubectl get ingressroutetcps.traefik.io -A

# ⚠️ 檢視 svc -o yaml
kubectl get svc -n kube-system traefik -o yaml
kubectl get svc -n infra-tools gitlab-infra-webservice-default -o yaml

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
```
---
```
* --- 手動過渡期: 基礎設施基底 ( gitlab + postgresql + airflow ) --- *

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

# 4.1.1 啟動 Gitlab ( 全家桶 | v10 開始需要自行建立全部拆光光 )
helm install gitlab-infra gitlab/gitlab \
  --namespace infra-tools \
  --create-namespace \
  -f gitops/infra/environments/test/gitlab-values.yaml \
  --version "^9.0.0" \
  --timeout 600s
  
# 4.1.2 更新自定義 ingress
kubectl delete ingress gitlab-infra-webservice-default -n infra-tools
kubectl delete ingressroutetcps.traefik.io gitlab-infra-gitlab-shell -n infra-tools
kubectl apply -f gitops/infra/base/ingress/gitlab-ingress.yaml
# kubectl apply -f traefik-rbac.yaml

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
    
    # [管理員 powershell] 增加路徑 # 參考 k3s.md
    
    # 查看 ingress 實際偵測到的路由 ( ADDRESS 有值 )
    kubectl get ingress -n infra-tools
    kubectl get ingressroute -n infra-tools
    
    # 訪問測試 1
    curl -v -H "Host: gitlab.k8s.local" http://10.88.0.20:30161

    # 訪問測試 2 確認走向
    tracert 10.88.0.20
    
    # 訪問測試 3
    http://gitlab.k8s.local:8080
    
    # 確認是否確實收到請求
    kubectl logs -n kube-system -l app.kubernetes.io/name=traefik -f

# [X] 5. 啟動 airflow
=> ⚠️ 遇到 OOMKilled => 折衷改為 Docker Compose
```
---
```
* --- 砍上述一系列依賴設置 --- *

# pods
helm uninstall gitlab-infra -n infra-tools
helm uninstall postgres-infra -n infra-data

# pvc
kubectl delete pvc -n infra-data --all

# ingress
kubectl delete ingress -n infra-tools --all

# ingressroute
kubectl delete ingressroute -n infra-tools --all

# helmchartconfig
kubectl delete helmchartconfig -n kube-system --all

# pv
kubectl delete pv -n infra-data --all
kubectl delete pv -n infra-tools --all

# secrets
kubectl delete secret -n infra-tools $(kubectl get secrets -n infra-tools -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep '^gitlab-infra-') --ignore-not-found
kubectl delete secret gitlab-postgres-pass -n infra-tools --ignore-not-found

# 刪除殘留的 ClusterRole/Binding (針對 Traefik)
kubectl delete clusterrolebinding traefik-kube-system --ignore-not-found
kubectl delete clusterrole traefik-kube-system --ignore-not-found
```

</ul>
</details>


<details open>
<summary><b><i>　c.2.　混合架構 ( 避免 OOM ) </i></b></summary>
<ul>

```
# 啟動 Docker Compose
cd infra/docker-compose
make gitlab action=up
#make postgresql action=up
#make registry action=up
#make airflow action=up
make portainer action=up
#make monitoring action=up
make mqtt action=up
make kafka action=up
make elk action=up


# 啟動 k3s 集群
```
---
```
* --- GitLab GitOps 專案結構樹 --- *
    GitLab ( SCM / CI Source )
    │
    ├── infra-live/           # ⚠️ GitOps 部署來源 ( ArgoCD Watch ) # Source of Truth
    ├── infra-modules/        # 可重用 K8S/Terraform Module
    ├── app-manifests/        # 業務服務 YAML/Helm Values
    ├── docker-services/      # Compose Stateful Services
    ├── platform-docs/        # 文件
    └── README


* --- K3s 部署結構樹 ( GitOps 與其對齊 ) --- *
    infra-live/
    │
    ├── bootstrap/ # 叢集初始化必備元件
    │   ├── argocd/
    │   ├── namespaces/
    │   ├── cert-manager/
    │   ├── ingress-nginx/
    │   └── sealed-secrets/
    │
    ├── environments/       ⚠️ Promotion Layer
    │   └── homelab/
    │       ├── test/
    │       ├── stage/
    │       └── prod/
    │
    ├── applications/       ⚠️ Deployable Units  
    │   ├── observability/
    │   │   ├── tracing/
    │   │   │   ├── [X] tempo/
    │   │   │   ├── [X] jaeger/
    │   │   │   └── [X] opentelemetry/
    │   │   │
    │   │   ├── visualization/
    │   │   │   └── grafana/
    │   │   │
    │   │   ├── metrics/
    │   │   │   ├── exporters/
    │   │   │   │   ├── postgres-exporter/
    │   │   │   │   └── node-exporter/
    │   │   │   └── prometheus/
    │   │   │
    │   │   └── logging/
    │   │       ├── loki/
    │   │       └── promtail/
    │   │
    │   ├── platform/
    │   │   ├── registry/
    │   │   └── argocd/     ⚠️ Deployment Controller
    │   │
    │   ├── security/
    │   │   └── vault/
    │   │
    │   ├── databases/
    │   │   └── postgresql/
    │   │
    │   └── storage/
    │       ├── [X] longhorn/
    │       ├── [X] rook-ceph/
    │       ├── [X] minio/
    │       └── nfs/
    │
    ├── argocd/
    │   ├── projects/
    │   └── applications/
    │
    ├── policies/
    │
    ├── templates/
    │
    └── README
    
    infra-live/bootstrap/
    └── namespaces/
        ├── monitoring.yaml
        ├── logging.yaml
        ├── security.yaml
        └── platform.yaml
    
    infra-live/environments/test/
    ├── root-app.yaml               ⚠️ App-of-Apps Pattern
    ├── core/core.yaml
    ├── observability/observability.yaml
    ├── security/security.yaml
    ├── storage/storage.yaml
    └── apps/apps.yaml
    
    infra-live/argocd               ⚠️ ArgoCD 治理邊界
    ├── applications/
    │   ├── grafana-app.yaml
    │   ├── prometheus-app.yaml
    │   └── ...
    │
    └── projects/
        ├── observability-project.yaml
        ├── platform-project.yaml
        ├── security-project.yaml
        ├── databases-project.yaml
        └── storage-project.yaml
    

* --- Applications: Databases --- *

    infra-live/applications/postgresql/
    ├── helm-release/
    ├── backup/
    ├── restore/
    ├── pvc/
    └── monitoring/
    
* --- Applications: Helm + Values 分離 --- *

    applications/grafana
    ├── helm/
    ├── kustomize/
    └── values/                     ⚠️ Environment Overlay

    applications/grafana/values/    ⚠️ Promotion Flow ( 非 main / Git Tag Promotion )
    ├── common.yaml  # 共用: image repo / ingress annotations / persistence
    ├── test.yaml
    ├── stage.yaml
    └── prod.yaml
```
---
```
* --- 實施步驟 --- *

    GitLab Repo
        ↓
    ArgoCD 接管
        ↓
    App-of-Apps 啟動
        ↓
    GitOps 自動同步


| 階段     | 目標                  |
| ------- | --------------------  |
| Phase 1 | Bootstrap Cluster     |
| Phase 2 | 安裝 ArgoCD            |
| Phase 3 | 建立 AppProject        |
| Phase 4 | 建立 Root App          |
| Phase 5 | 接管 Observability     |
| Phase 6 | 接管 Security          |
| Phase 7 | 接管 Stateful Services |


* --- DevOps Flow --- *
    Push Code
        ↓
    GitLab CI
        ↓
    Build Image
        ↓
    Push Registry
        ↓
    Update values.yaml
        ↓
    ArgoCD Detect Drift
        ↓
    Deploy
```
---
```
# 1. 基礎治理元件
    bootstrap/
    ├── namespaces/
    ├── ingress-nginx/
    ├── cert-manager/
    ├── sealed-secrets/
    └── argocd/

    # 建立 namespaces
    kubectl apply -f bootstrap/namespaces/
    
    # 安裝 ingress-nginx
    
    # 安裝 cert-manager
    
    # 安裝 sealed-secrets
    
# 2. ArgoCD
    # 安裝 ArgoCD
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    
    # 啟動 ArgoCD
    helm install argocd argo/argo-cd \
      -n argocd \
      --create-namespace

# 3.
# 4.
# 5.
# 6.
# 7.
```

</ul>
</details>

<br><br><br>

## *K3s Migration*

### *A.　結構說明*
```
Null
```

<br>

### *B.　Makefile Command*
```
Terraform:
    # 初始化 terraform 配置
    make init
    
    # 安裝 VM 環境 ( 包括: deploy_k3s.yml + init_nodes.yml ) => SSH 無密碼登入
    make apply VAR_FILE=./env_tfvars/test.tfvars
    
    # 手動初始化 bootstrap
    make init-gitops
    
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

```
* --- 建立命名空間 --- *

kubectl create namespace infra-data       # => Postgres, Kafka, Airflow
kubectl create namespace infra-monitor    # => Prometheus, Grafana, ELK
kubectl create namespace infra-tools      # => GitLab, Portainer, Vault
kubectl create namespace dev-apps         # => 自定義業務服務: cp, inst 
```

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

<br>

<details>
<summary><b><i>　I.　啟動服務 </i></b></summary>
<ul>

```
# 啟動 Docker Compose
cd infra/docker-compose
    make gitlab action=up
    make portainer action=up
    make mqtt action=up
    make kafka action=up
    make elk action=up

# 啟動 k3s 集群
    ✅ 1. 初始化 terraform 配置
    make init
    
    ✅ 2. 安裝 VM 環境 ( 包括: deploy_k3s.yml + init_nodes.yml ) => SSH 無密碼登入
    make apply VAR_FILE=./env_tfvars/test.tfvars
    
    ✅ 3. 手動初始化 bootstrap
    make init-gitops
    
    4. 親合/反親合設定
```

</ul>
</details>


<details>
<summary><b><i>　II.　結構樹說明 </i></b></summary>
<ul>

```
* --- GitLab 專案結構樹 ( Repo 即是 infra-live 內容 ) --- *
    infra-live/
    ├── applications/
    ├── argocd/
    ├── bootstrap/
    ├── environments/
    ├── policies/
    ├── templates/
    └── README


* --- K3s 部署結構樹 ( GitOps 與其對齊 ) --- *
    infra-live/
    │
    ├── bootstrap/ # 叢集初始化必備元件
    │   └── cluster/
    │       ├── argocd/
    │       ├── namespaces/
    │       ├── cert-manager/
    │       ├── ingress-nginx/
    │       ├── sealed-secrets/
    │       └── scripts/
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
    │   │   └── [X] argocd/     ⚠️ Deployment Controller
    │   │
    │   ├── security/
    │   │   └── vault/
    │   │
    │   ├── pg-apps/
    │   │   ├── cp/
    │   │   └── inst/ 
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
    
    infra-live/bootstrap/cluster
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
    ├── charts/    # Helm Wrapper Chart ( Helm-first GitOps )
    ├── values/                     ⚠️ Environment Overlay
    ├── app.yaml   # ArgoCD Application 定義
    ├── Chart.lock # 初始化 Chart 依賴包後自動生成
    └── Chart.yaml # Helm Chart 定義 ( 包含依賴包定義 )

    applications/grafana/values/    ⚠️ Promotion Flow ( 非 main / Git Tag Promotion )
    ├── common.yaml  # 共用: image repo / ingress annotations / persistence
    ├── test.yaml
    ├── stage.yaml
    └── prod.yaml
```

</ul>
</details>


<details>
<summary><b><i>　III.　實施階段 </i></b></summary>
<ul>

```
Layer 1 — Infra Provisioning ( Terraform)

Layer 2 — Node Bootstrap ( Ansible )

⚠️ Layer 3 — Cluster Bootstrap ( bootstrap/ )
    ✔ apply namespaces
    ✔ helm install ingress-nginx
    ✔ helm install cert-manager
    ✔ helm install sealed-secrets
    ✔ helm install argocd
    ✔ apply root-app.yaml

⚠️ Layer 4 — GitOps Continuous Delivery ( ArgoCD )
```

</ul>
</details>


<details>
<summary><b><i>　IV.　DevOps Flow 實施步驟 </i></b></summary>
<ul>

```
Git Push
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
Sync
  ↓
K3s Apply
  ↓
Pod Service Running
```

</ul>
</details>


<details>
<summary><b><i>　V.　重新校正 ingress-nginx 位置 </i></b></summary>
<ul>

```
 Browser <localhost:8080>
    ↓
    
 Windows
    ↓  PortProxy <TRANSFER 8080:80>
    
  WSL2
    ↓  socat <LISTEN:80> <TRANSFER 80:30547>
    
ingress-nginx <10.88.0.20:30547> 
    ↓
    
Ingress Rule
    ↓
    
pod-server


1. 確認映射位置: kubectl get svc -n ingress-nginx
NAME                                 TYPE           CLUSTER-IP     EXTERNAL-IP                        PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.43.95.35    10.88.0.20,10.88.0.21,10.88.0.22   80:30547/TCP,443:32451/TCP   17m
ingress-nginx-controller-admission   ClusterIP      10.43.166.76   <none>                             443/TCP                      17m
ingress-nginx-controller-metrics     ClusterIP      10.43.36.168   <none>                             10254/TCP                    17m

2. 設定 socat ( 參考 k3s.md )

3. 測試
    # 確保基本服務已可用
    kubectl port-forward svc/argocd-server -n argocd 8081:80
    
    # WSL2 端
    curl http://10.88.0.20:30547
    curl http://10.88.0.20:32451
    curl -H "Host: argo-cd.k8s.local" http://10.88.0.20:30547
    
    # WIN 端
    ping argo-cd.k8s.local
    Test-NetConnection argo-cd.k8s.local -Port 8080 
    http://argo-cd.k8s.local:8080/
```

</ul>
</details>


<details>
<summary><b><i>　VI.　建立 Applications </i></b></summary>
<ul>

```
# 將已定義的應用類部署
kubectl apply -f infra-live/argocd/projects/

# root-app.yaml 不同層級用途差異
    # [初始一次] 讓 ArgoCD 開始接管 GitOps
    bootstrap/cluster/argocd/root-app.yaml
    
    # [日常 GitOps 的 root]
    environments/homelab/test/root-app.yaml
    environments/homelab/stage/root-app.yaml
    environments/homelab/prod/root-app.yaml
    
# test/root-app.yaml 管理
    - observability.yaml
    - platform.yaml
    - security.yaml
    - pg-apps.yaml
    
    
Bootstrap Root App
    ↓
Environment Root App
    ↓
Layer Apps
    ├── observability
    ├── platform
    ├── security
    └── pg-apps
    ↓
Applications (observability)
    ├── grafana
    ├── prometheus
    ├── ...
    └── loki
    
------

# Hybrid Pattern ( Application 內包 Helm )

    Application
        ↓
    Helm Chart
        ↓
    Extra Kustomize Resources

------
⚠️ Git Repo = Desired State
⚠️ ArgoCD = Reconciliation Engine

直接 push 整個 infra-live tree
    git init
    git remote add origin \
    http://192.168.0.15:8090/pg/infra-live.git


# Applications/Observability
    # 用 git 推 infra 至 gitlab 來觸法 gitops 更新後續驅動
    git add .
    git commit -m "feat: add grafana app"
    git push
    
    
⚠️ 確認 argocd 狀態: kubectl get applications -n argocd -w
NAME                SYNC STATUS   HEALTH STATUS
grafana             Unknown       Healthy
homelab-root        Synced        Healthy
homelab-test-root   OutOfSync     Healthy
observability       Synced        Healthy
pg-apps             Unknown       Unknown
platform            Unknown       Unknown
security            Unknown       Unknown

    # 檢視 argocd 細節 (homelab-root)
    kubectl describe application homelab-root -n argocd
    kubectl describe application homelab-test-root -n argocd
    kubectl describe application observability -n argocd
    kubectl describe application grafana -n argocd
    
    # 懶人更新
    make init-gitops
    
    # 檢查 repo 是否已註冊
    kubectl get secrets -n argocd
    
    # 強制刷快取問題
    kubectl annotate application grafana \
        -n argocd \
        argocd.argoproj.io/refresh=hard --overwrite
    
    # 確認是否新增 ingress: kubectl get ingress -A
    NAMESPACE   NAME            CLASS   HOSTS               ADDRESS                            PORTS   AGE
    argocd      argocd-server   nginx   argo-cd.k8s.local   10.88.0.20,10.88.0.21,10.88.0.22   80      25h
    grafana     grafana         nginx   grafana.k8s.local   10.88.0.20,10.88.0.21,10.88.0.22   80      29s
     
    # 測試是否連通
    curl -v -H "Host: grafana.k8s.local" http://10.88.0.20:30547
    curl -v -H "Host: argo-cd.k8s.local" http://10.88.0.20:30547
    
    * 移除初始點 ( 移除 homelab-root  )
    kubectl delete application homelab-root -n argocd
    
    NAME                SYNC STATUS   HEALTH STATUS
    grafana             Unknown       Healthy
    homelab-test-root   OutOfSync     Healthy
    observability       Synced        Healthy
    pg-apps             Unknown       Unknown
    platform            Unknown       Unknown
    security            Unknown       Unknown
    
------
⚠️ Helm Wrapper Chart ( Helm-first GitOps )
   # 依賴 Helm 依賴包 不全部自己維護

    ArgoCD
        ↓
    Helm Chart
        ↓
    values/values.yaml
    

初始化 Chart 依賴包 ( ./charts )    
    # 手動 ( 在 App 根目錄執行  )
    helm dependency build
    
        # 強制覆蓋
        $$REPO_NAME ( from Chart.yaml )
        $$REPO_URL ( from Chart.yaml )
        helm repo add $$REPO_NAME $$REPO_URL --force-update
        helm repo add  kube-prometheus-stack https://prometheus-community.github.io/helm-charts --force-update
    
    # makefile
        # 全建置
        make init-chart-build
        
        # 單一建置
        make ./infra-live/applications/observability/visualization/grafana
        make ./infra-live/applications/observability/metrics/prometheus-stack
        
    * 檢視內部參數方式 (prometheus-27.39.0.tgz)
    helm show values charts/prometheus-27.39.0.tgz > values-reference.yaml
    
    * helm 渲染 ( 渲染後的 output.yaml 可用來檢視實際部署內容 )
    helm template . \
      -f values/common.yaml \
      -f values/test.yaml > output.yaml
```

</ul>
</details>

</ul>
</details>

<br><br><br>
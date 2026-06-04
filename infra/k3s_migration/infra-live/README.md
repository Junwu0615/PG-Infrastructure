## *K3s Migration*

### *A.　部署框架演進*
```
# Evolution: MiniKube -> K3d -> K3s -> ✅ K3s Migration -> Kubeadm -> GKE

# Summary:
    - GitOps 架構 需要非常嚴謹考量並調整 ( 包括: 服務依賴 / 環境切換 / 後期維運 )
    - 遇到 OOM 問題 => 折衷改為 Docker Compose + K3s 混合架構
    - Values 渲染很多坑 => search: 逆向渲染大法
    - 完整實施 k8s 框架下各類嘗試
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

⭐ 檢視 svc -o yaml
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
    
    # [管理員 powershell] 增加路徑 # 參考說明文件 docs/K3s.md
    
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

# 啟動 K3s Cluster
    ✅ 1. 初始化 terraform 配置
    make init
    
    ✅ 2. 安裝 VM 環境 ( 包括: deploy_k3s.yml + init_nodes.yml ) => SSH 無密碼登入
    make apply VAR_FILE=./env_tfvars/test.tfvars
    
    ✅ 3. 一鍵初始化必要 secrets
    make init-secrets
    
    ✅ 4. 手動初始化 bootstrap
    make init-gitops
    
    ✅ 5. 手動初始化 root-app.yaml
    kubectl apply -f infra-live/environments/homelab/test/root-app.yaml
    
    ✅ 6. 一鍵標籤設定 => 親合/反親合
    make label-nodes
    
    kubectl label nodes k3s-node-0 service-type=ingress-nginx --overwrite
    
```

</ul>
</details>


<details>
<summary><b><i>　II.　結構樹說明 </i></b></summary>
<ul>

```
* --- 改進方案 --- *
    infra-live/
    ├── argocd/                         # 全域 ArgoCD 最高指揮部
    │   ├── root-app.yaml               # 大總管
    │   ├── projects/                   # 專案防護外殼 (databases, security...)
    │   └── applications/               # 自動化生成器 (ApplicationSet)
    │       └── postgresql-appset.yaml  # 一支檔案，自動動態派發 test / prod 
    │
    ├── charts/                         # 第三方 Chart 封裝 (如官方 PostgreSQL)
    │   └── postgresql/
    │
    ├── templates/                      # 既有的內部自訂 K8s 模板基地 (Base)
    │   ├── app-deployment.yaml
    │   └── ingress-template.yaml
    │
    ├── policies/                       # 全域安全防禦策略 (Gatekeeper / NetworkPolicies)
    │   ├── deny-privileged-pods.yaml
    │   └── network-isolation.yaml
    │
    └── environments/                   # 純粹的環境變數儲存所 (絕無重複的 ArgoCD 宣告)
        ├── homelab-test/               
        │   └── postgresql-values.yaml  # 測試環境的調校參數
        └── homelab-prod/               
            └── postgresql-values.yaml  # 生產環境的高可用參數
        
        
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
    

* --- [?] Applications: Databases --- *

    infra-live/applications/databases/postgresql/
    ├── helm-release/
    ├── backup/
    ├── restore/
    ├── pvc/
    └── monitoring/
    
* --- Applications: Helm + Values 分離 --- *

    applications/observability/visualization/grafana
    ├── charts/    # Helm Wrapper Chart ( Helm-first GitOps )
    ├── values/                     ⚠️ Environment Overlay
    ├── app.yaml   # ArgoCD Application 定義
    ├── Chart.lock # 初始化 Chart 依賴包後自動生成
    └── Chart.yaml # Helm Chart 定義 ( 包含依賴包定義 )

    applications/observability/visualization/grafana/values/    ⚠️ Promotion Flow ( 非 main / Git Tag Promotion )
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
 Chrome Browser <localhost:8080> & IDE TCP 5432
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


1. 確認映射位置: kubectl get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                   AGE
ingress-nginx-controller             ClusterIP   10.43.74.36     <none>        80/TCP,443/TCP,5432/TCP   20h
ingress-nginx-controller-admission   ClusterIP   10.43.184.124   <none>        443/TCP                   20h
ingress-nginx-controller-metrics     ClusterIP   10.43.213.22    <none>        10254/TCP                 20h


2. 設定 Netsh PortProxy
    # 新增
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
        
    netsh interface portproxy add v4tov4 `
        listenaddress=0.0.0.0 `
        listenport=5432 `
        connectaddress=172.28.113.34 `
        connectport=5432
        
    # 刪除
    netsh interface portproxy delete v4tov4 listenport=8080 listenaddress=0.0.0.0
    netsh interface portproxy delete v4tov4 listenport=443 listenaddress=0.0.0.0
    netsh interface portproxy delete v4tov4 listenport=5432 listenaddress=0.0.0.0
    
    
    # 驗證
    netsh interface portproxy show all
    Address         Port        Address         Port
    --------------- ----------  --------------- ----------
    192.168.0.15    8090        172.28.113.34   8090
    192.168.0.15    5100        172.28.113.34   5100
    0.0.0.0         8080        172.28.113.34   80
    0.0.0.0         443         172.28.113.34   443
    0.0.0.0         5432        172.28.113.34   5432


3. 設定 Socat 轉發
    # 參考說明文件:
        - docs/K3s.md
        - docs/Dev-Services.md
    
    # 設定檔位置: k3s_migration/archive/ingress_settings/*
    
    # 重啟 
    systemctl enable k8s-http-proxy
    systemctl enable k8s-https-proxy
    systemctl enable postgresql-proxy
    systemctl enable portainer-agent-proxy
    
    # 確認狀態
    systemctl status k8s-http-proxy
    systemctl status k8s-https-proxy
    systemctl status postgresql-proxy
    systemctl status portainer-agent-proxy


4. 進入 VM 確認 ( 含有 ingress-nginx ): sudo ss -ltnp | grep -E ':80|:443|:5432|nginx'
LISTEN 0      511          0.0.0.0:5432       0.0.0.0:*    users:(("nginx",pid=10393,fd=15),("nginx",pid=10388,fd=15))
LISTEN 0      4096         0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=10393,fd=7),("nginx",pid=10388,fd=7))
LISTEN 0      4096         0.0.0.0:443        0.0.0.0:*    users:(("nginx",pid=10393,fd=9),("nginx",pid=10388,fd=9))


5.1. 測試: Socat 是否確實轉發: sudo ss -ltnp | grep -E ':80|:443|:5432|socat'
LISTEN 0      5             0.0.0.0:443        0.0.0.0:*    users:(("socat",pid=1681752,fd=5))
LISTEN 0      5             0.0.0.0:80         0.0.0.0:*    users:(("socat",pid=1680697,fd=5))
LISTEN 0      5             0.0.0.0:5432       0.0.0.0:*    users:(("socat",pid=1683769,fd=5))

---
curl http://10.88.0.20:80
curl http://10.88.0.20:443


5.2. 測試: 確認 WSL2 能否打進 VM 內部 ( HTTP / TCP 適用 )
nc -zv 10.88.0.20 80 => Connection to 10.88.0.20 80 port [tcp/http] succeeded!
nc -zv 10.88.0.20 443 => Connection to 10.88.0.20 443 port [tcp/https] succeeded!
nc -zv 10.88.0.20 5432 => Connection to 10.88.0.20 5432 port [tcp/postgresql] succeeded!
nc -zv 10.88.0.20 9001 => Connection to 10.88.0.20 9001 port [tcp/*] succeeded!


5.3. 測試: WSL2 HTTPS / HTTP 連線是否能打進 ingress-nginx
curl -H "Host: argo-cd.k8s.local" http://10.88.0.20:80


5.4. WIN 端是否能打進 ingress-nginx
Test-NetConnection argo-cd.k8s.local -Port 8080 
http://argo-cd.k8s.local:8080/


5.5. 測試: TCP 連線 ( 0 成功 ; 1 失敗 )
echo > /dev/tcp/10.88.0.20/5432
echo $?
echo > /dev/tcp/10.88.0.20/9001
echo $?

---
* 輸出官方範本參考
helm show values ingress-nginx/ingress-nginx > official-values.yaml


* 手動確認是否吃到參數
helm get values ingress-nginx -n ingress-nginx


* 確認實際 Deployment 參數
kubectl get deploy ingress-nginx-controller \
    -n ingress-nginx \
    -o yaml
```

</ul>
</details>


<details>
<summary><b><i>　VI.　建立 Applications </i></b></summary>
<ul>

```
# 應用類部署
    * 手動建立專案
    kubectl apply -f infra-live/environments/homelab/test/root-app.yaml
    kubectl apply -f infra-live/environments/homelab/test/databases.yaml
    
    ⭐ 強制讓 Argo CD 重新載入該 Application ( root-app.yaml ) # 前置作業要先 push 到 gitlab
    kubectl annotate application homelab-test-root -n argocd argocd.argoproj.io/refresh=normal --overwrite
    
    $ kubectl get appproject -n argocd
    NAME            AGE
    databases       3m14s
    default         5d3h
    observability   4d3h
    pg-apps         23s
    platform        23s
    security        23s


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
    Kustomize
        ↓
    Helm Chart

------
⭐ Git Repo = Desired State
⭐ ArgoCD = Reconciliation Engine

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
        make helm-chart-build
        
        # 單一建置
        make ./infra-live/applications/observability/visualization/grafana
        make ./infra-live/applications/observability/metrics/prometheus-stack
        make ./infra-live/applications/observability/logging/loki
        make ./infra-live/applications/observability/tracing/tempo
        make ./infra-live/applications/databases/postgresql


DEBUG
    * 輸出 values 範例 ( grafana/loki --version 5.47.2 )
    helm show values grafana/loki --version 5.47.2 > official-values.yaml
        
    * 檢視內部參數方式 (prometheus-27.39.0.tgz)
    helm show values charts/prometheus-27.39.0.tgz > values-reference.yaml
    
    * [ 部分應用渲染需要帶 values 驗證 否則直接報錯 ] helm 渲染 ( 渲染後的 output.yaml 可用來檢視實際部署內容 )
    helm template . \
      -f values/common.yaml \
      -f values/test.yaml > output.yaml
      
    * 不帶參數
    helm template . > output.yaml
    
    * 找關鍵字
    [1] cat output.yaml | grep "image: "
    [2] grep "image: " output.yaml
    
    ⭐ 渲染路徑查找 ( 找搞怪目標: replication_factor )
        # 單指 output.yaml
        grep -rn "replication_factor" output.yaml
        
        # 該目錄開始所有目標
        grep -rn "replication_factor" .
    
        # 解讀方式
        ex: ./official-values.yaml:1226:        replication_factor: {{ .Values.ingester.config.replication_factor }}
        Values 檔案中 ingester.config.replication_factor 這個參數會被套用到 Chart 中的 replication_factor 位置
    
    ⭐ 逆向渲染大法
        * 原廠變數精準定位
        grep -rn "目標參數關鍵字" .
        
        * 沙盒地獄渲染驗證
        # 1. 執行本地渲染 # 帶上所有 values # 無法確實輸出就是初步渲染都失敗
        helm template . -f values/common.yaml -f values/test.yaml > output.yaml
        
        # 2. 直接在產出的實體檔案中尋找該參數，驗證是否成功變更
        grep -n "目標參數關鍵字" output.yaml
        
    
    * 確認 Chart 是否真的載入到 dependency
    helm dependency list .
    
    * yq 排查內容方式
    yq '.loki.storage.bucketNames' values/common.yaml
    
    * 疊加 values 作法 ( 官方範本 + 自定義 )
    helm template . -f official-values.yaml -f values/common.yaml --debug
    
    * 改用 helm template 直接對子 Chart 進行操作
        1. 解壓子 Chart（如果它還是 .tgz 壓縮檔）
        tar -zxvf charts/loki-5.47.2.tgz -C charts/
        
        2. 直接指定子 Chart 目錄，並帶入你原本的 values
        helm template charts/loki -f values/common.yaml
    
------
⭐ 刪除孤兒做法 當 argocd 已消失名單 但 pod 還在 ... ( prometheus )
1. 先檢查 kubectl get application -n argocd

⚠️ 2. 查所有相關服務 因為前置設定已綁 -n prometheus
kubectl get all -n prometheus

⚠️ 3. 直接砍域名
kubectl delete namespace prometheus

------
Chart 版本號查詢 ( grafana/loki )

dependencies:
  # values 第一層 Key 必須與此 name 一致，才能正確套用 values 設定
  # 必須是官方 Chart 名稱，不能是自訂名稱
  - name: loki
    ⚠️ version: 5.47.2
    
helm repo list
helm search repo grafana/loki --versions | head -30
```

</ul>
</details>

</ul>
</details>

<br>

### *D.　量化測試*
- [K8s - 基礎設施高可用性測試](https://github.com/Junwu0615/Platform-Genesis/blob/main/docs/HA.md)

<br><br><br>
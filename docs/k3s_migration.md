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
    make apply node_num=3 node_cpu=4 node_memory=6144
    
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
# 建立空間 + 新增 Helm 倉庫
    # 1. 建立一個基礎工具空間
    kubectl create namespace infra-tools
    
    # 2. 新增 GitLab 官方 Helm 倉庫
    helm repo add gitlab https://charts.gitlab.io/
    helm repo update
    
# 啟動 gitlab 服務
helm install my-gitlab gitlab/gitlab \
  --namespace infra-tools \
  -f tmp-gitlab-values.yaml \
  --timeout 600s


```

<br><br><br>

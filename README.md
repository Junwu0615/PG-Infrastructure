<a href='https://github.com/Junwu0615/Platform Genesis'><img alt='GitHub Views' src='https://views.whatilearened.today/views/github/Junwu0615/Platform Genesis.svg'>
[![Back to HomePage](https://img.shields.io/badge/%F0%9F%8C%90_Back_to-HomePage-blue?style=flat-square)](https://github.com/Junwu0615/Platform-Genesis)

## *⭐ PG-Infrastructure ⭐*

<br>

### *A.　Implement*

<details>
<summary><b><i>　Service Support Form </i></b></summary>
<ul>

> ##### 預計實現 ( ✔ )
> ##### 尚未規劃 ( - )
> ##### 經權衡棄用 ( ✘ )
> ##### 經權衡不遷移 ( * ) ➔ 記憶體 OOM Kill ( 折衷打退回為 Docker Compose )
> ##### 經權衡不遷移 ( △ ) ➔ 省作業時間 ( 部分與重型服務 Docker Compose 綑綁 )

|_**Service**_|_**Docker**_|_**Terraform<br>( Docker )**_|_**MiniKube**_|_**K3d**_|_**K3s**_|_**K3s<br>Migration**_|_**Kubeadm**_|_**GKE**_|
|--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| _**PostgreSQL**_ | ✔ | - | ✔ | ✔ | ✔ | ✔ | - | - |
| _**PgAdmin**_ | ✔ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ |
| _**PoWA**_ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ |
| _**Apache Airflow**_ | ✔ | - | - | - | - | * | - | - |
| _**Superset**_ | ✔ | - | - | - | - | * | - | - |
| _**MQTT**_ | ✔ | - | - | - | - | △ | - | - |
| _**Apache Kafka**_ | ✔ | - | - | - | - | * | - | - |
| _**Kafka UI**_ | ✔ | - | - | - | - | △ | - | - |
| _**Schema Registry**_ | ✔ | - | - | - | - | △ | - | - |
| _**Debezium**_ | ✔ | - | - | - | - | △ | - | - |
| _**MinIO**_ | ✔ | - | - | - | - | △ | - | - |
| _**Apache Iceberg**_ | ✔ | - | - | - | - | * | - | - |
| _**Apache Flink**_ | ✔ | - | - | - | - | * | - | - |
| _**Postgres Exporter**_ | ✔ | ✔ | - | - | - | ✔ | - | - |
| _**Node Exporter**_ | ✔ | ✔ | - | - | - | ✔ | - | - |
| _**Prometheus**_ | ✔ | ✔ | - | - | - | ✔ | - | - |
| _**Grafana**_ | ✔ | ✔ | - | - | - | ✔ | - | - |
| _**Loki**_ | ✔ | - | - | - | - | ✔ | - | - |
| _**Promtail**_ | ✔ | - | - | - | - | ✔ | - | - |
| _**Tempo**_ | ✘ | - | - | - | - | ✔ | - | - |
| _**Elasticsearch**_ | ✔ | - | - | - | - | * | - | - |
| _**Logstash**_ | ✔ | - | - | - | - | * | - | - |
| _**Kibana**_ | ✔ | - | - | - | - | * | - | - |
| _**GitLab**_ | ✔ | - | - | - | - | * | - | - |
| _**Jenkins**_ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ |
| _**ArgoCD**_ | ✘ | - | - | - | - | ✔ | - | - |
| _**Harbor**_ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | - | - |
| _**Docker Registry**_ | ✔ | - | - | - | - | ✔ | - | - |
| _**Docker Registry UI**_ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ |
| _**Portainer**_ | ✔ | ✔ | - | - | ✔ | ✔ | - | - |
| _**HashiCorp Vault**_ | ✔ | - | - | - | - | ✔ | - | - |

</ul>
</details>

<details>
<summary><b><i>　Tree </i></b></summary>
<ul>

```bash
tree -I 'venv|.git|__pycache__|docs|logs|assets|kafka_data|charts|files'

.
├── LICENSE
├── README.md
├── infra
│   ├── docker-compose
│   │   ├── Makefile
│   │   ├── ansible
│   │   │   ├── inventory.ini
│   │   │   ├── playbook.yml
│   │   │   └── roles
│   │   │       └── monitoring
│   │   │           ├── handlers
│   │   │           │   └── main.yml
│   │   │           ├── tasks
│   │   │           │   └── main.yml
│   │   │           ├── templates
│   │   │           │   └── prometheus.yml.j2
│   │   │           └── vars
│   │   │               └── main.yml
│   │   ├── docker
│   │   │   ├── airflow
│   │   │   │   ├── deploy_dags.sh
│   │   │   │   └── docker-compose.yaml
│   │   │   ├── elk
│   │   │   │   ├── docker-compose.yaml
│   │   │   │   ├── elasticsearch.yaml
│   │   │   │   └── logstash
│   │   │   │       ├── logstash.yaml
│   │   │   │       └── pipeline
│   │   │   │           └── logstash.conf
│   │   │   ├── gitlab
│   │   │   │   ├── config
│   │   │   │   ├── data
│   │   │   │   └── docker-compose.yaml
│   │   │   ├── iot-platform
│   │   │   │   ├── config
│   │   │   │   │   ├── connectors
│   │   │   │   │   │   ├── sink
│   │   │   │   │   │   │   ├── sink-inst-prod-orders.json
│   │   │   │   │   │   │   ├── sink-inst-prod-records.json
│   │   │   │   │   │   │   └── sink-inst-status-logs.json
│   │   │   │   │   │   ├── sink-k8s
│   │   │   │   │   │   │   ├── sink-inst-prod-orders.json
│   │   │   │   │   │   │   ├── sink-inst-prod-records.json
│   │   │   │   │   │   │   └── sink-inst-status-logs.json
│   │   │   │   │   │   └── source
│   │   │   │   │   │       └── source-cp-mach-order.json
│   │   │   │   │   └── mosquitto.conf
│   │   │   │   ├── dockerfile
│   │   │   │   │   └── Dockerfile.kafka
│   │   │   │   ├── kafka-compose.yaml
│   │   │   │   └── mqtt-compose.yaml
│   │   │   ├── jenkins
│   │   │   │   └── docker-compose.yaml
│   │   │   ├── monitoring
│   │   │   │   ├── docker-compose.yaml
│   │   │   │   ├── loki-config.yaml
│   │   │   │   ├── prometheus.yaml
│   │   │   │   └── promtail-config.yaml
│   │   │   ├── portainer
│   │   │   │   └── docker-compose.yaml
│   │   │   ├── postgresql
│   │   │   │   ├── Dockerfile
│   │   │   │   ├── docker-compose.yaml
│   │   │   │   └── init
│   │   │   │       └── init.sql
│   │   │   ├── powa
│   │   │   │   ├── Dockerfile
│   │   │   │   ├── docker-compose.yaml
│   │   │   │   └── init
│   │   │   │       └── powa.sql
│   │   │   └── registry
│   │   │       └── docker-compose.yaml
│   │   ├── docker-compose.yaml
│   │   └── terraform
│   │       ├── main.tf
│   │       ├── modules
│   │       │   ├── docker_container
│   │       │   │   ├── main.tf
│   │       │   │   ├── outputs.tf
│   │       │   │   └── variables.tf
│   │       │   ├── monitoring
│   │       │   │   ├── main.tf
│   │       │   │   ├── outputs.tf
│   │       │   │   └── variables.tf
│   │       │   └── portainer
│   │       │       ├── main.tf
│   │       │       ├── outputs.tf
│   │       │       └── variables.tf
│   │       ├── outputs.tf
│   │       ├── terraform.tfvars
│   │       └── variables.tf
│   ├── gke ( `TBD` )
│   ├── k3d ( `omission` )
│   ├── k3s ( `omission` )
│   ├── k3s_migration
│   │   ├── Makefile
│   │   ├── archive
│   │   │   ├── k9s-fav
│   │   │   │   └── homelab-test.yaml
│   │   │   └── test ( `omission` )
│   │   ├── bootstrap
│   │   │   ├── ansible
│   │   │   │   ├── ansible.cfg
│   │   │   │   ├── group_vars
│   │   │   │   │   └── all.yml
│   │   │   │   ├── inventory.ini
│   │   │   │   ├── playbooks
│   │   │   │   │   ├── deploy_gateway.yml
│   │   │   │   │   ├── deploy_k3s.yml
│   │   │   │   │   ├── init_nodes.yml
│   │   │   │   │   └── roles
│   │   │   │   │       ├── init
│   │   │   │   │       │   └── tasks
│   │   │   │   │       │       └── main.yml
│   │   │   │   │       ├── k3s-primary
│   │   │   │   │       │   ├── handlers
│   │   │   │   │       │   │   └── main.yml
│   │   │   │   │       │   ├── tasks
│   │   │   │   │       │   │   └── main.yml
│   │   │   │   │       │   └── templates
│   │   │   │   │       ├── k3s-secondary
│   │   │   │   │       │   ├── handlers
│   │   │   │   │       │   │   └── main.yml
│   │   │   │   │       │   ├── tasks
│   │   │   │   │       │   │   └── main.yml
│   │   │   │   │       │   └── templates
│   │   │   │   │       ├── k3s_agents
│   │   │   │   │       │   ├── handlers
│   │   │   │   │       │   │   └── main.yml
│   │   │   │   │       │   ├── tasks
│   │   │   │   │       │   │   └── main.yml
│   │   │   │   │       │   └── templates
│   │   │   │   │       ├── keepalived
│   │   │   │   │       │   ├── handlers
│   │   │   │   │       │   │   └── main.yml
│   │   │   │   │       │   ├── tasks
│   │   │   │   │       │   │   └── main.yml
│   │   │   │   │       │   └── templates
│   │   │   │   │       │       └── keepalived.conf.j2
│   │   │   │   │       ├── nfs-common
│   │   │   │   │       │   └── tasks
│   │   │   │   │       │       └── main.yml
│   │   │   │   │       ├── nfs-server
│   │   │   │   │       │   ├── handlers
│   │   │   │   │       │   │   └── main.yml
│   │   │   │   │       │   └── tasks
│   │   │   │   │       │       └── main.yml
│   │   │   │   │       ├── registries
│   │   │   │   │       │   ├── tasks
│   │   │   │   │       │   │   └── main.yml
│   │   │   │   │       │   └── templates
│   │   │   │   │       │       └── registries.yml.j2
│   │   │   │   │       ├── validation-cluster
│   │   │   │   │       │   └── tasks
│   │   │   │   │       │       └── main.yml
│   │   │   │   │       ├── validation-control-plane
│   │   │   │   │       │   └── tasks
│   │   │   │   │       │       └── main.yml
│   │   │   │   │       └── validation-vip
│   │   │   │   │           └── tasks
│   │   │   │   │               └── main.yml
│   │   │   │   └── site.yml
│   │   │   ├── files
│   │   │   │   ├── init_packages
│   │   │   │   ├── iso_images
│   │   │   │   ├── k3s_packages
│   │   │   │   ├── keepalived_packages
│   │   │   │   ├── nfs_packages
│   │   │   │   └── nfs_server_packages
│   │   │   └── terraform
│   │   │       ├── cloud_init.cfg
│   │   │       ├── env_tfvars
│   │   │       │   ├── homelab-beta.tfvars
│   │   │       │   └── homelab-test.tfvars
│   │   │       ├── inventory.tftpl
│   │   │       ├── main.tf
│   │   │       ├── outputs.tf
│   │   │       ├── terraform.tfstate
│   │   │       ├── terraform.tfstate.backup
│   │   │       └── variables.tf
│   │   └── infra-live
│   │       ├── README.md
│   │       ├── argocd
│   │       │   ├── applications
│   │       │   │   ├── databases
│   │       │   │   │   └── postgresql-appset.yaml
│   │       │   │   ├── observability
│   │       │   │   │   ├── grafana-appset.yaml
│   │       │   │   │   ├── loki-appset.yaml
│   │       │   │   │   ├── prometheus-appset.yaml
│   │       │   │   │   ├── prometheus-stack-appset.yaml
│   │       │   │   │   ├── promtail-appset.yaml
│   │       │   │   │   ├── tempo-appset.yaml
│   │       │   │   │   └── tempo-distributed-appset.yaml
│   │       │   │   ├── other
│   │       │   │   │   └── kustomization.yaml
│   │       │   │   ├── pg-apps
│   │       │   │   │   ├── cp-appset.yaml
│   │       │   │   │   └── inst-appset.yaml
│   │       │   │   ├── platform
│   │       │   │   │   ├── harbor-appset.yaml
│   │       │   │   │   ├── ingress-nginx-appset.yaml
│   │       │   │   │   └── registry-appset.yaml
│   │       │   │   ├── security
│   │       │   │   │   └── vault-appset.yaml
│   │       │   │   └── storage
│   │       │   │       └── nfs-storage-appset.yaml
│   │       │   ├── kustomization.yaml
│   │       │   ├── projects
│   │       │   │   ├── databases.yaml
│   │       │   │   ├── observability.yaml
│   │       │   │   ├── pg-apps.yaml
│   │       │   │   ├── platform.yaml
│   │       │   │   ├── security.yaml
│   │       │   │   └── storage.yaml
│   │       │   └── root-app.yaml
│   │       ├── bootstrap
│   │       │   └── cluster
│   │       │       ├── argocd
│   │       │       │   ├── ingress.yaml
│   │       │       │   ├── namespace.yaml
│   │       │       │   ├── repo-secret.yaml
│   │       │       │   └── values.yaml
│   │       │       ├── cert-manager
│   │       │       │   ├── cluster-issuer.yaml
│   │       │       │   ├── namespace.yaml
│   │       │       │   └── values.yaml
│   │       │       ├── ingress-nginx
│   │       │       │   ├── namespace.yaml
│   │       │       │   └── values.yaml
│   │       │       ├── scripts
│   │       │       │   └── bootstrap-cluster.sh
│   │       │       └── sealed-secrets
│   │       │           ├── namespace.yaml
│   │       │           └── values.yaml
│   │       ├── charts
│   │       │   ├── databases
│   │       │   │   └── postgresql
│   │       │   │       ├── Chart.lock
│   │       │   │       ├── Chart.yaml
│   │       │   │       ├── charts
│   │       │   │       │   └── postgresql
│   │       │   │       ├── templates
│   │       │   │       │   ├── postgres-init-configmap.yaml
│   │       │   │       │   └── secret.yaml
│   │       │   │       └── values
│   │       │   │           └── common.yaml
│   │       │   ├── observability
│   │       │   │   ├── grafana
│   │       │   │   │   ├── Chart.lock
│   │       │   │   │   ├── Chart.yaml
│   │       │   │   │   ├── charts
│   │       │   │   │   │   └── grafana
│   │       │   │   │   └── values
│   │       │   │   │       └── common.yaml
│   │       │   │   ├── loki
│   │       │   │   │   ├── Chart.lock
│   │       │   │   │   ├── Chart.yaml
│   │       │   │   │   ├── charts
│   │       │   │   │   │   └── loki
│   │       │   │   │   └── values
│   │       │   │   │       └── common.yaml
│   │       │   │   ├── prometheus
│   │       │   │   │   ├── Chart.yaml
│   │       │   │   │   └── values
│   │       │   │   │       └── common.yaml
│   │       │   │   ├── prometheus-stack
│   │       │   │   │   ├── Chart.lock
│   │       │   │   │   ├── Chart.yaml
│   │       │   │   │   ├── charts
│   │       │   │   │   │   └── kube-prometheus-stack
│   │       │   │   │   └── values
│   │       │   │   │       └── common.yaml
│   │       │   │   ├── promtail
│   │       │   │   │   ├── Chart.lock
│   │       │   │   │   ├── Chart.yaml
│   │       │   │   │   ├── charts
│   │       │   │   │   │   └── promtail
│   │       │   │   │   └── values
│   │       │   │   │       └── common.yaml
│   │       │   │   ├── tempo
│   │       │   │   │   ├── Chart.lock
│   │       │   │   │   ├── Chart.yaml
│   │       │   │   │   ├── charts
│   │       │   │   │   │   └── tempo
│   │       │   │   │   ├── templates
│   │       │   │   │   │   └── ingress.yaml
│   │       │   │   │   └── values
│   │       │   │   │       └── common.yaml
│   │       │   │   └── tempo-distributed
│   │       │   │       ├── Chart.yaml
│   │       │   │       ├── templates
│   │       │   │       │   └── ingress.yaml
│   │       │   │       └── values
│   │       │   │           └── common.yaml
│   │       │   ├── pg-apps
│   │       │   │   ├── cp
│   │       │   │   │   ├── Chart.yaml
│   │       │   │   │   ├── templates
│   │       │   │   │   │   └── deployment.yaml
│   │       │   │   │   └── values
│   │       │   │   │       └── common.yaml
│   │       │   │   └── inst
│   │       │   │       ├── Chart.yaml
│   │       │   │       ├── templates
│   │       │   │       │   ├── deployment.yaml
│   │       │   │       │   └── hpa.yaml
│   │       │   │       └── values
│   │       │   │           └── common.yaml
│   │       │   ├── platform
│   │       │   │   ├── harbor
│   │       │   │   │   ├── Chart.yaml
│   │       │   │   │   └── values
│   │       │   │   │       └── common.yaml
│   │       │   │   ├── ingress-nginx
│   │       │   │   │   ├── Chart.lock
│   │       │   │   │   ├── Chart.yaml
│   │       │   │   │   ├── charts
│   │       │   │   │   │   └── ingress-nginx
│   │       │   │   │   └── values
│   │       │   │   │       └── common.yaml
│   │       │   │   └── registry
│   │       │   │       ├── Chart.yaml
│   │       │   │       ├── output.log
│   │       │   │       ├── templates
│   │       │   │       │   ├── deployment.yaml
│   │       │   │       │   ├── ingress.yaml
│   │       │   │       │   ├── pvc.yaml
│   │       │   │       │   └── service.yaml
│   │       │   │       └── values
│   │       │   │           └── common.yaml
│   │       │   ├── security
│   │       │   │   └── vault
│   │       │   │       ├── Chart.lock
│   │       │   │       ├── Chart.yaml
│   │       │   │       ├── charts
│   │       │   │       │   └── vault
│   │       │   │       └── values
│   │       │   │           └── common.yaml
│   │       │   └── storage
│   │       │       └── nfs-storage
│   │       │           ├── Chart.yaml
│   │       │           ├── templates
│   │       │           │   ├── patch-pv-job.yaml
│   │       │           │   ├── pv.yaml
│   │       │           │   ├── pvc.yaml
│   │       │           │   └── storageclass.yaml
│   │       │           └── values
│   │       │               └── common.yaml
│   │       ├── environments
│   │       │   ├── homelab-prod
│   │       │   │   ├── cp-values.yaml
│   │       │   │   ├── grafana-values.yaml
│   │       │   │   ├── ingress-nginx-values.yaml
│   │       │   │   ├── inst-values.yaml
│   │       │   │   ├── loki-values.yaml
│   │       │   │   ├── nfs-storage-values.yaml
│   │       │   │   ├── postgresql-values.yaml
│   │       │   │   ├── prometheus-stack-values.yaml
│   │       │   │   ├── prometheus-values.yaml
│   │       │   │   ├── promtail-values.yaml
│   │       │   │   ├── registry-values.yaml
│   │       │   │   ├── tempo-distributed-values.yaml
│   │       │   │   ├── tempo-values.yaml
│   │       │   │   └── vault-values.yaml
│   │       │   ├── homelab-stage
│   │       │   │   ├── cp-values.yaml
│   │       │   │   ├── grafana-values.yaml
│   │       │   │   ├── ingress-nginx-values.yaml
│   │       │   │   ├── inst-values.yaml
│   │       │   │   ├── loki-values.yaml
│   │       │   │   ├── nfs-storage-values.yaml
│   │       │   │   ├── postgresql-values.yaml
│   │       │   │   ├── prometheus-stack-values.yaml
│   │       │   │   ├── prometheus-values.yaml
│   │       │   │   ├── promtail-values.yaml
│   │       │   │   ├── registry-values.yaml
│   │       │   │   ├── tempo-distributed-values.yaml
│   │       │   │   ├── tempo-values.yaml
│   │       │   │   └── vault-values.yaml
│   │       │   └── homelab-test
│   │       │       ├── cp-values.yaml
│   │       │       ├── grafana-values.yaml
│   │       │       ├── ingress-nginx-values.yaml
│   │       │       ├── inst-values.yaml
│   │       │       ├── loki-values.yaml
│   │       │       ├── nfs-storage-values.yaml
│   │       │       ├── postgresql-values.yaml
│   │       │       ├── prometheus-stack-values.yaml
│   │       │       ├── prometheus-values.yaml
│   │       │       ├── promtail-values.yaml
│   │       │       ├── registry-values.yaml
│   │       │       ├── tempo-distributed-values.yaml
│   │       │       ├── tempo-values.yaml
│   │       │       └── vault-values.yaml
│   │       ├── policies
│   │       │   ├── deny-privileged-pods.yaml
│   │       │   └── network-isolation.yaml
│   │       └── templates
│   │           ├── app-deployment.yaml
│   │           └── ingress-template.yaml
│   ├── kubeadm ( `TBD` )
│   └── minikube ( `omission` )
└── templates
    ├── alert
    │   └── fastapi-delay-alert
    │       ├── message.txt
    │       └── rules.txt
    ├── gitlab-runner
    │   └── config.toml
    ├── grafana
    │   ├── htap.json
    │   ├── observability-test.json
    │   └── observability.json
    ├── ingress_bridge
    │   ├── k3s
    │   │   ├── k8s-http-proxy.service
    │   │   ├── k8s-https-proxy.service
    │   │   ├── portainer-agent-proxy.service
    │   │   └── postgresql-proxy.service
    │   └── k3s_migration
    │       ├── k8s-http-proxy.service
    │       ├── k8s-https-proxy.service
    │       ├── portainer-agent-proxy.service
    │       └── postgresql-proxy.service
    ├── scripts
    │   └── vm-power.sh
    ├── win_hosts
    │   ├── k3s
    │   └── k3s_migration
    └── wsl2
```

</ul>
</details>

<br>


### *B.　Service Architecture*

<details>
<summary><b><i>　b.1.　Data Core & Orchestration </i></b></summary>
<ul>

|_**Service**_|_**Description**_|_**Docker**_|_**K8s**_|_**Stateful<br>/Stateless**_|
|--:|:--|:--:|:--:|:--:|
| _**PostgreSQL**_ | _OLTP Primary Business DB_ | [5432](http://127.0.0.1:5432) | [8080](http://postgresql.k8s.local:8080) | O |
| _**PostgreSQL**_ | _Metadata DB for Airflow_ | [5433](http://127.0.0.1:5433) | △ | O |
| _**PgAdmin**_ | _PostgreSQL Web Management UI_ | [5050](http://127.0.0.1:5050) | X | X |
| _**Apache Airflow**_ | _OLAP Workflow Orchestration_ | [8100](http://127.0.0.1:8100) | * | O |
| _**Superset**_ | _OLAP BI Visualization Dashboard_ | `TBD` | * | X |

</ul>
</details>


<details>
<summary><b><i>　b.2.　Event Streaming & IoT Platform </i></b></summary>
<ul>

|_**Service**_|_**Description**_|_**Docker**_|_**K8s**_|_**Stateful<br>/Stateless**_|
|--:|:--|:--:|:--:|:--:|
| _**MQTT**_ | _High-concurrency IoT Message Ingestion_ | [1883](http://127.0.0.1:1883) | △ | X |
| _**Apache Kafka**_ | _Distributed Streaming Platform Backbone_ | [9092](http://127.0.0.1:9092) | * | O |
| _**Kafka UI**_ | _Topic & Cluster & Consumer Management_ | [9093](http://127.0.0.1:9093) | △ | X |
| _**Schema Registry**_ | _Centralized Schema Governance Avro/JSON_ | [8081](http://127.0.0.1:8081) | △ | X |

</ul>
</details>


<details>
<summary><b><i>　b.3.　Lakehouse Architecture </i></b></summary>
<ul>

|_**Service**_|_**Description**_|_**Docker**_|_**K8s**_|_**Stateful<br>/Stateless**_|
|--:|:--|:--:|:--:|:--:|
| _**MinIO**_ | _Object Storage High-performance AWS S3<br>Compatible Data Lakehouse_ | `TBD` | △ | O |
| _**Debezium**_ | _CDC from Postgres_ | `TBD` | △ | X |
| _**Apache Iceberg**_ | _OLAP High-performance<br>Table Format Data Lake_ | `TBD` | * | O |
| _**Apache Flink**_ | _Stateful Computations<br>over Data Streams_ | `TBD` | * | O |

</ul>
</details>


<details>
<summary><b><i>　b.4.　Observability </i></b></summary>
<ul>

|_**Service**_|_**Description**_|_**Docker**_|_**K8s**_|_**Stateful<br>/Stateless**_|
|--:|:--|:--:|:--:|:--:|
| _**PoWA**_ | - | X | X | X |
| _**Postgres Exporter**_ | _Database Performance Metrics_ | [9187](http://127.0.0.1:9187) | - | X |
| _**Node Exporter**_ | _Host Resource Metrics_ | [9100](http://127.0.0.1:9100) | - | X |
| _**Prometheus**_ | _Metrics Time-Series DB_ | [9090](http://127.0.0.1:9090) | [8080](http://prometheus.k8s.local:8080) | O |
| _**Grafana**_ | _Dashboard_ | [3000](http://127.0.0.1:3000) | [8080](http://grafana.k8s.local:8080) | X |
| _**Loki**_ | _Manage Log_ | [3100](http://127.0.0.1:3100/loki/api/v1/labels) | [8080](http://loki.k8s.local:8080/loki/api/v1/labels) | O |
| _**Promtail**_ | _for Loki_ | - | - | X |
| _**Tempo**_ | _K8s Services Analyze<br>the call topology and latency_ | X | [8080](http://tempo.k8s.local:8080/ready) | O |
| _**Elasticsearch**_ | _Manage Log Distributed<br>Search Engine_ | [9200](http://127.0.0.1:9200) | * | O |
| _**Logstash**_ | _Manage Log Log Processing Pipeline_ | [9600](http://127.0.0.1:9600) | * | X |
| _**Kibana**_ | _Manage Log Log Exploration UI_ | [5601](http://127.0.0.1:5601) | * | X |

</ul>
</details>


<details>
<summary><b><i>　b.5.　DevOps & Security </i></b></summary>
<ul>

|_**Service**_|_**Description**_|_**Docker**_|_**K8s**_|_**Stateful<br>/Stateless**_|
|--:|:--|:--:|:--:|:--:|
| _**GitLab**_ | _Self-hosted SCM CI/CD<br>Project Management_ | [8090](http://127.0.0.1:8090) | * | O |
| _**Jenkins**_ | _Continuous Delivery_ | X | X | X |
| _**ArgoCD**_ | _Continuous Delivery<br>Deployment Controller_ | X | [8080](http://argo-cd.k8s.local:8080) | O/X |
| _**Harbor**_ | _Replace Docker Registry_ | X | - | O |
| _**Docker Registry**_ | _Private Image Repository_ | [5100](http://127.0.0.1:5100/v2/_catalog) | [8080](http://docker-registry.k8s.local:8080/v2/_catalog) | O |
| _**Docker Registry UI**_ | _for Docker Registry_ | X | X | X |
| _**Portainer**_ | _Container Management UI_ | [9000](http://127.0.0.1:9000) | △ | X |
| _**HashiCorp Vault**_ | _KMS Advanced Secret<br>& Key Management_ | `TBD` | [8080](http://hashicorp-vault.k8s.local:8080) | O |

</ul>
</details>

<br>

### *C.　Notice*
- #### *c.1.　[Dev Services](./docs/Dev-Services.md)*
- #### *c.2.　[WSL2 Docker Engine](./docs/WSL2-Docker-Engine.md)*
- #### *c.3.　[Terraform & Ansible](./docs/Terraform-Ansible.md)*
- #### *c.4.　[Docker Compose + Terraform & Ansible](./docs/Docker-Compose.md)*
- #### *c.5.　[K8s Tools](./docs/K8s-tools.md)*
- #### *c.6.　[MiniKube](./docs/Minikube.md)*
- #### *c.7.　[K3s in Docker ( K3d )](./docs/K3d.md)*
- #### *c.8.　[Lightweight Kubernetes ( K3s )](./docs/K3s.md)*
- #### *c.9.　[⭐ K3s Migration](./infra/k3s_migration/infra-live/README.md)*
- #### *c.10.　[Kubeadm](./docs/Kubeadm.md)*
- #### *c.11.　[Google Kubernetes Engine ( GKE )](./docs/GKE.md)*

<br><br><br>

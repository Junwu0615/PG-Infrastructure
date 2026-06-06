<a href='https://github.com/Junwu0615/Platform Genesis'><img alt='GitHub Views' src='https://views.whatilearened.today/views/github/Junwu0615/Platform Genesis.svg'>

## *⭐ PG-Infrastructure ⭐*

<br>

### *A.　Implement*

<details>
<summary><b><i>　a.1.　Service Support Form </i></b></summary>
<ul>

```
O = 已實現
X = 已棄用
- = 未實現
* = Homelab 記憶體 OOM ( 折衷改為 Docker Compose ) => 不遷移
△ = 省作業時間 ( 部分與重型服務的 Docker Compose 綑綁 ) => 不遷移
``` 

|**Service**|**Docker**|**Terraform<br>( Docker )**|**MiniKube**|**K3d**|**K3s**|**K3s<br>Migration**|**Kubeadm**|**GKE**|
|--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **PostgreSQL** | O | - | O | O | O | O | - | - |
| **PgAdmin** | O | X | X | X | X | X | X | X |
| **PoWA** | X | X | X | X | X | X | X | X |
| **Apache Airflow** | O | - | - | - | - | * | - | - |
| **Superset** | O | - | - | - | - | * | - | - |
| **MQTT Broker** | O | - | - | - | - | △ | - | - |
| **Apache Kafka** | O | - | - | - | - | * | - | - |
| **Kafka UI** | O | - | - | - | - | △ | - | - |
| **Schema Registry** | O | - | - | - | - | △ | - | - |
| **Debezium** | O | - | - | - | - | △ | - | - |
| **MinIO** | O | - | - | - | - | △ | - | - |
| **Apache Iceberg** | O | - | - | - | - | * | - | - |
| **Apache Flink** | O | - | - | - | - | * | - | - |
| **Postgres Exporter** | O | O | - | - | - | O | - | - |
| **Node Exporter** | O | O | - | - | - | O | - | - |
| **Prometheus** | O | O | - | - | - | O | - | - |
| **Grafana** | O | O | - | - | - | O | - | - |
| **Loki** | O | - | - | - | - | O | - | - |
| **Promtail** | O | - | - | - | - | O | - | - |
| **Tempo** | X | - | - | - | - | O | - | - |
| **Elasticsearch** | O | - | - | - | - | * | - | - |
| **Logstash** | O | - | - | - | - | * | - | - |
| **Kibana** | O | - | - | - | - | * | - | - |
| **Gitlab** | O | - | - | - | - | * | - | - |
| **Jenkins** | X | X | X | X | X | X | X | X |
| **ArgoCD** | X | - | - | - | - | O | - | - |
| **Harbor** | X | X | X | X | X | X | X | X |
| **Docker Registry** | O | - | - | - | - | O | - | - |
| **Docker Registry UI** | X | X | X | X | X | X | X | X |
| **Portainer** | O | O | - | - | O | △ | - | - |
| **HashiCorp Vault** | O | - | - | - | - | O | - | - |

</ul>
</details>

<details>
<summary><b><i>　a.2.　Tree </i></b></summary>
<ul>

```bash
tree -I 'venv|.git|__pycache__|docs|logs|assets|kafka_data|charts'

.
├── LICENSE
├── README.md
└── infra
    ├── docker-compose
    │   ├── Makefile
    │   ├── ansible
    │   │   ├── inventory.ini
    │   │   ├── playbook.yml
    │   │   └── roles
    │   │       └── monitoring
    │   │           ├── handlers
    │   │           │   └── main.yml
    │   │           ├── tasks
    │   │           │   └── main.yml
    │   │           ├── templates
    │   │           │   └── prometheus.yml.j2
    │   │           └── vars
    │   │               └── main.yml
    │   ├── docker
    │   │   ├── airflow
    │   │   │   ├── config
    │   │   │   ├── deploy_dags.sh
    │   │   │   ├── docker-compose.yaml
    │   │   │   └── plugins
    │   │   ├── elk
    │   │   │   ├── docker-compose.yaml
    │   │   │   ├── elasticsearch.yaml
    │   │   │   └── logstash
    │   │   │       ├── logstash.yaml
    │   │   │       └── pipeline
    │   │   │           └── logstash.conf
    │   │   ├── gitlab
    │   │   │   ├── config
    │   │   │   ├── data
    │   │   │   └── docker-compose.yaml
    │   │   ├── iot-platform
    │   │   │   ├── config
    │   │   │   │   ├── connectors
    │   │   │   │   │   ├── sink
    │   │   │   │   │   │   ├── sink-inst-prod-orders.json
    │   │   │   │   │   │   ├── sink-inst-prod-records.json
    │   │   │   │   │   │   └── sink-inst-status-logs.json
    │   │   │   │   │   └── source
    │   │   │   │   │       └── source-cp-mach-order.json
    │   │   │   │   ├── mosquitto.conf
    │   │   │   │   └── passwd
    │   │   │   ├── dockerfile
    │   │   │   │   └── Dockerfile.kafka
    │   │   │   ├── kafka-compose.yaml
    │   │   │   └── mqtt-compose.yaml
    │   │   ├── jenkins
    │   │   │   └── docker-compose.yaml
    │   │   ├── monitoring
    │   │   │   ├── docker-compose.yaml
    │   │   │   ├── htap_grafana.json
    │   │   │   ├── loki-config.yaml
    │   │   │   ├── prometheus.yaml
    │   │   │   └── promtail-config.yaml
    │   │   ├── portainer
    │   │   │   └── docker-compose.yaml
    │   │   ├── postgresql
    │   │   │   ├── Dockerfile
    │   │   │   ├── docker-compose.yaml
    │   │   │   └── init
    │   │   │       └── init.sql
    │   │   ├── powa
    │   │   │   ├── Dockerfile
    │   │   │   ├── docker-compose.yaml
    │   │   │   └── init
    │   │   │       └── powa.sql
    │   │   └── registry
    │   │       └── docker-compose.yaml
    │   ├── docker-compose.yaml
    │   ├── gitlab-runner
    │   │   └── config.toml
    │   ├── terraform
    │   │   ├── main.tf
    │   │   ├── modules
    │   │   │   ├── docker_container
    │   │   │   │   ├── main.tf
    │   │   │   │   ├── outputs.tf
    │   │   │   │   └── variables.tf
    │   │   │   ├── monitoring
    │   │   │   │   ├── main.tf
    │   │   │   │   ├── outputs.tf
    │   │   │   │   └── variables.tf
    │   │   │   └── portainer
    │   │   │       ├── main.tf
    │   │   │       ├── outputs.tf
    │   │   │       └── variables.tf
    │   │   ├── outputs.tf
    │   │   ├── terraform.tfvars
    │   │   └── variables.tf
    │   └── wsl2
    ├── gcp
    ├── k3d ( `omission` )
    ├── k3s ( `omission` )
    ├── k3s_migration
    │   ├── Makefile
    │   ├── archive ( `omission` )
    │   ├── bootstrap
    │   │   ├── ansible
    │   │   │   ├── ansible.cfg
    │   │   │   ├── group_vars
    │   │   │   │   └── all.yml
    │   │   │   ├── inventory.ini
    │   │   │   └── playbooks
    │   │   │       ├── deploy_k3s.yml
    │   │   │       ├── gateway.yml
    │   │   │       ├── init_nodes.yml
    │   │   │       ├── power_manage.yml
    │   │   │       └── site.yml
    │   │   └── terraform
    │   │       ├── cloud_init.cfg
    │   │       ├── env_tfvars
    │   │       │   └── homelab-test.tfvars
    │   │       ├── inventory.tftpl
    │   │       ├── main.tf
    │   │       ├── outputs.tf
    │   │       ├── terraform.tfstate
    │   │       ├── terraform.tfstate.backup
    │   │       └── variables.tf
    │   ├── infra-live
    │   │   ├── applications
    │   │   │   ├── databases
    │   │   │   │   └── postgresql
    │   │   │   ├── observability
    │   │   │   │   ├── logging
    │   │   │   │   │   ├── loki
    │   │   │   │   │   └── promtail
    │   │   │   │   ├── metrics
    │   │   │   │   │   ├── exporters
    │   │   │   │   │   │   ├── node-exporter
    │   │   │   │   │   │   └── postgres-exporter
    │   │   │   │   │   └── prometheus
    │   │   │   │   ├── tracing
    │   │   │   │   │   └── tempo
    │   │   │   │   └── visualization
    │   │   │   │       └── grafana
    │   │   │   ├── pg-apps
    │   │   │   │   ├── cp
    │   │   │   │   └── inst
    │   │   │   ├── platform
    │   │   │   │   ├── argocd
    │   │   │   │   └── registry
    │   │   │   ├── security
    │   │   │   │   └── vault
    │   │   │   └── storage
    │   │   │       └── nfs
    │   │   ├── argocd
    │   │   │   ├── applications
    │   │   │   └── projects
    │   │   ├── bootstrap
    │   │   │   └── cluster
    │   │   │       ├── argocd
    │   │   │       │   ├── ingress.yaml
    │   │   │       │   ├── namespace.yaml
    │   │   │       │   ├── repo-secret.yaml
    │   │   │       │   ├── root-app.yaml
    │   │   │       │   └── values.yaml
    │   │   │       ├── cert-manager
    │   │   │       │   ├── cluster-issuer.yaml
    │   │   │       │   ├── namespace.yaml
    │   │   │       │   └── values.yaml
    │   │   │       ├── ingress-nginx
    │   │   │       │   ├── namespace.yaml
    │   │   │       │   └── values.yaml
    │   │   │       ├── namespaces
    │   │   │       │   ├── databases.yaml
    │   │   │       │   ├── observability.yaml
    │   │   │       │   ├── pg-apps.yaml
    │   │   │       │   ├── platform.yaml
    │   │   │       │   ├── security.yaml
    │   │   │       │   └── storage.yaml
    │   │   │       ├── scripts
    │   │   │       │   └── bootstrap-cluster.sh
    │   │   │       └── sealed-secrets
    │   │   │           ├── namespace.yaml
    │   │   │           └── values.yaml
    │   │   ├── environments
    │   │   │   └── homelab
    │   │   │       ├── prod
    │   │   │       ├── stage
    │   │   │       └── test
    │   │   ├── policies
    │   │   └── templates
    │   ├── scripts
    │   │   └── vm-power.sh
    │   └── win_hosts
    ├── kubeadm
    └── minikube ( `omission` )
```

</ul>
</details>

<br>


### *B.　Service Architecture*

<details>
<summary><b><i>　b.1.　Data Core & Orchestration </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|**State**|
|--:|:--|:--:|:--:|:--:|
| **PostgreSQL** | `OLTP` Primary Business DB | [5432](http://127.0.0.1:5432) | [8080](http://postgresql.k8s.local:8080) | O |
| **PostgreSQL** | Metadata DB for `Airflow` | [5433](http://127.0.0.1:5433) | △ | O |
| **PgAdmin** | PostgreSQL Web Management UI | [5050](http://127.0.0.1:5050) | X | X |
| **Apache Airflow** | `OLAP` Workflow Orchestration | [8100](http://127.0.0.1:8100) | * | O |
| **Superset** | `OLAP` BI Visualization Dashboard | `TBD` | * | X |

</ul>
</details>


<details>
<summary><b><i>　b.2.　Event Streaming & IoT Platform </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|**State**|
|--:|:--|:--:|:--:|:--:|
| **MQTT Broker** | High-concurrency `IoT` Message Ingestion | [1883](http://127.0.0.1:1883) | △ | X |
| **Apache Kafka** | Distributed Streaming Platform `Backbone` | [9092](http://127.0.0.1:9092) | * | O |
| **Kafka UI** | Topic & Cluster & Consumer Management | [9093](http://127.0.0.1:9093) | △ | X |
| **Schema Registry** | Centralized Schema Governance `Avro/JSON` | [8081](http://127.0.0.1:8081) | △ | X |

</ul>
</details>


<details>
<summary><b><i>　b.3.　Lakehouse Architecture </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|**State**|
|--:|:--|:--:|:--:|:--:|
| **MinIO** | `Object Storage` High-performance AWS S3<br>Compatible `Data Lakehouse` | `TBD` | △ | O |
| **Debezium** | `CDC` from Postgres | `TBD` | △ | X |
| **Apache Iceberg** | `OLAP` High-performance Table Format `Data Lake` | `TBD` | * | O |
| **Apache Flink** | Stateful Computations over Data Streams | `TBD` | * | O |

</ul>
</details>


<details>
<summary><b><i>　b.4.　Monitoring </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|**State**|
|--:|:--|:--:|:--:|:--:|
| **PoWA** | - | X | X | X |
| **Postgres Exporter** | Database Performance Metrics | [9187](http://127.0.0.1:9187) | - | X |
| **Node Exporter** | Host Resource Metrics | [9100](http://127.0.0.1:9100) | - | X |
| **Prometheus** | Metrics Time-Series DB | [9090](http://127.0.0.1:9090) | [8080](http://prometheus.k8s.local:8080) | O |
| **Grafana** | Dashboard | [3000](http://127.0.0.1:3000) | [8080](http://grafana.k8s.local:8080) | X |
| **Loki** | `Manage Log` | [3100](http://127.0.0.1:3100/loki/api/v1/labels) | [8080](http://loki.k8s.local:8080/loki/api/v1/labels) | O |
| **Promtail** | for `Loki` | - | - | X |
| **Tempo** | `K8s Services` Analyze<br>the call topology and latency | X | [8080](http://tempo.k8s.local:8080/ready) | O |
| **Elasticsearch** | `Manage Log` Distributed Search Engine | [9200](http://127.0.0.1:9200) | * | O |
| **Logstash** | `Manage Log` Log Processing Pipeline | [9600](http://127.0.0.1:9600) | * | X |
| **Kibana** | `Manage Log` Log Exploration UI | [5601](http://127.0.0.1:5601) | * | X |

</ul>
</details>


<details>
<summary><b><i>　b.5.　DevOps & Security </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|**State**|
|--:|:--|:--:|:--:|:--:|
| **Gitlab** | `Self-hosted SCM` `CI/CD` `Project Management` | [8090](http://127.0.0.1:8090) | * | O |
| **Jenkins** | `Continuous Delivery` | X | X | X |
| **ArgoCD** | `Continuous Delivery`<br>`Deployment Controller` | X | [8080](http://argo-cd.k8s.local:8080) | O/X |
| **Harbor** | Replace `Docker Registry` | X | - | O |
| **Docker Registry** | `Private Image Repository` | [5100](http://127.0.0.1:5100/v2/_catalog) | [8080](http://docker-registry.k8s.local:8080) | O |
| **Docker Registry UI** | for `Docker Registry` | X | X | X |
| **Portainer** | `Container Management` UI | [9000](http://127.0.0.1:9000) | △ | X |
| **HashiCorp Vault** | `KMS` Advanced Secret & Key Management | `TBD` | [8080](http://hashicorp-vault.k8s.local:8080) | O |

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
- #### *c.9.　[K3s Migration](./infra/k3s_migration/infra-live/README.md)*
- #### *c.10.　[Kubeadm](./docs/Kubeadm.md)*
- #### *c.11.　[Google Kubernetes Engine ( GKE )](./docs/GKE.md)*

<br><br><br>
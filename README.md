<a href='https://github.com/Junwu0615/Platform Genesis'><img alt='GitHub Views' src='https://views.whatilearened.today/views/github/Junwu0615/Platform Genesis.svg'>

## *⭐ PG-Infrastructure ⭐*

### *A.　Roadmap*

<details>
<summary><b><i>　Service Support Form </i></b></summary>
<ul>

```
O = 已實現
X = 已棄用
- = 未實現
* = Homelab 硬體吃不消 ( 折衷改為 Docker Compose ) => 不遷移
△ = 省作業時間 ( 部分與重型服務的 Docker Compose 綑綁 ) => 不遷移
``` 

|**Service**|**Docker**|**Terraform<br>( Docker )**|**MiniKube**|**K3d**|**K3s**|**K3s Migration**|**Kubeadm**|**GCP**|
|--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **PostgreSQL** | O | - | O | O | O | O | - | - |
| **PgAdmin** | O | - | X | X | X | X | X | X |
| **PoWA** | X | X | X | X | X | X | X | X |
| **Apache Airflow** | O | - | - | - | - | * | - | - |
| **Superset** | O | - | - | - | - | * | - | - |
| **MQTT Broker** | O | - | - | - | - | △ | - | - |
| **Apache Kafka** | O | - | - | - | - | * | - | - |
| **Kafka UI** | O | - | - | - | - | △ | - | - |
| **Schema Registry** | O | - | - | - | - | △ | - | - |
| **Debezium** | O | - | - | - | - | △ | - | - |
| **Apache Iceberg** | O | - | - | - | - | * | - | - |
| **Apache Flink** | O | - | - | - | - | * | - | - |
| **Postgres Exporter** | O | O | - | - | - | O | - | - |
| **Node Exporter** | O | O | - | - | - | O | - | - |
| **Prometheus** | O | O | - | - | - | O | - | - |
| **Grafana** | O | O | - | - | - | O | - | - |
| **Loki** | O | - | - | - | - | O | - | - |
| **Promtail** | O | - | - | - | - | O | - | - |
| **Elasticsearch** | O | - | - | - | - | * | - | - |
| **Logstash** | O | - | - | - | - | * | - | - |
| **Kibana** | O | - | - | - | - | * | - | - |
| **Gitlab** | O | - | - | - | - | * | - | - |
| **Jenkins** | X | X | X | X | X | X | X | X |
| **ArgoCD** | X | - | - | - | - | O | - | - |
| **Docker Registry** | O | - | - | - | - | O | - | - |
| **Docker Registry UI** | X | X | X | X | X | X | X | X |
| **Portainer** | O | O | - | - | O | △ | - | - |
| **HashiCorp Vault** | O | - | - | - | - | O | - | - |

</ul>
</details>

<details>
<summary><b><i>　Project Tree </i></b></summary>
<ul>

```bash
tree -I 'venv|.git|__pycache__|docs|logs|assets|kafka_data'
tree -d -I 'venv|.git|__pycache__|docs|logs|assets|kafka_data'

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
    ├── k3d
    ├── k3s
    │   ├── Makefile
    │   ├── app
    │   │   ├── app.py
    │   │   └── dockerfile
    │   │       └── Dockerfile.app
    │   ├── bootstrap
    │   │   ├── ansible
    │   │   │   ├── ansible.cfg
    │   │   │   ├── group_vars
    │   │   │   │   └── all.yml
    │   │   │   └── playbooks
    │   │   │       ├── deploy_k3s.yml
    │   │   │       ├── gateway.yml
    │   │   │       ├── init_nodes.yml
    │   │   │       ├── power_manage.yml
    │   │   │       └── site.yml
    │   │   ├── archive
    │   │   └── terraform
    │   │       ├── cloud_init.cfg
    │   │       ├── gateway_cloud_init.cfg
    │   │       ├── inventory.tftpl
    │   │       ├── main.tf
    │   │       ├── outputs.tf
    │   │       ├── terraform.tfvars
    │   │       └── variables.tf
    │   ├── helm
    │   │   └── app-stack
    │   │       ├── Chart.yaml
    │   │       ├── templates
    │   │       │   ├── app
    │   │       │   │   └── app-deploy.yaml
    │   │       │   ├── configmap.yaml
    │   │       │   ├── db-pvc.yaml
    │   │       │   ├── ingress.yaml
    │   │       │   ├── portainer
    │   │       │   │   ├── portainer-deploy.yaml
    │   │       │   │   └── portainer-service.yaml
    │   │       │   ├── postgres
    │   │       │   │   ├── db-deploy.yaml
    │   │       │   │   └── db-service.yaml
    │   │       │   └── secret.yaml
    │   │       ├── values-dev.yaml
    │   │       ├── values-prod.yaml
    │   │       └── values.yaml
    │   ├── ingress_settings
    │   │   ├── config.yaml
    │   │   ├── k8s-http-proxy.service
    │   │   └── k8s-https-proxy.service
    │   └── scripts
    │       └── vm-power.sh
    ├── k3s_migration
    │   ├── Makefile
    │   ├── archive
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
    │   │       │   └── test.tfvars
    │   │       ├── inventory.tftpl
    │   │       ├── main.tf
    │   │       ├── outputs.tf
    │   │       ├── terraform.tfstate
    │   │       └── variables.tf
    │   ├── gitops
    │   │   ├── apps
    │   │   │   ├── base
    │   │   │   │   ├── cp
    │   │   │   │   └── inst
    │   │   │   └── environments
    │   │   │       ├── prod
    │   │   │       ├── stage
    │   │   │       └── test
    │   │   │           ├── cp-values.yaml
    │   │   │           ├── inst-values.yaml
    │   │   │           └── kustomization.yaml
    │   │   ├── argocd-bootstrap
    │   │   │   ├── base
    │   │   │   └── root-apps
    │   │   │       ├── prod-root.yaml
    │   │   │       ├── stage-root.yaml
    │   │   │       └── test-root.yaml
    │   │   └── infra
    │   │       ├── base
    │   │       │   ├── argo_cd
    │   │       │   ├── docker_registry
    │   │       │   ├── grafana
    │   │       │   ├── hashicorp_vault
    │   │       │   ├── ingress
    │   │       │   │   └── gitlab-ingress.yaml
    │   │       │   ├── loki
    │   │       │   ├── postgresql
    │   │       │   └── prometheus
    │   │       └── environments
    │   │           ├── prod
    │   │           ├── stage
    │   │           └── test
    │   │               └── archive
    │   ├── scripts
    │   │   └── vm-power.sh
    │   └── win_hosts
    ├── kubeadm
    └── minikube
```

</ul>
</details>

<br>


### *B.　Service Architecture*

<details>
<summary><b><i>　b.1.　Data Core & Orchestration </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|
|--:|:--|:--:|:--:|
| **PostgreSQL** | `OLTP` Primary Business DB | [5432](http://127.0.0.1:5432) | [8080](http://postgresql.k8s.local:8080) |
| **PostgreSQL** | Metadata DB for Airflow | [5433](http://127.0.0.1:5433) | * |
| **PgAdmin** | PostgreSQL Web Management UI | [5050](http://127.0.0.1:5050) | X |
| **Apache Airflow** | `OLAP` Workflow Orchestration | [8100](http://127.0.0.1:8100) | * |
| **Superset** | `OLAP` BI Visualization Dashboard | `TBD` | * |

</ul>
</details>


<details>
<summary><b><i>　b.2.　Event Streaming & IoT Platform </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|
|--:|:--|:--:|:--:|
| **MQTT Broker** | High-concurrency `IoT` Message Ingestion | [1883](http://127.0.0.1:1883) | △ |
| **Apache Kafka** | Distributed Streaming Platform `Backbone` | [9092](http://127.0.0.1:9092) | * |
| **Kafka UI** | Topic & Cluster & Consumer Management | [9093](http://127.0.0.1:9093) | △ |
| **Schema Registry** | Centralized Schema Governance `Avro/JSON` | [8081](http://127.0.0.1:8081) | △ |

</ul>
</details>


<details>
<summary><b><i>　b.3.　Lakehouse Architecture </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|
|--:|:--|:--:|:--:|
| **Debezium** | `CDC` from Postgres | `TBD` | △ |
| **Apache Iceberg** | `OLAP` High-performance Table Format `Data Lake` | `TBD` | * |
| **Apache Flink** | Stateful Computations over Data Streams | `TBD` | * |

</ul>
</details>


<details>
<summary><b><i>　b.4.　Monitoring </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|
|--:|:--|:--:|:--:|
| **PoWA** | - | X | X |
| **Postgres Exporter** | Database Performance Metrics | [9187](http://127.0.0.1:9187) | - |
| **Node Exporter** | Host Resource Metrics | [9100](http://127.0.0.1:9100) | - |
| **Prometheus** | Metrics Time-Series DB | [9090](http://127.0.0.1:9090) | [8080](http://prometheus.k8s.local:8080) |
| **Grafana** | Dashboard | [3000](http://127.0.0.1:3000) | [8080](http://grafana.k8s.local:8080) |
| **Loki** | `Manage Log` | [3100](http://127.0.0.1:3100) | [8080](http://loki.k8s.local:8080) |
| **Promtail** | for `Loki` | - | - |
| **Elasticsearch** | `Manage Log` Distributed Search Engine | [9200](http://127.0.0.1:9200) | * |
| **Logstash** | `Manage Log` Log Processing Pipeline | [9600](http://127.0.0.1:9600) | * |
| **Kibana** | `Manage Log` Log Exploration UI | [5601](http://127.0.0.1:5601) | * |

</ul>
</details>


<details>
<summary><b><i>　b.5.　DevOps & Security </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|
|--:|:--|:--:|:--:|
| **Gitlab** | `Self-hosted SCM` `CI/CD` `Project Management` | [8090](http://127.0.0.1:8090) | * |
| **Jenkins** | `Continuous Delivery` | X | X |
| **ArgoCD** | `Continuous Delivery` | X | [8080](http://argo-cd.k8s.local:8080) |
| **Docker Registry** | `Private Image Repository` | [5100](http://127.0.0.1:5100/v2/_catalog) | [8080](http://docker-registry.k8s.local:8080) |
| **Docker Registry UI** | for `Docker Registry` | X | X |
| **Portainer** | `Container Management` UI | [9000](http://127.0.0.1:9000) | △ |
| **HashiCorp Vault** | `KMS` Advanced Secret & Key Management | `TBD` | [8080](http://hashicorp-vault.k8s.local:8080) |

</ul>
</details>

<br>

### *C.　Notice*
- #### *c.1.　[Dev Startup Service](./docs/dev_startup_service.md)*
- #### *c.2.　[WSL2 Docker Engine](./docs/wsl2_docker_engine.md)*
- #### *c.3.　[Terraform & Ansible](./docs/terraform_ansible.md)*
- #### *c.4.　[Docker Compose + Terraform & Ansible](./docs/docker_compose.md)*
- #### *c.5.　[K8s Tools](./docs/k8s_tools.md)*
- #### *c.6.　[MiniKube](./docs/minikube.md)*
- #### *c.7.　[K3s in Docker ( K3d )](./docs/k3d.md)*
- #### *c.8.　[Lightweight Kubernetes ( K3s )](./docs/k3s.md)*
- #### *c.9.　[K3s Migration](./docs/k3s_migration.md)*
- #### *c.10.　[Kubeadm](./docs/kubeadm.md)*
- #### *c.11.　[GCP](./docs/gcp.md)*

<br><br><br>
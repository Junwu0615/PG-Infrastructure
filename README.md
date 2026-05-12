<a href='https://github.com/Junwu0615/Platform Genesis'><img alt='GitHub Views' src='https://views.whatilearened.today/views/github/Junwu0615/Platform Genesis.svg'>

## *⭐ PG-Infrastructure ⭐*

### *A.　Roadmap*

<details>
<summary><b><i>　Project Tree </i></b></summary>
<ul>

```bash
tree -I 'venv|.git|__pycache__|docs|logs|assets|kafka_data'
tree -d -I 'venv|.git|__pycache__|docs|logs|assets|kafka_data'

.
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
    │   │   │   ├── deploy_dags.sh
    │   │   │   └── docker-compose.yaml
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
    │   │   │   │   └── mosquitto.conf
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
    │   ├── Makefile
    │   ├── app
    │   │   ├── app.py
    │   │   └── dockerfile
    │   │       └── Dockerfile.app
    │   └── helm
    │       └── app-stack
    │           ├── Chart.yaml
    │           ├── templates
    │           │   ├── app
    │           │   │   └── app-deploy.yaml
    │           │   ├── configmap.yaml
    │           │   ├── db-pvc.yaml
    │           │   ├── ingress.yaml
    │           │   ├── portainer
    │           │   │   ├── portainer-deploy.yaml
    │           │   │   └── portainer-service.yaml
    │           │   ├── postgres
    │           │   │   ├── db-deploy.yaml
    │           │   │   └── db-service.yaml
    │           │   └── secret.yaml
    │           ├── values-dev.yaml
    │           ├── values-prod.yaml
    │           └── values.yaml
    ├── k3s
    │   ├── Makefile
    │   ├── ansible
    │   │   ├── ansible.cfg
    │   │   ├── group_vars
    │   │   │   └── all.yml
    │   │   ├── inventory.ini
    │   │   └── playbooks
    │   │       ├── deploy_k3s.yml
    │   │       ├── init_nodes.yml
    │   │       ├── power_manage.yml
    │   │       └── site.yml
    │   ├── app
    │   │   ├── app.py
    │   │   └── dockerfile
    │   │       └── Dockerfile.app
    │   ├── archive
    │   │   ├── v1
    │   │   │   ├── Makefile
    │   │   │   └── ansible
    │   │   │       ├── ansible.cfg
    │   │   │       ├── inventory.ini
    │   │   │       └── playbooks
    │   │   │           ├── deploy_k3s.yml
    │   │   │           ├── init_nodes.yml
    │   │   │           └── power_manage.yml
    │   │   └── v2
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
    │   └── terraform
    │       ├── cloud_init.cfg
    │       ├── inventory.tftpl
    │       ├── main.tf
    │       ├── outputs.tf
    │       ├── terraform.tfstate
    │       ├── terraform.tfstate.backup
    │       ├── terraform.tfvars
    │       └── variables.tf
    ├── kubeadm
    └── minikube
        ├── Makefile
        ├── app
        │   ├── app.py
        │   └── dockerfile
        │       └── Dockerfile.app
        ├── helm
        │   └── app-stack
        │       ├── Chart.yaml
        │       ├── templates
        │       │   ├── app
        │       │   │   └── app-deploy.yaml
        │       │   ├── configmap.yaml
        │       │   ├── db-pvc.yaml
        │       │   ├── ingress.yaml
        │       │   ├── portainer
        │       │   │   ├── portainer-deploy.yaml
        │       │   │   └── portainer-service.yaml
        │       │   ├── postgres
        │       │   │   ├── db-deploy.yaml
        │       │   │   └── db-service.yaml
        │       │   └── secret.yaml
        │       ├── values-dev.yaml
        │       ├── values-prod.yaml
        │       └── values.yaml
        └── k8s-manifests
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
| **PostgreSQL** | `OLTP` Primary Business DB | [5432](http://127.0.0.1:5432) | `TBD` |
| **PostgreSQL** | Metadata DB for Airflow | [5433](http://127.0.0.1:5433) | `TBD` |
| **PgAdmin** | PostgreSQL Web Management UI | [5050](http://127.0.0.1:5050) | `TBD` |
| **Apache Airflow** | `OLAP` Workflow Orchestration | [8100](http://127.0.0.1:8100) | `TBD` |
| **Superset** | `OLAP` BI Visualization Dashboard | `TBD` | `TBD` |

</ul>
</details>


<details>
<summary><b><i>　b.2.　Event Streaming & IoT Platform </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|
|--:|:--|:--:|:--:|
| **MQTT Broker** | High-concurrency `IoT` Message Ingestion | [1883](http://127.0.0.1:1883) | `TBD` |
| **Apache Kafka** | Distributed Streaming Platform `Backbone` | [9092](http://127.0.0.1:9092) | `TBD` |
| **Kafka UI** | Topic & Cluster & Consumer Management | [9093](http://127.0.0.1:9093) | `TBD` |
| **Schema Registry** | Centralized Schema Governance `Avro/JSON` | [8081](http://127.0.0.1:8081) | `TBD` |

</ul>
</details>


<details>
<summary><b><i>　b.3.　Lakehouse Architecture </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|
|--:|:--|:--:|:--:|
| **Debezium** | `CDC` from Postgres | `TBD` | `TBD` |
| **Apache Iceberg** | `OLAP` High-performance Table Format `Data Lake` | `TBD` | `TBD` |
| **Apache Flink** | Stateful Computations over Data Streams | `TBD` | `TBD` |

</ul>
</details>


<details>
<summary><b><i>　b.4.　Monitoring & Logging </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|
|--:|:--|:--:|:--:|
| **Postgres Exporter** | Database Performance Metrics | [9187](http://127.0.0.1:9187) | `TBD` |
| **Node Exporter** | Host Resource Metrics | [9100](http://127.0.0.1:9100) | `TBD` |
| **Prometheus** | Metrics Time-Series DB | [9090](http://127.0.0.1:9090) | `TBD` |
| **Grafana** | Dashboard | [3000](http://127.0.0.1:3000) | `TBD` |
| **Loki** | `Manage Log` | [3100](http://127.0.0.1:3100) | `TBD` |
| **Promtail** | for `Loki` | - | - |
| **Elasticsearch** | `Manage Log` Distributed Search Engine | [9200](http://127.0.0.1:9200) | `TBD` |
| **Logstash** | `Manage Log` Log Processing Pipeline | [9600](http://127.0.0.1:9600) | `TBD` |
| **Kibana** | `Manage Log` Log Exploration UI | [5601](http://127.0.0.1:5601) | `TBD` |

</ul>
</details>


<details>
<summary><b><i>　b.5.　DevOps & Security </i></b></summary>
<ul>

|**Service**|**Description**|**Docker**|**K8s**|
|--:|:--|:--:|:--:|
| **Gitlab** | `Self-hosted SCM` `CI/CD` `Project Management` | [8090](http://127.0.0.1:8090) | `TBD` |
| **Jenkins** | `Continuous Delivery` | [8095](http://127.0.0.1:8095/jenkins) | `TBD` |
| **Docker Registry** | `Private Image Repository` | [5100](http://127.0.0.1:5100/v2/_catalog) | `TBD` |
| **Docker Registry UI** | for `Docker Registry` | [8085](http://127.0.0.1:8085) | `TBD` |
| **Portainer** | `Container Management` UI | [9000](http://127.0.0.1:9000) | `TBD` |
| **HashiCorp Vault** | `KMS` Advanced Secret & Key Management | `TBD` | `TBD` |

</ul>
</details>


<br>


### *C.　Service Support Form*

|**Service**|**Docker**|**Terraform<br>( Docker )**|**MiniKube**|**K3d**|**K3s**|**Kubeadm**|**GCP**|
|--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **PostgreSQL** | O | - | O | O | O | O | - |
| **PgAdmin** | O | - | - | - | - | - | - |
| **Apache Airflow** | O | - | - | - | - | - | - |
| **Superset** | O | - | - | - | - | - | - |
| **MQTT Broker** | O | - | - | - | - | - | - |
| **Apache Kafka** | O | - | - | - | - | - | - |
| **Kafka UI** | O | - | - | - | - | - | - |
| **Schema Registry** | O | - | - | - | - | - | - |
| **Debezium** | O | - | - | - | - | - | - |
| **Apache Iceberg** | O | - | - | - | - | - | - |
| **Apache Flink** | O | - | - | - | - | - | - |
| **Postgres Exporter** | O | O | - | - | - | - | - |
| **Node Exporter** | O | O | - | - | - | - | - |
| **Prometheus** | O | O | - | - | - | - | - |
| **Grafana** | O | O | - | - | - | - | - |
| **Loki** | O | - | - | - | - | - | - |
| **Promtail** | O | - | - | - | - | - | - |
| **Elasticsearch** | O | - | - | - | - | - | - |
| **Logstash** | O | - | - | - | - | - | - |
| **Kibana** | O | - | - | - | - | - | - |
| **Gitlab** | O | - | - | - | - | - | - |
| **Jenkins** | O | - | - | - | - | - | - |
| **Docker Registry** | O | - | - | - | - | - | - |
| **Docker Registry UI** | O | - | - | - | - | - | - |
| **Portainer** | O | O | - | - | - | - | - |
| **HashiCorp Vault** | O | - | - | - | - | - | - |

<br>

### *D.　Notice*
- #### *d.1.　[Dev Startup Service](./docs/dev_startup_service.md)*
- #### *d.2.　[WSL2 Docker Engine](./docs/wsl2_docker_engine.md)*
- #### *d.3.　[Terraform & Ansible](./docs/terraform_ansible.md)*
- #### *d.4.　[Docker Compose + Terraform & Ansible](./docs/docker_compose.md)*
- #### *d.5.　[K8s Tools](./docs/k8s_tools.md)*
- #### *d.6.　[MiniKube](./docs/minikube.md)*
- #### *d.7.　[K3s in Docker ( K3d )](./docs/k3d.md)*
- #### *d.8.　[Lightweight Kubernetes ( K3s )](./docs/k3s.md)*
- #### *d.9.　[Kubeadm](./docs/kubeadm.md)*
- #### *d.10.　[GCP](./docs/gcp.md)*

<br><br><br>
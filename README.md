<a href='https://github.com/Junwu0615/Platform Genesis'><img alt='GitHub Views' src='https://views.whatilearened.today/views/github/Junwu0615/Platform Genesis.svg'>

## *⭐ PG-Infrastructure ⭐*

<br>

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
    │   │   ├── monitoring
    │   │   │   ├── docker-compose.yaml
    │   │   │   ├── htap_grafana.json
    │   │   │   └── prometheus.yaml
    │   │   ├── portainer
    │   │   │   └── docker-compose.yaml
    │   │   ├── postgresql
    │   │   │   ├── Dockerfile
    │   │   │   ├── docker-compose.yaml
    │   │   │   └── init
    │   │   │       └── init.sql
    │   │   └── powa
    │   │       ├── Dockerfile
    │   │       ├── docker-compose.yaml
    │   │       └── init
    │   │           └── powa.sql
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
    ├── k3s
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

|**Service**|**Description**|**Port**|
|--:|:--|:--:|
| **PostgreSQL** | `OLTP` Primary Business DB | [5432](http://127.0.0.1:5432) |
| **PostgreSQL** | Metadata DB for Airflow | [5433](http://127.0.0.1:5433) |
| **PgAdmin** | PostgreSQL Web Management UI | [5050](http://127.0.0.1:5050) |
| **Apache Airflow** | `OLAP` Workflow Orchestration | [8100](http://127.0.0.1:8100) |
| **Superset** | `OLAP` BI Visualization Dashboard | `TBD` |

</ul>
</details>


<details>
<summary><b><i>　b.2.　Event Streaming & IoT Platform </i></b></summary>
<ul>

|**Service**|**Description**|**Port**|
|--:|:--|:--:|
| **MQTT Broker** | High-concurrency `IoT` Message Ingestion | [1883](http://127.0.0.1:1883) |
| **Apache Kafka** | Distributed Streaming Platform `Backbone` | [9092](http://127.0.0.1:9092) |
| **Kafka UI** | Topic & Cluster & Consumer Management | [9093](http://127.0.0.1:9093) |
| **Schema Registry** | Centralized Schema Governance `Avro/JSON` | [8081](http://127.0.0.1:8081) |

</ul>
</details>


<details>
<summary><b><i>　b.3.　Lakehouse Architecture </i></b></summary>
<ul>

|**Service**|**Description**|**Port**|
|--:|:--|:--:|
| **Debezium** | `CDC` from Postgres | `TBD` |
| **Apache Iceberg** | `OLAP` High-performance Table Format `Data Lake` | `TBD` |
| **Apache Flink** | Stateful Computations over Data Streams | `TBD` |

</ul>
</details>


<details>
<summary><b><i>　b.4.　Monitoring & Logging </i></b></summary>
<ul>

|**Service**|**Description**|**Port**|
|--:|:--|:--:|
| **Postgres Exporter** | Database Performance Metrics | [9187](http://127.0.0.1:9187) |
| **Node Exporter** | Host Resource Metrics | [9100](http://127.0.0.1:9100) |
| **Prometheus** | Metrics Time-Series DB | [9090](http://127.0.0.1:9090) |
| **Grafana** | Dashboard | [3000](http://127.0.0.1:3000) |
| **Loki** | `Manage Log` | `TBD` |
| **Elasticsearch** | `Manage Log` Distributed Search Engine | [9200](http://127.0.0.1:9200) |
| **Logstash** | `Manage Log` Log Processing Pipeline | [9600](http://127.0.0.1:9600) |
| **Kibana** | `Manage Log` Log Exploration UI | [5601](http://127.0.0.1:5601) |

</ul>
</details>


<details>
<summary><b><i>　b.5.　DevOps & Security </i></b></summary>
<ul>

|**Service**|**Description**|**Port**|
|--:|:--|:--:|
| **Gitlab** | `Self-hosted SCM` `CI/CD` `Project Management` | `TBD` |
| **Jenkins** | `Continuous Delivery` | `TBD` |
| **Docker-Registry** | `Private Image Repository` | `TBD` |
| **Portainer** | `Container Management` UI | [9000](http://127.0.0.1:9000) |
| **HashiCorp Vault** | `KMS` Advanced Secret & Key Management | `TBD` |

</ul>
</details>


<br>


### *C.　Command Platform*

<details>
<summary><b><i>　c.1.　Docker Compose</i></b></summary>
<ul>

```bash
cd infra/docker-compose

# initialization
make init
make build

# depends on 'Compose' service
make up

# service shutdown
make down
```
</ul>
</details>


<details>
<summary><b><i>　c.2.　Terraform + Ansible + Compose </i></b></summary>
<ul>

```bash
cd infra/docker-compose

# initialization
make init
make build
make setup

# depends on 'Compose' service
make postgresql
make airflow
make mqtt
make kafka
make elk

# depends on 'Terraform' + 'Ansible' services ( Monitoring + Portainer )
make all

# service shutdown
make down
make destroy
```
</ul>
</details>


<details>
<summary><b><i>　c.3.　K8s ( Helm + Terraform + Ansible ) </i></b></summary>
<ul>

```bash
...
```
</ul>
</details>


<details>
<summary><b><i>　c.4.　Other </i></b></summary>
<ul>

```bash
# Common
make ps
make prune
make get-chown-all
make list-configs
make refresh

# Airflow
make copy-dag

# Terraform + Ansible
make graph
make infra
make config
make reload

# Kafka Connect
make kafka-connect-create
make kafka-connect-upsert
make kafka-connect-status

# Kafka Cleanup
make kafka-connect-clean
make kafka-topic-clean
make kafka-schema-clean
make kafka-all-clean
```
</ul>
</details>


<br>


### *D.　Service Support Form*

|**Service**|**Docker**|**Terraform**|**MiniKube**|**K3s**|**Kubeadm**|**GCP**|
|--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **PostgreSQL** | O | - | O | O | O | - |
| **PgAdmin** | O | - | - | - | - | - |
| **Apache Airflow** | O | - | - | - | - | - |
| **Superset** | O | - | - | - | - | - |
| **MQTT Broker** | O | - | - | - | - | - |
| **Apache Kafka** | O | - | - | - | - | - |
| **Kafka UI** | O | - | - | - | - | - |
| **Schema Registry** | O | - | - | - | - | - |
| **Debezium** | O | - | - | - | - | - |
| **Apache Iceberg** | O | - | - | - | - | - |
| **Apache Flink** | O | - | - | - | - | - |
| **Postgres Exporter** | O | O | - | - | - | - |
| **Node Exporter** | O | O | - | - | - | - |
| **Prometheus** | O | O | - | - | - | - |
| **Grafana** | O | O | - | - | - | - |
| **Loki** | O | - | - | - | - | - |
| **Elasticsearch** | O | - | - | - | - | - |
| **Logstash** | O | - | - | - | - | - |
| **Kibana** | O | - | - | - | - | - |
| **Gitlab** | O | - | - | - | - | - |
| **Jenkins** | O | - | - | - | - | - |
| **Docker-Registry** | O | - | - | - | - | - |
| **Portainer** | O | O | - | - | - | - |
| **HashiCorp Vault** | O | - | - | - | - | - |

<br>

### *E.　Notice*
- #### *e.1.　[Service Startup](./docs/service_startup.md)*
- #### *e.2.　[WSL2 Docker Engine](./docs/wsl2_docker_engine.md)*
- #### *e.3.　[Terraform & Ansible](./docs/terraform_ansible.md)*
- #### *e.4.　[Kubernetes](./docs/k8s.md)*

<br><br><br>
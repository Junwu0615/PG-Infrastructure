<a href='https://github.com/Junwu0615/Platform Genesis'><img alt='GitHub Views' src='https://views.whatilearened.today/views/github/Junwu0615/Platform Genesis.svg'>

## *⭐ PG-Infrastructure ⭐*

<br>

### *A.　Service Architecture*

<details>
<summary><b><i>　a.1.　Data Core & Orchestration </i></b></summary>
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
<summary><b><i>　a.2.　Event Streaming & IoT Platform </i></b></summary>
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
<summary><b><i>　a.3.　Lakehouse Architecture </i></b></summary>
<ul>

|**Service**|**Description**|**Port**|
|--:|:--|:--:|
| **Debezium** | `CDC` from Postgres | `TBD` |
| **Apache Iceberg** | `OLAP` High-performance Table Format `Data Lake` | `TBD` |
| **Apache Flink** | Stateful Computations over Data Streams | `TBD` |

</ul>
</details>


<details>
<summary><b><i>　a.4.　Monitoring & Logging </i></b></summary>
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
<summary><b><i>　a.5.　DevOps & Security </i></b></summary>
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


### *B.　Command Platform ( Makefile Execute )*

<details>
<summary><b><i>　b.1.　Docker Compose</i></b></summary>
<ul>

```bash
cd docker-compose

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
<summary><b><i>　b.2.　Terraform + Ansible + Compose </i></b></summary>
<ul>

```bash
cd docker-compose

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
<summary><b><i>　b.3.　K8s ( Helm + Terraform + Ansible ) </i></b></summary>
<ul>

```bash
...
```
</ul>
</details>


<details>
<summary><b><i>　b.4.　Other </i></b></summary>
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
## *Docker Compose*

<br>

<details>
<summary><b><i>　Makefile </i></b></summary>
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

# alone
make postgresql
make portainer
make monitoring
make airflow
make mqtt
make kafka
make elk
make registry
make gitlab
[X] make jenkins

# detail ( ex: kafka )
make kafka action=up
make kafka action=restart
make kafka action=down
make kafka action=down volume=-v
```
</ul>
</details>


<details>
<summary><b><i>　Makefile ( Terraform & Ansible ) </i></b></summary>
<ul>

```bash
cd infra/docker-compose

# initialization
make setup

# depends on 'Terraform' + 'Ansible' services ( Monitoring + Portainer )
# incomplete Monitoring ( Loki + Promtail )
make all

# service shutdown
make destroy
```
</ul>
</details>


<details open>
<summary><b><i>　Other Commandline </i></b></summary>
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
make kafka-connect-create sink_type=sink
make kafka-connect-create sink_type=sink-k8s

make kafka-connect-upsert sink_type=sink
make kafka-connect-upsert sink_type=sink-k8s

make kafka-connect-status

# Kafka Cleanup
make kafka-connect-clean
make kafka-topic-clean
make kafka-schema-clean
make kafka-all-clean
```
</ul>
</details>

<br><br><br>
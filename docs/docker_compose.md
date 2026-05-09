## *Docker Compose*


### *A.　Command Platform*

<details>
<summary><b><i>　a.1.　Docker Compose</i></b></summary>
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
<summary><b><i>　a.2.　Terraform + Ansible + Compose </i></b></summary>
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


<details open>
<summary><b><i>　a.3.　Other </i></b></summary>
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

<br><br><br>
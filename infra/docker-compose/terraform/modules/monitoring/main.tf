# terraform/modules/monitoring/main.tf


terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

data "docker_registry_image" "prometheus" {
  name = "prom/prometheus:v3.1.0"
}
data "docker_registry_image" "grafana" {
  name = "grafana/grafana:11.5.1"
}
data "docker_registry_image" "postgres_exporter" {
  name = "prometheuscommunity/postgres-exporter:v0.16.0"
}
data "docker_registry_image" "node_exporter" {
  name = "prom/node-exporter:v1.8.2"
}

module "generic_worker" {
  source       = "../docker_container"
  main_name    = var.main_name
  network_name = var.network_name
  app_configs  = local.apps # TODO 把定義清單丟進去
}

locals {
  apps = {
    "prometheus" = {
      image    = data.docker_registry_image.prometheus.sha256_digest
      ports    = [{ internal = 9090, external = 9090 }]
      restart  = "unless-stopped"
      security_opts = null
      pid_mode = null
      envs     = null
      command  = [
        "--config.file=/etc/prometheus/prometheus.yml", # 為了搭配 lifecycle 否則會崩潰 [1]
        "--storage.tsdb.path=/prometheus", # [1]
        "--web.enable-lifecycle", # 關鍵：開啟此項才支援 POST /-/reload
      ]
      host     = [] # TODO 補齊以維持結構一致
      volumes  = [
        { host = var.prometheus_config_path, container = "/etc/prometheus/prometheus.yml", ro = false },
        { volume_name = var.prometheus_data_name, container = "/prometheus", ro = false }
      ]
    },
    "grafana" = {
      image    = data.docker_registry_image.grafana.sha256_digest
      ports    = [{ internal = 3000, external = 3000 }]
      restart  = "unless-stopped"
      security_opts = null
      pid_mode = null
      envs     = [
        "GF_SECURITY_ADMIN_PASSWORD=admin",
      ]
      command  = null
      host     = []
      volumes  = [
        { volume_name = var.grafana_data_name, container = "/var/lib/grafana", ro = false },
      ]
    },
    "postgres_exporter" = {
      image    = data.docker_registry_image.postgres_exporter.sha256_digest
      ports    = [{ internal = 9187, external = 9187 }]
      restart  = "unless-stopped"
      security_opts = null
      pid_mode = null
      envs     = [
        "DATA_SOURCE_NAME=postgresql://postgres_exporter:exporter@host.docker.internal:5432/postgres?sslmode=disable"
      ]
      command  = [
        "--collector.stat_bgwriter", # TPS / IO / tuples
        "--collector.stat_database", # checkpoint / write
        "--collector.stat_user_tables", # table activity
        "--collector.wal", # WAL throughput
        "--collector.locks", # lock contention 貌似預設即開
        "--collector.database", # DB size
        "--auto-discover-databases", # 自動抓所有 database 的 metrics
        "--collector.postmaster", # Table size / index size
        # "--collector.replication", # Replication status 若未來做 HTAP replica
      ]
      host     = [
        { host = "host.docker.internal", ip = "172.19.0.1" },
      ]
      volumes = []
    },
    "node_exporter" = {
      image    = data.docker_registry_image.node_exporter.sha256_digest
      ports    = [{ internal = 9100, external = 9100 }]
      restart  = "unless-stopped"
      security_opts = null
      pid_mode = "host" # TODO 特例：需要主機 PID 模式
      envs     = null
      command  = [
        "--path.procfs=/host/proc",
        "--path.sysfs=/host/sys",
        "--path.rootfs=/rootfs",
        # 避免 pseudo filesystem
        "--collector.filesystem.fs-types-exclude=^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|overlay|proc|pstore|rpc_pipefs|securityfs|sysfs|tracefs)$$",
        # 避免抓 container mount + C、D、E drive mount ( Node Exporter 掃描這些路徑會極度緩慢且容易報錯 )
        "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc|mnt/c|mnt/d|mnt/e)($$|/)"
      ]
      host     = []
      volumes  = [
        { host = "/proc", container = "/host/proc", ro = true },
        { host = "/sys", container = "/host/sys", ro = true },
        { host = "/", container = "/rootfs", ro = true }
      ]
    }
  }
}
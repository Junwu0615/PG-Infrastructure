# terraform/modules/portainer/main.tf


terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

data "docker_registry_image" "portainer" {
  name = "portainer/portainer-ce:2.21.5"
}

module "generic_worker" {
  source       = "../docker_container"
  main_name    = var.main_name
  network_name = var.network_name
  app_configs  = local.apps # TODO 把定義清單丟進去
}

locals {
  apps = {
    "portainer" = {
      image    = data.docker_registry_image.portainer.sha256_digest
      ports    = [{ internal = 9000, external = 9000 }]
      restart  = "unless-stopped"
      security_opts = ["no-new-privileges:true"]
      pid_mode = null
      envs     = null
      command  = null
      host     = []
      volumes  = [
        { host = "/var/run/docker.sock", container = "/var/run/docker.sock", ro = false },
        { volume_name = var.portainer_data_name, container = "/data", ro = false }
      ]
    }
  }
}
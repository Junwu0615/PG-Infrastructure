# terraform/main.tf


terraform {
  # TODO 顯示表達給 Terraform 此模組必須搭配 docker provider 使用
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}
# TODO 僅在此處實例化，模組會自動繼承這個設定
provider "docker" {}


# TODO ----- 基礎設施層： 網路 -----
resource "docker_network" "monitoring" {
  name = "${var.MAIN_NAME}_monitoring_default"
}

resource "docker_network" "portainer" {
  name = "${var.MAIN_NAME}_portainer_default"
}


# ----- 基礎設施層： Volume -----
# resource + lifecycle 模式: 在此定義清楚，但必須宣告誤刪除 !
# data source 模式: 僅引用
  # TODO 只引用已建立的 volume 怕被暴力誤刪 => 目前做法: 不定義，由軟體層建立並持續使用
# bind mount 模式: 掛載硬碟目錄


# TODO ----- 服務層： 呼叫模組 -----
module "monitoring_services" {
  source       = "./modules/monitoring"
  network_name = docker_network.monitoring.name # TODO 隱性依賴: 網路需要先啟動
  depends_on = [docker_network.monitoring] # TODO 顯性依賴: 網路需要先啟動

  main_name    = var.MAIN_NAME
  service_path = var.SERVICE_PATH

  prometheus_config_path = "${abspath(path.root)}/${var.DOCKER_DIR}/monitoring/prometheus.yaml"
  prometheus_data_name   = "${var.MAIN_NAME}_prometheus_data"
  grafana_data_name      = "${var.MAIN_NAME}_grafana_data"
}

module "portainer_services" {
  source       = "./modules/portainer"
  network_name = docker_network.portainer.name
  depends_on = [docker_network.portainer]

  main_name    = var.MAIN_NAME
  service_path = var.SERVICE_PATH

  portainer_data_name   = "${var.MAIN_NAME}_portainer_data"
}
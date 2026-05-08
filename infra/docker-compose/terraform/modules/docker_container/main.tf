# terraform/modules/docker_container/main.tf


terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

resource "docker_container" "this" {
  for_each = var.app_configs # TODO 接收外部傳入變數清單
  # for_each = local.apps # 原先: 接收本地清單

  # TODO 基礎設置
  name     = "${var.main_name}-${each.key}-1"
  image    = each.value.image

  # TODO 針對性處理共性與非共性的
  dynamic "volumes" {
    for_each = each.value.volumes
    content {
      host_path      = lookup(volumes.value, "host", null)
      volume_name    = lookup(volumes.value, "volume_name", null)
      container_path = volumes.value.container
      read_only      = volumes.value.ro
    }
  }
  dynamic "host" {
    for_each = each.value.host
    content {
      host  = lookup(host.value, "host", null)
      ip    = lookup(host.value, "ip", null) # 欲監控目標的主閘道
    }
  }
  dynamic "ports" {
    for_each = each.value.ports
    content {
      internal  = lookup(ports.value, "internal", null)
      external  = lookup(ports.value, "external", null)
    }
  }

  # TODO 其餘共性標籤 ( 含 ports, lifecycle ... )
  pid_mode      = each.value.pid_mode # TODO 若是 null 則自動忽略
  restart       = each.value.restart
  env           = each.value.envs
  security_opts = each.value.security_opts
  command       = each.value.command

  labels {
    label = "com.docker.compose.project"
    value = var.main_name
  }
  labels {
    label = "com.docker.compose.service"
    value = each.key
  }
  networks_advanced {
    aliases = [each.key] # TODO 增加藝名卡，使網域內可用別名被找到
    name = var.network_name
  }
  lifecycle {
    ignore_changes = [
      # image,        # 建議移除：若更換了版本標籤（例如從 v1 改到 v2），你通常會希望它重啟
      network_mode,   # 建議保留：Docker 常常會自動填入 bridge，造成 tf 無謂的差異比對
      user,           # 建議保留：避免因映像檔內部 user 定義與 tf 預設值不符而重啟
      working_dir,    # 建議保留：理由同上
      # command,      # 建議移除：可透過 command 注入啟動參數
      # entrypoint,   # 建議移除：若 entrypoint 改了，通常服務邏輯也變了
    ]
  }
}
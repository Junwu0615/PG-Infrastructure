# terraform/modules/docker_container/variables.tf


variable "main_name" {}
variable "network_name" {}

variable "app_configs" {
  description = "接收來自各功能模組的 locals"
  # type = map(any)
  type = any
}
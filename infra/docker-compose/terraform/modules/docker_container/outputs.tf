# terraform/modules/docker_container/outputs.tf


output "containers" {
  # TODO 將整個物件輸出，方便上層存取任何屬性
  value = docker_container.this
}
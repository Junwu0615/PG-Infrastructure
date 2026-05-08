# terraform/modules/portainer/variables.tf


variable "main_name" {
  description = "項目名稱 (由父層傳入)"
  type        = string
}
variable "network_name" {
  description = "欲連接的 Docker 網路名稱 (由父層傳入)"
  type        = string
}
variable "service_path" {
  description = "服務位置 (由父層傳入)"
  type        = string
}
variable "portainer_data_name" {
  description = "Portainer 持久化資料名稱 (由父層傳入)"
  type        = string
}
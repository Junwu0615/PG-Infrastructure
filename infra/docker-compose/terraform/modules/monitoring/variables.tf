# terraform/modules/monitoring/variables.tf


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
variable "prometheus_config_path" {
  description = "Prometheus 設定檔位置 (由父層傳入)"
  type        = string
}
variable "prometheus_data_name" {
  description = "Prometheus 持久化資料名稱 (由父層傳入)"
  type        = string
}
variable "grafana_data_name" {
  description = "Grafana 持久化資料名稱 (由父層傳入)"
  type        = string
}
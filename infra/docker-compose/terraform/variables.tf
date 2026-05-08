# terraform/variables.tf


variable "MAIN_NAME" {
  description = "主項目名稱"
  type        = string
  default     = "pg-cluster"
}
variable "DOCKER_DIR" {
  description = "Docker 檔案夾具體位置"
  type        = string
  default     = "../docker"
}
variable "SERVICE_PATH" {
  description = "服務位置"
  type        = string
  default     = "http://127.0.0.1"
}
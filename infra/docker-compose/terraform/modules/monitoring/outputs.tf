# terraform/modules/monitoring/outputs.tf


output "container_ids" {
  description = "所有監控服務容器的 ID 清單"
  value       = { for k, v in module.generic_worker.containers : k => v.id }
}
output "container_names" {
  description = "所有監控服務容器的名稱"
  value       = { for k, v in module.generic_worker.containers : k => v.name }
}
output "network_used" {
  description = "監控服務所連接的網路名稱"
  value       = var.network_name
}

output "url_path_grafana" {
  description = "Grafana 控制台位址"
  value       = "${var.service_path}:${module.generic_worker.containers["grafana"].ports[0].external}"
}
output "url_path_prometheus" {
  description = "Prometheus 查詢介面位址"
  value       = "${var.service_path}:${module.generic_worker.containers["prometheus"].ports[0].external}"
}
output "url_path_postgres_exporter" {
  description = "postgres_exporter 查詢介面位址"
  value       = "${var.service_path}:${module.generic_worker.containers["postgres_exporter"].ports[0].external}"
}
output "url_path_node_exporter" {
  description = "node_exporter 查詢介面位址"
  value       = "${var.service_path}:${module.generic_worker.containers["node_exporter"].ports[0].external}"
}

output "all_service_urls" {
  description = "所有監控服務的存取位址清單"
  value = {
    for k, v in module.generic_worker.containers :
    k => "http://localhost:${v.ports[0].external}"
    if length(v.ports) > 0 # 過濾掉沒有對外開 Port 的容器
  }
}
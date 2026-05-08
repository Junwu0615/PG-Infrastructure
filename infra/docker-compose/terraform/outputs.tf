# terraform/outputs.tf


output "monitoring_summary" {
  value = {
    container_ids               = module.monitoring_services.container_ids
    container_names             = module.monitoring_services.container_names
    network_used                = module.monitoring_services.network_used
    url_path_grafana            = module.monitoring_services.url_path_grafana
    url_path_prometheus         = module.monitoring_services.url_path_prometheus
    url_path_postgres_exporter  = module.monitoring_services.url_path_postgres_exporter
    url_path_node_exporter      = module.monitoring_services.url_path_node_exporter
    all_service_urls            = module.monitoring_services.all_service_urls
  }
}

output "portainer_summary" {
  value = {
    container_ids               = module.portainer_services.container_ids
    container_names             = module.portainer_services.container_names
    network_used                = module.portainer_services.network_used
    url_path_portainer          = module.portainer_services.url_path_portainer
    all_service_urls            = module.portainer_services.all_service_urls
  }
}
# terraform/outputs.tf

output "master_ip" {
  value = libvirt_domain.k3s_nodes[0].network_interface.0.addresses[0]
}

output "agent_ips" {
  value = slice(libvirt_domain.k3s_nodes[*].network_interface.0.addresses[0], 1, var.node_count)
}
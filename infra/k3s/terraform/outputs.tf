# terraform/outputs.tf

output "ips" {
  value = libvirt_domain.k3s_nodes.*.network_interface.0.addresses
}
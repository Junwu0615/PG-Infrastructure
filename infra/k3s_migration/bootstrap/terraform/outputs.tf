# terraform/outputs.tf

# Gateway SSH
# output "gateway_ssh_command" {
#   value = "k3s-gateway => ssh debian@${libvirt_domain.gateway.network_interface.0.addresses[0]}"
# }

# Master SSH
output "master_ssh_command" {
  value = "k3s-node-0 => ssh debian@${libvirt_domain.k3s_nodes[0].network_interface.0.addresses[0]}"
}

# Agent SSH
output "agent_ssh_commands" {
  value = [
    for i in range(1, var.node_count) :
    "k3s-node-${i} => ssh debian@${libvirt_domain.k3s_nodes[i].network_interface.0.addresses[0]}"
  ]
}

# All SSH Commands
# output "all_ssh_commands" {
#   value = concat(
#     [
#       "k3s-gateway => ssh debian@${libvirt_domain.gateway.network_interface.0.addresses[0]}"
#     ],
#
#     [
#       for i, vm in libvirt_domain.k3s_nodes :
#       "k3s-node-${i} => ssh debian@${vm.network_interface.0.addresses[0]}"
#     ]
#   )
# }
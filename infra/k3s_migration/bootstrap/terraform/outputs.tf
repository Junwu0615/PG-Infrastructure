# terraform/outputs.tf

# Master SSH
output "master_ssh_command" {
  value = [
    for i in range(0, var.master_count) :
    "k3s-master-${i} → ssh debian@${libvirt_domain.k3s_masters[i].network_interface.0.addresses[0]}"
  ]
}

# Agent SSH
output "agent_ssh_commands" {
  value = [
    for i in range(0, var.agent_count) :
    "k3s-agent-${i} → ssh debian@${libvirt_domain.k3s_agents[i].network_interface.0.addresses[0]}"
  ]
}

# Storage SSH
output "storage_ssh_command" {
  value = [
    for i in range(0, 1) :
    "k3s-master-${i} → ssh debian@${libvirt_domain.k3s_masters[i].network_interface.0.addresses[0]}"
  ]
}
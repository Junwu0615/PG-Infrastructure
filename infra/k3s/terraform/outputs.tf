# terraform/outputs.tf

# 取得 Master 的 SSH 指令 ( 維持單一輸出 )
output "master_ssh_command" {
  value = "ssh debian@${libvirt_domain.k3s_nodes[0].network_interface.0.addresses[0]}"
}

# 取得所有節點的 SSH 指令列表 (包含 Master 與所有 Agents)
# output "all_nodes_ssh_commands" {
#   value = [
#     for vm in libvirt_domain.k3s_nodes :
#     "ssh debian@${vm.network_interface.0.addresses[0]}"
#   ]
# }

# 如果你只需要 Agent 的部分 (排除第一台 Master)
output "agent_ssh_commands" {
  value = [
    for i in range(1, var.node_count) :
    "ssh debian@${libvirt_domain.k3s_nodes[i].network_interface.0.addresses[0]}"
  ]
}
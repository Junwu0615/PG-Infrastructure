# terraform/terraform.tfvars

vm_user    = "debian"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

net_segment = "192.168.133"
node_count = 3
node_config = {
  "k3s-node-0" = { memory = 4096, vcpu = 2 } # Master
  "k3s-node-1" = { memory = 8192, vcpu = 4 } # infra-data: postgresql
  "k3s-node-2" = { memory = 12288, vcpu = 6 } # infra-tools: gitlab
  "default"    = { memory = 6144, vcpu = 4 }
}
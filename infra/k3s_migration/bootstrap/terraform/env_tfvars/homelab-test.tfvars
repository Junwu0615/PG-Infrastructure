# terraform/terraform.tfvars

vm_user    = "debian"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

net_segment = "10.88.0"
net_segment_master_start = 10
net_segment_agent_start = 20

master_count = 3
agent_count = 4

node_config = {
  "default"     = { memory = 3072, vcpu = 2 }
  "k3s-master-0"= { memory = 3072, vcpu = 2 }
  "k3s-master-1"= { memory = 3072, vcpu = 2 }
  "k3s-master-2"= { memory = 3072, vcpu = 2 }
  "k3s-agent-0" = { memory = 4096, vcpu = 4 }
  "k3s-agent-1" = { memory = 4096, vcpu = 4 }
  "k3s-agent-2" = { memory = 4096, vcpu = 4 }
  "k3s-agent-3" = { memory = 4096, vcpu = 4 }
}
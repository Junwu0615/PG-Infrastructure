# terraform/terraform.tfvars

vm_user    = "debian"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

net_segment = "10.88.0"
net_segment_master_start = 10
net_segment_agent_start = 20

master_count = 3
agent_count = 3

node_config = {
  "default"     = { memory = 2048, vcpu = 2 }
  "k3s-master-0"= { memory = 2048, vcpu = 2 }
  "k3s-master-1"= { memory = 2048, vcpu = 2 }
  "k3s-master-2"= { memory = 2048, vcpu = 2 }
  "k3s-agent-0" = { memory = 6144, vcpu = 4 }
  "k3s-agent-1" = { memory = 6144, vcpu = 4 }
  "k3s-agent-2" = { memory = 6144, vcpu = 4 }
}
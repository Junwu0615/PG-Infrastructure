# terraform/terraform.tfvars

vm_user    = "debian"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# net_segment = "192.168.0"
net_segment = "10.88.0"
net_segment_start = 20
node_count = 2
node_config = {
  "default"    = { memory = 2048, vcpu = 2 }
}
# terraform/variables.tf

variable "ssh_public_key_path" {
  description = "SSH KEY 位置"
  default = "~/.ssh/id_rsa.pub"
}

variable "vm_user" {
  description = "VM USER NAME"
  default = "debian"
}

variable "node_count" {
  description = "生成節點總數"
  default = 3
}

variable "node_config" {
  description = "節點資源配置"
  type = map(object({
    memory = number
    vcpu   = number
  }))
  default = {
    "k3s-node-0" = { memory = 4096, vcpu = 2 }
    "default"    = { memory = 6144, vcpu = 4 }
  }
}


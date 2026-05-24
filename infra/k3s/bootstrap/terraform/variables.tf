# terraform/variables.tf

variable "ssh_public_key_path" {
  description = "SSH KEY 位置"
  default = "~/.ssh/id_rsa.pub"
}

variable "vm_user" {
  description = "VM USER NAME"
  default = "debian"
}

variable "net_segment" {
  description = "網段 ex: 192.168.0.?"
  default = "192.168.0"
}

variable "net_segment_start" {
  description = "網段開始位置"
  default = 20
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
    "default"    = { memory = 2048, vcpu = 2 }
  }
}


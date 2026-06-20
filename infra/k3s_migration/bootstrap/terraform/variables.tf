# terraform/variables.tf

variable "vm_user" {
  description = "VM USER NAME"
  default = "debian"
}

variable "iso_image" {
  description = "ISO IMAGE"
  default = "debian-12-generic-amd64.qcow2"
}

variable "ssh_public_key_path" {
  description = "SSH KEY 位置"
  default = "~/.ssh/id_rsa.pub"
}

variable "net_segment" {
  description = "網段 ex: 192.168.0.?"
  default = "192.168.0"
}

variable "net_segment_master_start" {
  description = "Master 網段開始位置"
  default = 10
}

variable "net_segment_agent_start" {
  description = "Agent 網段開始位置"
  default = 20
}

variable "master_count" {
  description = "生成 Master 節點總數"
  default = 3
}

variable "agent_count" {
  description = "生成 Agent 節點總數 ( 有/無狀態 )"
  default = 2
}

variable "node_config" {
  description = "節點資源配置"
  type = map(object({
    memory = number
    vcpu   = number
  }))
  default = {
    "default"     = { memory = 2048, vcpu = 2 }
    "k3s-master-0"= { memory = 2048, vcpu = 2 }
    "k3s-master-1"= { memory = 2048, vcpu = 2 }
    "k3s-master-2"= { memory = 2048, vcpu = 2 }
    "k3s-agent-0" = { memory = 6144, vcpu = 4 }
    "k3s-agent-1" = { memory = 6144, vcpu = 4 }
    "k3s-agent-2" = { memory = 6144, vcpu = 4 }
  }
}
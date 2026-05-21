# terraform/variables.tf

variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "node_count" {
  default = 3
}

variable "node_memory" {
  default = "2048"
}

variable "node_cpu" {
  default = 2
}

variable "vm_user" {
  default = "debian"
}
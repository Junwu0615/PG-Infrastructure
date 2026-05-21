# terraform/variables.tf

variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "node_count" {
  default = 3
}

variable "vm_user" {
  default = "debian"
}
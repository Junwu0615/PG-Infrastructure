# terraform/main.tf

terraform {
  required_providers {
    libvirt = { source = "dmacvicar/libvirt" }
  }
}

provider "libvirt" { uri = "qemu:///system" }

# 導入 Debian 官方 Cloud Image
resource "libvirt_volume" "debian_base" {
  name   = "debian12_base.qcow2"
  source = "[https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2](https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2)"
  format = "qcow2"
}

# 每個 Node 的獨立磁碟 (從 Base Clone)
resource "libvirt_volume" "node_disk" {
  count          = 3
  name           = "k3s-disk-${count.index}.qcow2"
  base_volume_id = libvirt_volume.debian_base.id
  size           = 21474836480 # 20GB
}

# 注入 Cloud-Init 設定
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_public_key = file("~/.ssh/id_rsa.pub")
  })
}

# 建立 VM
resource "libvirt_domain" "k3s_nodes" {
  count  = 3
  name   = "k3s-node-${count.index}"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk { volume_id = libvirt_volume.node_disk[count.index].id }

  # 重要：等待 SSH 就緒後更新 Inventory 並跑 Ansible
  provisioner "local-exec" {
    command = <<EOT echo "[nodes]\n${join("\n", [for ip in libvirt_domain.k3s_nodes.*.network_interface.0.addresses[0] : "${ip} ansible_user="debian"])}""> ../ansible/inventory.ini
      sleep 30; # 等待 Cloud-init 完成 SSH Key 寫入
      export ANSIBLE_HOST_KEY_CHECKING=False;
      ansible-playbook -i ../ansible/inventory.ini ../ansible/playbooks/site.yml
    EOT
  }
}
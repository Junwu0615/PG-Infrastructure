# terraform/main.tf

terraform {
  required_providers {
    libvirt = { source = "dmacvicar/libvirt" }
  }
}

provider "libvirt" { uri = "qemu:///system" }

# 導入 Debian 官方 Cloud Image [cite: 1]
resource "libvirt_volume" "debian_base" {
  name   = "debian12_base.qcow2"
  source = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  format = "qcow2"
}

# 每個 Node 的獨立磁碟 [cite: 2]
resource "libvirt_volume" "node_disk" {
  count          = var.node_count
  name           = "k3s-disk-${count.index}.qcow2"
  base_volume_id = libvirt_volume.debian_base.id
  size           = 21474836480 # 20GB [cite: 2]
}

# 注入 Cloud-Init 設定
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_public_key = file(var.ssh_public_key_path)
  })
}

# 建立 VM
resource "libvirt_domain" "k3s_nodes" {
  count  = var.node_count
  name   = "k3s-node-${count.index}"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk { volume_id = libvirt_volume.node_disk[count.index].id }
}

# --- 新增/更新部分：使用 Template 處理 Inventory ---

# 1. 自動生成 Inventory 檔案
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    user       = var.vm_user
    master_ip  = libvirt_domain.k3s_nodes[0].network_interface.0.addresses[0]
    # 取得除第一台以外的所有 IP
    agent_ips  = slice(libvirt_domain.k3s_nodes[*].network_interface.0.addresses[0], 1, var.node_count)
  })
  filename = "../ansible/inventory.ini"
}

# 2. 確保 Inventory 產生且 VM 就緒後執行 Ansible
resource "null_resource" "ansible_trigger" {
  depends_on = [libvirt_domain.k3s_nodes, local_file.ansible_inventory]

  provisioner "local-exec" {
    # 這裡的 command 變得非常單純 [cite: 3, 5]
    command = "export ANSIBLE_HOST_KEY_CHECKING=False && cd ../ansible && ansible-playbook playbooks/site.yml"
  }
}
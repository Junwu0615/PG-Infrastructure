# terraform/main.tf

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1" # 強制指定穩定版本
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# 1. 取得現有的 Storage Pool (通常 KVM 預設為 default)
# 如果你沒有自定義 Pool，請確保 /var/lib/libvirt/images 權限正確
resource "libvirt_volume" "debian_base" {
  name   = "debian12_base.qcow2"
  pool   = "default" # 修正：加入必填的 pool
  source = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  format = "qcow2"
}

# 2. 建立節點磁碟
resource "libvirt_volume" "node_disk" {
  count          = var.node_count
  name           = "k3s-disk-${count.index}.qcow2"
  pool           = "default" # 修正：加入必填的 pool
  base_volume_id = libvirt_volume.debian_base.id
  size           = 21474836480 # 20GB [cite: 2]
}

# 3. Cloud-Init 設定
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  pool      = "default" # 修正：部分版本此處也需 pool
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_public_key = file(var.ssh_public_key_path)
  })
  # 修正：加入必填但可為空的 meta_data
  meta_data = ""
}

# 4. 建立 VM 節點
resource "libvirt_domain" "k3s_nodes" {
  count  = var.node_count
  name   = "k3s-node-${count.index}"
  memory = "2048"
  vcpu   = 2

  # 1. 移除 'type = "kvm"'，這在許多版本中是預設值或不支援直接賦值
  # 2. 修正 cloudinit 的引用方式
  cloudinit = libvirt_cloudinit_disk.commoninit.id

  # 修正：確保 network_interface 是以 block 形式存在
  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  # 修正：使用正確的 disk 引用方式
  disk {
    volume_id = libvirt_volume.node_disk[count.index].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
  }
}

# 5. 生成 Inventory 檔案 [cite: 3, 6]
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    user       = var.vm_user
    master_ip  = libvirt_domain.k3s_nodes[0].network_interface.0.addresses[0]
    agent_ips  = slice(libvirt_domain.k3s_nodes[*].network_interface.0.addresses[0], 1, var.node_count)
  })
  filename = "../ansible/inventory.ini"
}

# 6. 執行佈署
resource "null_resource" "ansible_trigger" {
  depends_on = [libvirt_domain.k3s_nodes, local_file.ansible_inventory]

  provisioner "local-exec" {
    command = "sleep 30 && export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i ../ansible/inventory.ini ../ansible/playbooks/site.yml"
  }
}
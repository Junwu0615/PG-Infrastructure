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
resource "libvirt_volume" "debian_base" {
  name   = "debian12_base.qcow2"
  pool   = "default"
  source = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  format = "qcow2"
}

# 2. 建立節點磁碟
resource "libvirt_volume" "node_disk" {
  count          = var.node_count
  name           = "k3s-disk-${count.index}.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.debian_base.id
  size           = 21474836480 # 20GB [cite: 2]
}

# 3. Cloud-Init 設定
resource "libvirt_cloudinit_disk" "commoninit" {
  count = var.node_count
  name  = "commoninit-${count.index}.iso" # 每個節點需要獨立的 ISO 以區分 Hostname
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_public_key = file(var.ssh_public_key_path)
    hostname       = "k3s-node-${count.index}" # 傳入正確的 Hostname
  })
  pool = "default"
}

# 4.0 定義網路 (寫死 DHCP 規則)
resource "libvirt_network" "k3s_net" {
  name   = "k3s_net"
  # bridge = "k3sbr0"
  mode   = "nat"
  domain = "k3s.local"
  addresses = ["${var.net_segment}.0/24"]

  dhcp {
    enabled = true
    # enabled = false
  }

  dns {
    enabled = true
    # 自動為所有節點產生 DNS 與靜態 DHCP 對應
    dynamic "hosts" {
      for_each = range(var.node_count)
      content {
        hostname = "k3s-node-${hosts.value}"
        ip       = "${var.net_segment}.${var.net_segment_start + hosts.value}"
      }
    }
  }
}

# 4. 建立 VM 節點
resource "libvirt_domain" "k3s_nodes" {
  count  = var.node_count
  name   = "k3s-node-${count.index}"

  memory = lookup(var.node_config, "k3s-node-${count.index}", var.node_config["default"]).memory
  vcpu   = lookup(var.node_config, "k3s-node-${count.index}", var.node_config["default"]).vcpu

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id # 引用對應索引

  network_interface {
    # network_name   = "default"
    network_id     = libvirt_network.k3s_net.id
    # 每個節點都有固定 MAC，確保 IP 被固定
    mac = format("52:54:00:00:00:%02x", var.net_segment_start + count.index)
    addresses    = ["${var.net_segment}.${var.net_segment_start + count.index}"]
    wait_for_lease = true
  }

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
    nodes      = [for i in range(var.node_count) : "${var.net_segment}.${var.net_segment_start + i}"]
    user       = var.vm_user
    master_ip  = "${var.net_segment}.${var.net_segment_start}"
    agent_ips  = [for i in range(1, var.node_count) : "${var.net_segment}.${var.net_segment_start + i}"]
  })
  filename = "../ansible/inventory.ini"
}

# 6. 執行佈署
resource "null_resource" "ansible_trigger" {
  # 當節點數量改變時，強制重新觸發 Ansible
  triggers = {
    node_count = var.node_count
    inventory_config = local_file.ansible_inventory.content
  }

  depends_on = [libvirt_domain.k3s_nodes, local_file.ansible_inventory]

  provisioner "local-exec" {
    command = <<EOT
      sleep 30

      # 使用迴圈清理所有節點的 SSH 指紋
      %{ for i in range(var.node_count) }
      ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${var.net_segment}.${var.net_segment_start + i}" || true
      %{ endfor }

      # 執行 Ansible
      export ANSIBLE_HOST_KEY_CHECKING=False
      ansible-playbook -i ../ansible/inventory.ini ../ansible/playbooks/site.yml
    EOT
  }
}
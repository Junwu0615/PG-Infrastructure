# terraform/main.tf

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1"
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

# 3. Cloud-init (nodes)
resource "libvirt_cloudinit_disk" "node_init" {
  count = var.node_count

  name = "k3s-node-${count.index}-ci.iso"
  pool = "default"

  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_public_key = file(var.ssh_public_key_path)
    hostname       = "k3s-node-${count.index}"
  })
}

# 4. 定義網路
resource "libvirt_network" "k3s_net" {
  name      = "k3s_net"
  mode      = "nat"
  domain    = "k3s.local"
  addresses = ["10.210.0.0/24"]

  dhcp {
    enabled = true
  }

  dns {
    enabled = true
  }
}


# 5. 建立 VM 節點
resource "libvirt_domain" "k3s_nodes" {
  count = var.node_count
  name   = "k3s-node-${count.index}"
  memory = lookup(var.node_config, "k3s-node-${count.index}", var.node_config["default"]).memory
  vcpu   = lookup(var.node_config, "k3s-node-${count.index}", var.node_config["default"]).vcpu

  cloudinit = libvirt_cloudinit_disk.node_init[count.index].id

  network_interface {
    network_id = libvirt_network.k3s_net.id

    mac = format(
      "52:54:00:00:00:%02x",
      var.net_segment_start + count.index
    )
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.node_disk[count.index].id
  }

  console {
    type = "pty"
    # target_port = "0"
    # target_type = "serial"
  }

  graphics {
    type = "spice"
    # listen_type = "address"
  }
}

# 6. Gateway VM
resource "libvirt_volume" "gateway_disk" {
  name           = "k3s-gateway.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.debian_base.id
  size           = 10737418240
}

resource "libvirt_cloudinit_disk" "gateway_init" {
  name = "k3s-gateway-ci.iso"
  pool = "default"

  user_data = templatefile("${path.module}/gateway_cloud_init.cfg", {
    ssh_public_key = file(var.ssh_public_key_path)
  })
}

resource "libvirt_domain" "gateway" {
  name   = "k3s-gateway"
  memory = 1024
  vcpu   = 1

  # hostname = "k3s-gateway"

  cloudinit = libvirt_cloudinit_disk.gateway_init.id

  network_interface {
    network_id = libvirt_network.k3s_net.id

    mac = "52:54:00:00:00:ff"

    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.gateway_disk.id
  }

  console {
    type = "pty"
    # target_port = "0"
    # target_type = "serial"
  }

  graphics {
    type = "spice"
    # listen_type = "address"
  }
}


# 7. 生成 Inventory 檔案 [cite: 3, 6]
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    gateway_ip = "${var.net_segment}.10"

    nodes      = [for i in range(var.node_count) : "${var.net_segment}.${var.net_segment_start + i}"]
    user       = var.vm_user
    master_ip  = "${var.net_segment}.${var.net_segment_start}"
    agent_ips  = [for i in range(1, var.node_count) : "${var.net_segment}.${var.net_segment_start + i}"]
  })
  filename = "../ansible/inventory.ini"
}

# 8. 執行佈署
resource "null_resource" "ansible_trigger" {
  # 當節點數量改變時，強制重新觸發 Ansible
  triggers = {
    node_count = var.node_count
    inventory_config = local_file.ansible_inventory.content
  }

  depends_on = [
    libvirt_domain.gateway,
    libvirt_domain.k3s_nodes,
    local_file.ansible_inventory
  ]

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
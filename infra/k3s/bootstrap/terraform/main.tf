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
  depends_on = [
    libvirt_volume.debian_base,
  ]

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
  domain    = "k8s.local"
  addresses = ["${var.net_segment}.0/24"]

  dhcp {
    enabled = true
  }

  dns {
    enabled = true

    hosts {
      hostname = "gateway"
      ip       = "${var.net_segment}.10"
    }

    dynamic "hosts" {
      for_each = range(var.node_count)
      content {
        hostname = "k3s-node-${hosts.value}"
        ip       = "${var.net_segment}.${var.net_segment_start + hosts.value}"
      }
    }
  }
}

# 5. 建立 VM 節點
resource "libvirt_domain" "k3s_nodes" {
  depends_on = [
    libvirt_volume.node_disk,
    libvirt_cloudinit_disk.node_init,
    libvirt_network.k3s_net,
  ]

  count = var.node_count
  name   = "k3s-node-${count.index}"
  memory = lookup(var.node_config, "k3s-node-${count.index}", var.node_config["default"]).memory
  vcpu   = lookup(var.node_config, "k3s-node-${count.index}", var.node_config["default"]).vcpu

  cloudinit = libvirt_cloudinit_disk.node_init[count.index].id

  network_interface {
    network_id = libvirt_network.k3s_net.id
    hostname   = "k3s-node-${count.index}"
    addresses  = ["${var.net_segment}.${var.net_segment_start + count.index}"]
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
    target_port = "0"
    target_type = "serial"
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
    hostname       = "k3s-gateway"
  })
}

resource "libvirt_domain" "gateway" {
  depends_on = [
    libvirt_volume.gateway_disk,
    libvirt_cloudinit_disk.gateway_init,
  ]

  name   = "k3s-gateway"
  memory = 1024
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.gateway_init.id

  network_interface {
    network_id = libvirt_network.k3s_net.id
    hostname   = "k3s-node-gateway"
    addresses  = ["${var.net_segment}.10"]
    mac = format(
      "52:54:00:00:00:%02x",
      10
    )
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.gateway_disk.id
  }

  console {
    type = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type = "spice"
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

# 8. wait_for_ssh
resource "null_resource" "wait_for_ssh" {
  depends_on = [
    local_file.ansible_inventory,
    libvirt_domain.k3s_nodes,
    libvirt_domain.gateway,
  ]

  provisioner "local-exec" {
    command = <<EOT
    for ip in \
    $(seq ${var.net_segment_start} $(( ${var.net_segment_start} + ${var.node_count} - 1 )) )
    do
      TARGET=${var.net_segment}.$ip

      echo "Waiting SSH on $TARGET"

      until ssh \
        -o StrictHostKeyChecking=no \
        -o BatchMode=yes \
        -o ConnectTimeout=5 \
        ${var.vm_user}@$TARGET 'echo ok' >/dev/null 2>&1
      do
        sleep 5
      done

      echo "$TARGET SSH ready"
    done
    EOT
  }
}

# 9. 執行佈署
resource "null_resource" "ansible_trigger" {
  depends_on = [
    local_file.ansible_inventory,
    libvirt_domain.gateway,
    libvirt_domain.k3s_nodes,
    null_resource.wait_for_ssh,
  ]

  # 當節點數量改變時，強制重新觸發 Ansible
  triggers = {
    node_count = var.node_count
    inventory_config = local_file.ansible_inventory.content
  }

  provisioner "local-exec" {
    command = <<EOT
      # 清理 SSH 指紋 ( gateway )
      ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${var.net_segment}.10" || true

      # 清理 SSH 指紋 ( 迴圈清理所有節點 )
      %{ for i in range(var.node_count) }
      ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${var.net_segment}.${var.net_segment_start + i}" || true
      %{ endfor }

      # 執行 Ansible
      export ANSIBLE_HOST_KEY_CHECKING=False
      ansible-playbook -i ../ansible/inventory.ini ../ansible/playbooks/site.yml
    EOT
  }
}
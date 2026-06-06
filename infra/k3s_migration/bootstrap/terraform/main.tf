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


# 2.1. Masters:  建立節點磁碟 + Cloud-init
resource "libvirt_volume" "master_disk" {
  count          = var.master_count
  name           = "k3s-master-disk-${count.index}.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.debian_base.id
  size           = 21474836480 # 20GB
}

resource "libvirt_cloudinit_disk" "master_init" {
  count = var.master_count
  name  = "k3s-master-${count.index}-ci.iso"
  pool  = "default"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_public_key = file(var.ssh_public_key_path)
    hostname       = "k3s-master-${count.index}"
  })
}


# 2.2. Agents:  建立節點磁碟 + Cloud-init
resource "libvirt_volume" "agent_disk" {
  count          = var.agent_count
  name           = "k3s-agent-disk-${count.index}.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.debian_base.id
  size           = 21474836480 # 20GB
}

resource "libvirt_cloudinit_disk" "agent_init" {
  count = var.agent_count
  name  = "k3s-agent-${count.index}-ci.iso"
  pool  = "default"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_public_key = file(var.ssh_public_key_path)
    hostname       = "k3s-agent-${count.index}"
  })
}


# 3. 定義網路
resource "libvirt_network" "k3s_net" {
  name      = "k3s_net"
  mode      = "nat"
  domain    = "k8s.local"
  addresses = ["${var.net_segment}.0/24"]

  dhcp { enabled = true }

  dns {
    enabled = true

    # Masters DNS
    dynamic "hosts" {
      for_each = range(var.master_count)
      content {
        hostname = "k3s-master-${hosts.value}"
        ip       = "${var.net_segment}.${var.net_segment_master_start + hosts.value}"
      }
    }

    # Agents DNS
    dynamic "hosts" {
      for_each = range(var.agent_count)
      content {
        hostname = "k3s-agent-${hosts.value}"
        ip       = "${var.net_segment}.${var.net_segment_agent_start + hosts.value}"
      }
    }
  }
}

# 4.1. 建立 VM 節點: Master 虛擬機
resource "libvirt_domain" "k3s_masters" {
  count = var.master_count
  name  = "k3s-master-${count.index}"

  memory = lookup(var.node_config, "k3s-master-${count.index}", var.node_config["default"]).memory
  vcpu   = lookup(var.node_config, "k3s-master-${count.index}", var.node_config["default"]).vcpu

  cloudinit = libvirt_cloudinit_disk.master_init[count.index].id

  network_interface {
    network_id     = libvirt_network.k3s_net.id
    hostname       = "k3s-master-${count.index}"
    addresses      = ["${var.net_segment}.${var.net_segment_master_start + count.index}"]
    mac            = format("52:54:00:00:10:%02x", var.net_segment_master_start + count.index)
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.master_disk[count.index].id
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

# 4.2. 建立 VM 節點: Agent 虛擬機
resource "libvirt_domain" "k3s_agents" {
  count = var.agent_count
  name  = "k3s-agent-${count.index}"

  memory = lookup(var.node_config, "k3s-agent-${count.index}", var.node_config["default"]).memory
  vcpu   = lookup(var.node_config, "k3s-agent-${count.index}", var.node_config["default"]).vcpu

  cloudinit = libvirt_cloudinit_disk.agent_init[count.index].id

  network_interface {
    network_id     = libvirt_network.k3s_net.id
    hostname       = "k3s-agent-${count.index}"
    addresses      = ["${var.net_segment}.${var.net_segment_agent_start + count.index}"]
    mac            = format("52:54:00:00:20:%02x", var.net_segment_agent_start + count.index)
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.agent_disk[count.index].id
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

# 5. Gateway VM
# resource "libvirt_volume" "gateway_disk" {
#   name           = "k3s-gateway.qcow2"
#   pool           = "default"
#   base_volume_id = libvirt_volume.debian_base.id
#   size           = 10737418240
# }
#
# resource "libvirt_cloudinit_disk" "gateway_init" {
#   name = "k3s-gateway-ci.iso"
#   pool = "default"
#
#   user_data = templatefile("${path.module}/gateway_cloud_init.cfg", {
#     ssh_public_key = file(var.ssh_public_key_path)
#     hostname       = "k3s-gateway"
#     vm_user        = var.vm_user
#   })
# }
#
# resource "libvirt_domain" "gateway" {
#   depends_on = [
#     libvirt_volume.gateway_disk,
#     libvirt_cloudinit_disk.gateway_init,
#   ]
#
#   name   = "k3s-gateway"
#   memory = 1024
#   vcpu   = 1
#
#   cloudinit = libvirt_cloudinit_disk.gateway_init.id
#
#   network_interface {
#     network_id = libvirt_network.k3s_net.id
#     hostname   = "k3s-node-gateway"
#     addresses  = ["${var.net_segment}.10"]
#     mac = format(
#       "52:54:00:00:00:%02x",
#       10
#     )
#     wait_for_lease = true
#   }
#
#   disk {
#     volume_id = libvirt_volume.gateway_disk.id
#   }
#
#   console {
#     type = "pty"
#     target_port = "0"
#     target_type = "serial"
#   }
#
#   graphics {
#     type = "spice"
#   }
# }

# 6. 生成 Inventory 檔案 [cite: 3, 6]
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    gateway_ip = "${var.net_segment}.10"
    user       = var.vm_user
    masters    = [for i in range(var.master_count) : "${var.net_segment}.${var.net_segment_master_start + i}"]
    agents     = [for i in range(var.agent_count) : "${var.net_segment}.${var.net_segment_agent_start + i}"]
  })
  filename = "../ansible/inventory.ini"
}

# 7. wait_for_ssh
resource "null_resource" "wait_for_ssh" {
  depends_on = [
    local_file.ansible_inventory,
    libvirt_domain.k3s_masters,
    libvirt_domain.k3s_agents,
    # libvirt_domain.gateway,
  ]

  provisioner "local-exec" {
    command = <<EOT
    # 設定 k3s_net 網路「開機自動啟動」
    virsh net-autostart k3s_net  || true

    for ip in \
    $(seq ${var.net_segment_master_start} $(( ${var.net_segment_master_start} + ${var.master_count} - 1 )) )
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
    EOT \

    for ip in \
    $(seq ${var.net_segment_agent_start} $(( ${var.net_segment_agent_start} + ${var.agent_count} - 1 )) )
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

# 8. 執行佈署
resource "null_resource" "ansible_trigger" {
  depends_on = [
    local_file.ansible_inventory,
    libvirt_domain.k3s_masters,
    libvirt_domain.k3s_agents,
    # libvirt_domain.gateway,
    null_resource.wait_for_ssh,
  ]

  # 當節點數量改變時，強制重新觸發 Ansible
  triggers = {
    master_count = var.master_count
    agent_count  = var.agent_count
    inventory_config = local_file.ansible_inventory.content
  }

  provisioner "local-exec" {
    command = <<EOT
      # 清理 SSH 指紋 ( gateway )
      # ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${var.net_segment}.10" || true

      # 動態清理 SSH 舊指紋 ( Masters )
      %{ for i in range(var.master_count) }
      ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${var.net_segment}.${var.net_segment_master_start + i}" || true
      %{ endfor }

      # 動態清理 SSH 舊指紋 ( Agents )
      %{ for i in range(var.agent_count) }
      ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${var.net_segment}.${var.net_segment_agent_start + i}" || true
      %{ endfor }

      # 執行 Ansible
      export ANSIBLE_HOST_KEY_CHECKING=False
      ansible-playbook -i ../ansible/inventory.ini ../ansible/playbooks/site.yml
    EOT
  }
}
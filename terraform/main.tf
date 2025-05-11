# Configure the Proxmox provider
provider "proxmox" {
  pm_api_url          = "https://${var.proxmox_host}/api2/json"
  pm_api_token_id     = var.proxmox_api_user
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
}

# --- Define the Kubernetes Control Plane VM ---
resource "proxmox_vm_qemu" "k8s_control_plane" {
  name        = "k8s-control-plane-01"
  target_node = var.proxmox_node
  clone       = var.template_name
  full_clone = true

  # VM Configuration (adjust as needed)
  cores    = 2
  memory   = 4096
  sockets  = 1
  os_type  = "cloud-init"
  agent    = 1            # Enable QEMU guest agent if installed in template
  boot   = "order=scsi0"
  onboot = true
  qemu_os = "l26" # Linux kernel 2.6/3.x/4.x
  tags = "kubernetes,control-plane"
  scsihw = "virtio-scsi-single"



  network {
    id     = 0
    model  = "virtio"
    bridge = var.vm_bridge
    firewall = true
  }

  # Cloud-Init settings
  sshkeys = join("\n", var.ssh_authorized_keys)
  ciuser      = var.ciuser # Replace with the user created by cloud-init in your template (e.g., 'debian', 'ubuntu')
  cipassword  = var.cipassword
  ciupgrade = true
  ipconfig0 = "ip=192.168.50.123/24,gw=192.168.50.1"
  # ipconfig0 = "ip=dhcp" # DHCP for simplicity
  # nameserver = var.nameserver

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.disk_storage_pool
          size    = "30G"
          iothread = true
          cache = "writeback"
        }
      }
    }
    ide {
      ide3 {
        cloudinit {
          storage = var.disk_storage_pool
        }
      }
    }
  }

}

# --- Define the Kubernetes Worker Node VM ---
resource "proxmox_vm_qemu" "k8s_worker_nodes" {
  count       = var.worker_node_count
  name        = "k8s-worker-node-${format("%02d", count.index + 1)}"
  target_node = var.proxmox_node
  clone       = var.template_name
  full_clone  = true

  # VM Configuration (adjust as needed)
  cores    = 2
  memory   = 20480
  balloon  = 2048
  sockets  = 1
  os_type  = "cloud-init"
  agent    = 1            # Enable QEMU guest agent if installed in template
  boot   = "order=scsi0"
  onboot = true
  qemu_os = "l26" # Linux kernel 2.6/3.x/4.x
  tags = "kubernetes,worker-node"
  scsihw = "virtio-scsi-single"

  network {
    id     = 0
    model  = "virtio"
    bridge = var.vm_bridge
    firewall = true
  }

  # Cloud-Init settings
  sshkeys = join("\n", var.ssh_authorized_keys)
  ciuser      = var.ciuser # Replace with the user created by cloud-init in your template (e.g., 'debian', 'ubuntu')
  cipassword  = var.cipassword
  ciupgrade = true
  ipconfig0 = "ip=dhcp"

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.disk_storage_pool
          size    = "50G"
          iothread = true
          cache = "writeback"
        }
      }
    }
    ide {
      ide3 {
        cloudinit {
          storage = var.disk_storage_pool
        }
      }
    }
  }
}

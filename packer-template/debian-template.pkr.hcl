# =====================================================
# Packer Template for Debian 12 Proxmox Cloud-Init
# =====================================================

# Define required variables for Proxmox connection secrets
variable "proxmox_host" {
  type = string
}

variable "proxmox_api_user" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_tls_insecure" {
  type    = bool
  default = true # Set to false if you have valid TLS certs
}

variable "ssh_authorized_keys" {
  type = list(string)
}

variable "http_interface" {
  type = string
}

variable "iso_url" {
  type = string
}

variable "checksum_url" {
  type = string
}

variable "disk_format" {
  type    = string
  default = "raw"
}

variable "disk_size" {
  type    = string
  default = "5G"
}

variable "disk_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "cloudinit_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "ssh_password" {
  type      = string
  default = "packer"
}

# Define Packer block for required plugins
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# --- Data Source to Fetch Debian JSON Metadata ---
data "http" "debian_sums" {
  url = var.checksum_url
}

# --- Locals Block to Process SHA512SUMS Data ---
locals {
  # Define the target filename we are looking for
  debian_iso_filename = "${basename(var.iso_url)}"

  # Get the raw multi-line string content from the fetched file
  sums_file_content = data.http.debian_sums.body

  # Split the file content into a list of individual lines
  sum_lines = split("\n", local.sums_file_content)

  # Find the specific line that contains our target filename
  # Creates a list of matching lines (expecting zero or one)
  matching_lines = [
    for line in local.sum_lines : line
    # Use strcontains for robust substring matching within each line
    if strcontains(line, local.debian_iso_filename)
  ]

  # Extract the first (and presumably only) matching line
  # Using element() safely gets the item or errors if list is empty
  target_line = element(local.matching_lines, 0)

  # --- Extract Checksum using split() ---
  # Split the target line by the common "two spaces" delimiter
  # This assumes the format is consistently "CHECKSUM<space><space>FILENAME"
  line_parts = split("  ", local.target_line)

  # The checksum should be the first element in the resulting list
  # Add a check for list not being empty before accessing element 0
  extracted_checksum = length(local.line_parts) > 0 ? element(local.line_parts, 0) : ""

  # Format the checksum string as required by Packer ("type:value")
  packer_checksum_string = format("%s:%s", "sha512", local.extracted_checksum)
}

# Define the image source
source "proxmox-iso" "debian" {
  # --- Proxmox Connection ---
  proxmox_url              = "https://${var.proxmox_host}/api2/json"
  username                 = var.proxmox_api_user
  token                    = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = var.proxmox_tls_insecure

  # --- Source Image Details ---
  boot_iso {
    type             = "scsi"
    iso_url          = var.iso_url
    unmount          = true
    iso_storage_pool = "local"
    iso_download_pve = false
    iso_checksum     = local.packer_checksum_string
  }

  # --- Temporary VM Configuration during build ---
  node            = var.proxmox_node
  vm_name         = trimsuffix(basename(var.iso_url), ".iso")
  cores           = 2
  memory          = 2048
  os              = "l26" # Linux kernel 2.6/3.x/4.x
  scsi_controller = "virtio-scsi-single"
  network_adapters {
    firewall = true
    model    = "virtio"
    bridge   = "vmbr0" # CRITICAL: Ensure this bridge provides DHCP access
  }
  disks {
    type         = "scsi"        # VirtIO Block is also good ("virtio")
    disk_size    = var.disk_size # Initial size, Terraform can resize later
    storage_pool = var.disk_storage_pool
    format       = var.disk_format
    io_thread    = true
  }

  http_directory = "./config"
  http_interface = var.http_interface # Use the interface of your current internet connection
  boot_wait      = "10s"
  boot_command   = ["<esc><wait>auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>"]

  # --- Cloud-Init Configuration for build VM ---
  cloud_init              = true
  cloud_init_storage_pool = var.cloudinit_storage_pool

  # --- SSH Communicator ---
  # How Packer connects to the temporary VM to run provisioners
  communicator = "ssh"
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password # It's a temporary password
  # ssh_private_key_file = "~/.ssh/id_rsa" # Use key if needed/configured on image
  ssh_timeout = "10m" # Increase timeout for slow downloads/updates

  # --- Output Template Configuration ---
  template_name        = "debian-template-packer" # Name of the FINAL template
  template_description = "Built from ${basename(var.iso_url)} on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
}

# Define the build block
build {
  name    = "debian-template"
  sources = ["source.proxmox-iso.debian"]

  provisioner "shell" {
    # Set environment variable to prevent interactive prompts from apt/debconf
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
    ]
    # Execute commands inline
    inline = [
      "echo '==> Upgrading all packages...'",
      "sudo apt-get update",
      "sudo apt-get -y dist-upgrade"
    ]
  }

  # --- Provisioners: Run inside the temporary VM ---
  provisioner "file" {
    destination = "/etc/cloud/cloud.cfg"
    content = templatefile("./config/cloud.cfg.tpl", {
      ssh_authorized_keys = var.ssh_authorized_keys
    })
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
    ]
    # Execute commands inline
    inline = [
      "echo '==> Cleaning up...'",
      "sudo apt-get -y autoremove",
      "sudo apt-get autoclean",
      "sudo apt-get clean",
      "sudo rm -f /etc/ssh/ssh_host_*_key*",
      "sudo truncate -s 0 /etc/machine-id || true",
      "sudo rm -f /var/lib/dbus/machine-id || true",
      "sudo truncate -s 0 /root/.bash_history || true",
      "sudo sync",
      "echo '==> Cleanup complete.'"
    ]
  }
}

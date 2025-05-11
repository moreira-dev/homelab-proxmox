proxmox_host         = "10.10.0.10:8006"
proxmox_node         = "pve-01"
proxmox_api_user     = "root@pam"
proxmox_api_password = "my secret password"
http_interface       = "Ethernet"

template_name        = "debian-template-packer"
iso_url              = "https://debian.mirror.digitalpacific.com.au/debian-cd/12.10.0/amd64/iso-cd/debian-12.10.0-amd64-netinst.iso"
checksum_url         = "https://debian.mirror.digitalpacific.com.au/debian-cd/12.10.0/amd64/iso-cd/SHA512SUMS"

ssh_authorized_keys  = [
  "ssh-rsa AAAAB3NzaC1y..."
]

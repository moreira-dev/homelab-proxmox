proxmox_host               = "10.10.0.10:8006"
proxmox_api_user           = "root@pam!terraform-token"
proxmox_api_token_secret   = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
proxmox_node               = "pve-01"
ssh_authorized_keys = [
  "ssh-rsa AAAAB3NzaC1y...",
]
template_name              = "debian-template-packer"
disk_storage_pool          = "local-lvm"
cloudinit_storage_pool     = "local"
ciuser                     = "debian"
cipassword                 = "My Secret Password"
worker_node_count          = 1

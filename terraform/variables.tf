variable "proxmox_host" {
  type        = string
  description = "The hostname or IP address of your Proxmox server."
}

variable "proxmox_api_user" {
  type        = string
  description = "Proxmox API user (e.g., user@pve or user@pam)."
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API token secret."
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  type        = bool
  description = "Set to true to skip TLS certificate verification."
  default     = true
}

variable "proxmox_node" {
  type        = string
  description = "The Proxmox node to deploy VMs on."
}

variable "template_name" {
  type        = string
  description = "The name of the VM template to clone from."
  default     = ""
}

variable "worker_node_count" {
  type        = number
  description = "The number of Kubernetes worker nodes to create."
  default     = 1
}

variable "ssh_authorized_keys" {
  type        = list(string)
  description = "Public SSH key(s) to inject into the VMs via Cloud-Init."
  sensitive   = true
}

variable "disk_storage_pool" {
  type        = string
  description = "The Proxmox storage pool for the VM disks."
}

variable "cloudinit_storage_pool" {
  type        = string
  description = "The Proxmox storage pool for the Cloud-Init drive."
}

variable "ciuser" {
  type        = string
  description = "Default username configured by cloud-init in the template."
  default     = "debian"
}

variable "cipassword" {
  type        = string
  description = "Default cloud-init password (less secure, prefer SSH keys)."
  sensitive   = true
}

variable "vm_bridge" {
  type        = string
  description = "Proxmox network bridge for the VMs."
  default     = "vmbr0"
}

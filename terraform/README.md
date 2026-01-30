# Terraform Deployment

> **Getting Started?** See the [main README](../README.md) for quick start instructions.

This directory contains the Terraform configuration for deploying VMs from the Packer-built template.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | VM resource definitions (control plane + worker nodes) |
| `variables.tf` | Input variable declarations with defaults |
| `versions.tf` | Provider versions and HCP Terraform backend config |
| `outputs.tf` | Output definitions (VM IP addresses) |
| `example-variables.tfvars` | Example variables file (copy to `terraform.tfvars`) |

## All Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `proxmox_host` | Proxmox API URL | — |
| `proxmox_node` | Proxmox node name | — |
| `proxmox_api_user` | API user (`user@realm!token-name`) | — |
| `proxmox_api_token_secret` | API token (use `TF_VAR_` env var) | — |
| `proxmox_skip_tls_verify` | Skip TLS certificate verification | `true` |
| `template_name` | Name of the Packer-built template to clone | — |
| `worker_node_count` | Number of worker VMs to create | `1` |
| `vm_bridge` | Network bridge | `vmbr0` |
| `disk_storage_pool` | Storage pool for VM disks | `local-lvm` |
| `cloudinit_storage_pool` | Storage pool for cloud-init drives | `local-lvm` |
| `cloudinit_user` | Default user created by cloud-init | `debian` |
| `cloudinit_password` | Password for cloud-init user (use env var) | — |
| `ssh_public_keys` | SSH public keys (newline-separated) | — |

## HCP Terraform Setup

This configuration uses HCP Terraform (Terraform Cloud) for remote state storage.

### First-time setup

1. Create a free account at [app.terraform.io](https://app.terraform.io)
2. Create an organization
3. The workspace is created automatically on first `terraform init`

### Environment variables

**Linux/macOS:**
```bash
export TF_CLOUD_ORGANIZATION="your-org-name"
export TF_WORKSPACE="homelab-proxmox"  # or any name you choose
export TF_VAR_proxmox_api_token_secret="your-token"
```

**Windows PowerShell:**
```powershell
$env:TF_CLOUD_ORGANIZATION = "your-org-name"
$env:TF_WORKSPACE = "homelab-proxmox"
$env:TF_VAR_proxmox_api_token_secret = "your-token"
```

**Windows (persistent):**
```powershell
[System.Environment]::SetEnvironmentVariable("TF_CLOUD_ORGANIZATION", "your-org-name", "User")
[System.Environment]::SetEnvironmentVariable("TF_WORKSPACE", "homelab-proxmox", "User")
# Open a new terminal after running these
```

## Customizing VM Specs

Edit `main.tf` to modify the VM resources:

**Control plane** (`proxmox_vm_qemu.k8s_control_plane`):
- `cores`, `memory`, `disk.size` — Compute resources
- `ipconfig0` — Static IP configuration

**Worker nodes** (`proxmox_vm_qemu.k8s_worker_nodes`):
- Same options as control plane
- `count` — Controlled by `var.worker_node_count`
- Uses DHCP by default

## Outputs

After `terraform apply`, these outputs are available:

```bash
terraform output k8s_control_plane_ip    # Control plane IP
terraform output k8s_worker_node_ips     # List of worker IPs
```

Note: IP detection requires QEMU guest agent running in the VMs.

## Troubleshooting

### "Could not find VM template"

The template name in `terraform.tfvars` doesn't match the Packer-built template. Check the exact name in Proxmox UI or use `pvesh get /nodes/<node>/qemu --output-format json | jq '.[] | select(.template==1)'`.

### VMs created but no IP in outputs

QEMU guest agent isn't running or isn't installed. The template should have it pre-installed; verify with `systemctl status qemu-guest-agent` inside a VM.

### Cloud-init not applying configuration

- Check cloud-init logs: `cat /var/log/cloud-init-output.log`
- Verify cloud-init drive is attached in Proxmox UI
- Ensure `cicustom` isn't overriding the configuration

### API permission errors

Ensure the API token has these Proxmox permissions:
- `VM.Allocate`, `VM.Clone`, `VM.Config.*`, `VM.Monitor`, `VM.Audit`
- `Datastore.AllocateSpace`, `Datastore.Audit`
- `SDN.Use` (if using SDN)

### Debug mode

```bash
TF_LOG=DEBUG terraform apply
```

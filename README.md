# Homelab Proxmox: Automated VM Deployment with Packer & Terraform

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Automate the creation and deployment of Debian 12 virtual machines on Proxmox VE. This project uses a two-stage pipeline: **Packer** builds a reusable VM template, and **Terraform** deploys VMs from that template with cloud-init customization.

## Who Is This For?

- **Homelab enthusiasts** who want to quickly spin up VMs on Proxmox without manual installation
- **Kubernetes users** looking to bootstrap a cluster (the default config creates 1 control plane + N worker nodes)
- **Anyone** who wants reproducible, infrastructure-as-code VM deployments on Proxmox

## What You Get

1. A **golden Debian 12 template** with cloud-init pre-configured (built once, clone many times)
2. **Automated VM deployment** with customizable specs (CPU, RAM, disk, networking)
3. **Cloud-init integration** for SSH keys, hostname, and user configuration on first boot

## Prerequisites

- [Proxmox VE 8.x](https://www.proxmox.com/en/proxmox-ve) server
- [Packer](https://www.packer.io/downloads) installed locally
- [Terraform](https://www.terraform.io/downloads) installed locally
- [HCP Terraform](https://cloud.hashicorp.com/products/terraform) account (free tier works) for remote state
- Proxmox API token with permissions to create VMs, templates, and manage storage

## Quick Start

### Step 1: Build the Template (Packer)

```bash
cd packer-template

# Copy and edit the variables file
cp example-variables.pkrvars.hcl variables.auto.pkrvars.hcl
# Edit variables.auto.pkrvars.hcl with your Proxmox details

# Set your API token (don't commit this!)
export PKR_VAR_proxmox_api_token_secret="your-token-here"

# Build the template
packer init .
packer build .
```

This creates a VM template named `debian-template-packer` on your Proxmox server. The build downloads a Debian 12 netinstall ISO, runs an automated installation via preseed, installs cloud-init and QEMU guest agent, then converts the VM to a template.

### Step 2: Deploy VMs (Terraform)

```bash
cd terraform

# Copy and edit the variables file
cp example-variables.tfvars terraform.tfvars
# Edit terraform.tfvars with your Proxmox details and desired VM specs

# Set environment variables
export TF_VAR_proxmox_api_token_secret="your-token-here"
export TF_CLOUD_ORGANIZATION="your-org-name"
export TF_WORKSPACE="your-workspace-name"

# Login to HCP Terraform
terraform login

# Deploy
terraform init
terraform plan    # Review what will be created
terraform apply   # Create the VMs
```

This clones the template and creates:
- **1 control plane VM**: Static IP (default: 192.168.50.123), 2 cores, 4GB RAM, 30GB disk
- **N worker VMs**: DHCP, 2 cores, 20GB RAM, 50GB disk (set `worker_node_count` in your tfvars)

### Step 3: Connect to Your VMs

```bash
ssh debian@<vm-ip>
```

The default user is `debian`. Your SSH public key (configured in the variables files) is injected via cloud-init.

## How It Works

<img src="docs/diagrams/architecture.svg" alt="Architecture Diagram" width="600">

## Configuration & Customization

For detailed configuration options, see the component READMEs:

- **[packer-template/README.md](packer-template/README.md)** — All Packer variables, customizing Debian installation and cloud-init defaults, Packer-specific troubleshooting
- **[terraform/README.md](terraform/README.md)** — All Terraform variables, HCP Terraform setup (including Windows instructions), customizing VM specs, Terraform-specific troubleshooting

## Cleanup

```bash
cd terraform
terraform destroy  # Removes all VMs created by Terraform
```

To remove the template, delete it manually from the Proxmox web UI.

## License

MIT License - see [LICENSE](LICENSE) for details.

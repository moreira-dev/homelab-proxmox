# Proxmox Debian Template & VM Deployment with Packer, Terraform and Cloud-Init

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)


This project provides an automated solution using HashiCorp's Packer and Terraform to build a standardized Debian 12 (Bookworm) VM template for Proxmox Virtual Environment (PVE),
and to deploy virtual machines (VMs). This workflow leverages cloud-init for easy customization upon deployment, simplifying the creation of new Debian VMs in your environment.

## Features

* **Packer Template Creation:**
    * Builds a Debian 12 (configurable) Proxmox template.
    * Uses cloud-init for initial VM configuration.
* **Terraform VM Deployment:**
    * Deploys one or more VMs from the Packer-built template.
    * Configures VMs using cloud-init.
    * Uses Terraform Cloud (HCP Terraform) backend for state management.
* **Customizable:** Easily adapt variables for your Proxmox environment, VM specifications, and Debian version.

## Prerequisites

Before you begin, ensure you have the following installed and configured:

* [Packer](https://www.packer.io/downloads)
* [Terraform](https://www.terraform.io/downloads)
* Access to a Proxmox VE server (version 8.x recommended).
* A Proxmox API token with sufficient permissions to create templates, VMs, manage storage, and (if used) firewall rules.
* [Git](https://git-scm.com/downloads) for cloning this repository.
* An [HCP Terraform](https://cloud.hashicorp.com/products/terraform) (Terraform Cloud) account if you wish to store your Terraform state remotely.

## Configuration Overview

Detailed configuration instructions are available within the respective `packer-template` and `terraform` directories:

* **Packer:** See [packer-template/README.md](packer-template/README.md) for instructions on configuring and building the VM template.
* **Terraform:** See [terraform/README.md](terraform/README.md) for instructions on configuring and deploying VMs.

**Sensitive Credentials:**
It is **strongly recommended** to provide Proxmox API tokens and other sensitive data via environment variables:
* For Packer: `PKR_VAR_proxmox_api_token_secret`
* For Terraform: `TF_VAR_proxmox_api_token_secret`
  These variables will be automatically picked up by Packer and Terraform if set in your shell environment.
* Alternatively, you can create a `variables.auto.pkrvars.hcl` file for Packer and a `terraform.tfvars` file for Terraform to store your sensitive and site-specific settings (API keys, IPs, etc.).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

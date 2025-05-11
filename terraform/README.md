# Terraform VM Deployment for Proxmox

This folder contains the Terraform configuration files to deploy virtual machines (VMs) on Proxmox Virtual Environment (PVE) using a pre-built Cloud-Init template. 
This Terraform configuration is designed as a starter for a k8s cluster, with one Control Plane and `n` worker nodes.

## Setup

1. **Create Variables File:**
    * Copy the example variables file:
        ```bash
        cp example-variables.tfvars terraform.tfvars
        ```
    * **Edit `terraform.tfvars`** and fill in your specific details.

2. **Review Configuration:**
    * Examine `main.tf` if you want to change VM resources (cores, memory, disk size), network bridge (`vmbr0`), storage pools (`local-lvm`), etc.
    
## Deployment

1. **Login to HCP Terraform:**
   * Ensure you are properly authenticated into HCP Terraform by running:
       ```bash
       terraform login
       ```

2.  **Set Environment Variables for your HCP Terraform:**

    * **For Linux/macOS (e.g., bash, zsh):**
     Open your terminal and execute the following commands, replacing the placeholder values with your actual details:
       ```bash
       export TF_CLOUD_ORGANIZATION="your-hcp-organization-name"
       export TF_WORKSPACE="your-desired-workspace-name"
       ```
     To make these settings persist for your current terminal session or for future sessions, consider adding these lines to your shell's profile file (e.g., `~/.bashrc`, `~/.zshrc`, `~/.profile`). After editing the profile file, either source it (e.g., `source ~/.bashrc`) or open a new terminal window.

    * **For Windows (PowerShell):**
     Open PowerShell and execute the following commands, replacing the placeholder values:
       ```powershell
       $env:TF_CLOUD_ORGANIZATION = "your-hcp-organization-name"
       $env:TF_WORKSPACE = "your-desired-workspace-name"
       ```
     These commands set the variables for the current PowerShell session. For a more persistent setting (across PowerShell sessions for the current user), use:
       ```powershell
       [System.Environment]::SetEnvironmentVariable("TF_CLOUD_ORGANIZATION", "your-hcp-organization-name", "User")
       [System.Environment]::SetEnvironmentVariable("TF_WORKSPACE", "your-desired-workspace-name", "User")
       ```
     After using `SetEnvironmentVariable`, you **must open a new PowerShell window** for the changes to be recognized by subsequent commands.

    Replace `"your-hcp-organization-name"` with your actual HCP Terraform organization name and `"your-desired-workspace-name"` with the name you want for your workspace (Terraform will create this workspace if it doesn't already exist in your organization).

3. **Initialize Terraform:**
    * Download the required Terraform provider for Proxmox. Run this in the same directory as `main.tf`:
        ```bash
        terraform init
        ```
      
4. **Plan the Deployment:**
    * Generate and show an execution plan:
        ```bash
        terraform plan
        ```
    * This command will show you what resources will be created, modified, or destroyed.

5. **Apply the Configuration:**
    * Start the deployment process:
        ```bash
        terraform apply
        ```
    * Terraform will prompt for confirmation before proceeding. Type `yes` to continue.

6. **Monitor the Deployment:**
    * The deployment process can take a few minutes depending on your internet speed, host hardware, and template size.
    * You can watch the progress in the Terraform output console.
    * You can also monitor the VMs being created via the Proxmox web UI.

## Cleanup

To destroy the created VMs, run:
```bash
terraform destroy
```

# Packer Build: Debian 12 Cloud-Init Template for Proxmox VE

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

This project provides an automated solution using HashiCorp Packer to build a standardized Debian 12 (Bookworm) VM template for Proxmox Virtual Environment (PVE). 
The resulting template includes cloud-init for easy customization upon deployment, and simplifies the creation of new Debian VMs in your environment.

Cloud-Init simplifies the setup of virtual machines by automating tasks like setting the hostname, configuring the network, creating users, and adding SSH keys when the machine starts for the first time. 
This is similar to how AWS EC2 instances are customized using user data. With Cloud-Init, you can create a single generic Proxmox template and quickly deploy new VMs without manually installing or configuring the operating system each time. 
This saves time and ensures all VMs are set up consistently.

## Key Components

1. **Packer Template (`debian-template.pkr.hcl`)**:
   * The main Packer file orchestrating the build process.
   * Defines the Proxmox connection, temporary VM specs, ISO download, provisioning steps (installing software, cleanup), and final template conversion.
   * Uses the `proxmox-iso` builder.

2. **Preseed Configuration (`config/preseed.cfg`)**:
   * Automates the Debian 12 network installation process, answering all installer questions.

3. **Cloud-Init User Data (`config/cloud.cfg.tpl`)**:
   * A Packer template file used to generate the `/etc/cloud/cloud.cfg` file *within the VM*.
   * Configures cloud-init default behavior, particularly setting up SSH keys passed via Packer variables.

4. **Variables Files**:
   * `debian-template.pkr.hcl`: Defines the variables the template accepts (see `variable` blocks).
   * `example-variables.pkrvars.hcl`: An example file showing required variables you need to set. **Do not edit this directly.**
   * `variables.auto.pkrvars.hcl`: **(Not committed to Git)** Create this file to store your sensitive and site-specific settings (API keys, IPs, etc.). Packer automatically loads `.auto.pkrvars.hcl` files.

## Prerequisites

* **Proxmox VE:** Version 8.0 or later recommended.
* **Proxmox API Token:** A user and API token on Proxmox with sufficient permissions (e.g., `Administrator` role or a custom role allowing VM creation, modification, console access, template creation).
* **Network Access:**
   * The machine running Packer needs network access to the Proxmox API endpoint (e.g., `https://your-proxmox-ip:8006`).
   * The temporary VM created during the build needs network access to a Debian mirror (e.g., `deb.debian.org`).
   * The temporary VM needs network access **back to** the machine running Packer to download the `preseed.cfg`. **Firewalls must allow this.** (See Troubleshooting).
* **Packer:** HashiCorp Packer installed (latest version recommended). [Install Guide](https://developer.hashicorp.com/packer/install)
* **Git:** Required for cloning this repository.
* **SSH Keypair:** You'll need an SSH public key to inject into the template for accessing deployed VMs.

## Setup & Configuration

1. **Clone the Repository:**
    ```bash
    git clone [https://github.com/moreira-dev/homelab-proxmox.git](https://github.com/moreira-dev/homelab-proxmox.git) # Replace with your actual repo URL if different
    cd homelab-proxmox/packer-template/
    ```

2. **Create Variables File:**
   * Copy the example variables file:
       ```bash
       cp example-variables.pkrvars.hcl variables.auto.pkrvars.hcl
       ```
   * **Edit `variables.auto.pkrvars.hcl`** and fill in your specific details.

3. **Review Configuration (Optional):**
   * Examine `debian-template.pkr.hcl` if you want to change VM resources (cores, memory, disk size), network bridge (`vmbr0`), storage pools (`local-lvm`), etc.
   * Review `config/preseed.cfg` if you need to customize the Debian installation (e.g., default packages, partitioning, timezone).
   * Review `config/cloud.cfg.tpl` if you want to change default cloud-init behavior.

## Building the Template

1. **Initialize Packer:**
   * Download the required Packer plugin for Proxmox. Run this in the same directory as `debian-template.pkr.hcl`:
       ```bash
       packer init .
       ```

2. **Run the Build:**
   * Start the template creation process:
       ```bash
       packer build .
       ```
   * Packer will automatically use the variables defined in `variables.auto.pkrvars.hcl`.

3. **Monitor the Build:**
   * The build process can take 5-10 minutes depending on your internet speed, host hardware, and mirror speed.
   * You can watch the progress in the Packer output console.
   * You can also monitor the temporary VM being created and provisioned via the Proxmox web UI (look for a VM named after the ISO file).

## Using the Template

1. **Find the Template:** Once the Packer build completes successfully, you will find a new VM template in your target Proxmox storage pool (usually "local"). The template name is defined in the `template_name` variable within `debian-template.pkr.hcl` (default might be `debian-template-packer`).
2. **Deploy a New VM:**
   * In the Proxmox UI, right-click the template and select "Clone".
   * Configure the new VM's name, resources, etc. Choose "Linked Clone" for space efficiency or "Full Clone" for an independent copy.
   * **Crucially:** Configure the **Cloud-Init** tab during cloning:
      * **User:** Set the desired default username for the new VM.
      * **Password:** Set a password for the user.
      * **DNS:** Configure DNS settings if needed.
      * **SSH Public Key:** Paste the public key(s) for SSH access. (This overrides the default key baked into the template via Packer vars if desired).
      * **IP Config:** Configure static IP or DHCP for the VM's network interface(s).
3. **Boot and Access:** Start the newly cloned VM. It should boot up and apply the cloud-init settings. You can then access it via SSH using the key you provided or via the Proxmox console using the user/password set in cloud-init.

## Troubleshooting

* **Enable Debug Logs:** For detailed logs, run Packer with the `PACKER_LOG` environment variable:
    ```bash
    PACKER_LOG=1 packer build .
    ```
* **VM Cannot Reach Packer HTTP Server:**
   * **Symptoms:** Build stalls during preseed phase; `wget` test from VM console (Alt+F2) to `http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg` fails/times out.
   * **Causes:** Firewall on the machine running Packer (e.g., Windows Firewall) might be blocking incoming connections from the VM's IP; network routing issue between VM network (`vmbr0`) and Packer host network.
   * **Fixes:** Adjust host firewall rules; ensure the `http_interface` variable in the `variables.auto.pkrvars.hcl` file is using your internet interface.
* **APIPA Address (`169.254.x.x`):**
   * **Symptoms:** Packer logs show `{{ .HTTPIP }}` resolving to `169.254.x.x`.
   * **Cause:** Packer is binding its HTTP server to a network interface on the host machine that failed to get an IP via DHCP.
   * **Fix:** Ensure the `http_interface` variable in the `variables.auto.pkrvars.hcl` file is using your internet interface.
* **Preseed Stalls:**
   * **Symptoms:** Installation shows progress then hangs on a blue screen.
   * **Causes:** Issue in `preseed.cfg` (e.g., network config, package install failure, mirror unreachable, missing directive).
   * **Fixes:** Use Proxmox console, switch to virtual consoles (`Alt+F4` for logs, `Alt+F2` for shell). Check logs for errors. Test network connectivity (`ping`, `nslookup`, `wget`) from the shell. Review and simplify `preseed.cfg`. Check Debian mirror status.
* **SSH Connection Fails:**
   * **Symptoms:** Packer reports connection timed out or authentication failed after the OS install finishes.
   * **Causes:** SSH server not installed/running; user specified in `ssh_username` not created or password incorrect; firewall blocking SSH port; QEMU Guest Agent issues delaying IP reporting.
   * **Fixes:** Ensure `ssh-server` is in `pkgsel/include` in `preseed.cfg`; verify user/password setup in preseed matches Packer communicator settings; check VM firewall; ensure guest agent is installed.
* **Proxmox API Errors:**
   * **Symptoms:** Errors mentioning authentication, permissions, or object not found.
   * **Causes:** Incorrect API user/token/node; insufficient permissions for the API token.
   * **Fixes:** Verify credentials in `variables.auto.pkrvars.hcl`; ensure the token has necessary privileges in Proxmox Datacenter -> Permissions -> API Tokens.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

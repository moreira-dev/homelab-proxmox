# Packer Template for Proxmox Debian VM

This folder contains the configuration files and scripts to create a standardized Debian 12 (Bookworm) VM template for Proxmox Virtual Environment (PVE) using HashiCorp Packer and Cloud-Init.

## Setup

1. **Create Variables File:**
    * Copy the example variables file:
        ```bash
        cp example-variables.pkrvars.hcl variables.auto.pkrvars.hcl
        ```
    * **Edit `variables.auto.pkrvars.hcl`** and fill in your specific details.

2. **Review Configuration:**
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

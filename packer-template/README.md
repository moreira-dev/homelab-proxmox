# Packer Template

> **Getting Started?** See the [main README](../README.md) for quick start instructions.

This directory contains the Packer configuration for building a Debian 12 VM template on Proxmox.

## Files

| File | Purpose |
|------|---------|
| `debian-template.pkr.hcl` | Main Packer configuration (VM specs, provisioners, output template) |
| `config/preseed.cfg` | Debian installer automation (packages, partitioning, locale, users) |
| `config/cloud.cfg.tpl` | Cloud-init configuration embedded in the template |
| `example-variables.pkrvars.hcl` | Example variables file (copy to `variables.auto.pkrvars.hcl`) |

## All Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `proxmox_host` | Proxmox API URL (e.g., `https://192.168.1.100:8006`) | Yes |
| `proxmox_node` | Proxmox node name | Yes |
| `proxmox_api_user` | API user in format `user@realm!token-name` | Yes |
| `proxmox_api_token_secret` | API token secret (use `PKR_VAR_` env var) | Yes |
| `http_interface` | Network interface for Packer's HTTP server | Yes |
| `ssh_public_key` | SSH public key to embed in the template | Yes |
| `iso_url` | Debian netinstall ISO URL | No (has default) |
| `iso_checksum_url` | ISO checksum URL | No (has default) |

## Customizing the Debian Installation

Edit `config/preseed.cfg` to change:

- **Packages**: Modify `pkgsel/include` to add/remove packages installed during setup
- **Partitioning**: Adjust LVM configuration in the partitioning section
- **Locale/Timezone**: Change `d-i debian-installer/locale` and `d-i time/zone`
- **Root password**: Change `d-i passwd/root-password` (this is reset by cloud-init on deployment)

## Customizing Cloud-Init Defaults

Edit `config/cloud.cfg.tpl` to change:

- **Default user**: Modify the `users` block (default: `debian` with sudo)
- **SSH settings**: Adjust `disable_root`, `ssh_pwauth`, etc.
- **Modules**: Enable/disable cloud-init modules in the `cloud_init_modules` lists

## Troubleshooting

### Build stalls during preseed (VM can't fetch preseed.cfg)

**Symptoms**: Installation hangs; testing `wget http://<packer-ip>:<port>/preseed.cfg` from VM console (Alt+F2) fails.

**Causes & Fixes**:
1. **Firewall blocking**: Your machine's firewall is blocking incoming connections from the VM. Add a rule to allow traffic from your VM network.
2. **Wrong interface**: `http_interface` is set to the wrong network interface. Run `ip addr` (Linux/macOS) or `ipconfig` (Windows) to find the correct one.

### Packer HTTP IP shows `169.254.x.x`

Packer is binding to an interface without a valid IP address. This happens when `http_interface` points to a disconnected or misconfigured adapter. Set it to your primary network interface.

### Preseed stalls on blue screen

**Diagnosis**: Use Proxmox console, press Alt+F4 for installer logs, Alt+F2 for a shell.

**Common causes**:
- Debian mirror unreachable (test with `ping deb.debian.org` from shell)
- Syntax error in preseed.cfg
- Package in `pkgsel/include` doesn't exist

### SSH connection timeout after install completes

1. Verify `ssh-server` is in `pkgsel/include` in preseed.cfg
2. Check that `ssh_username` and `ssh_password` in the Packer config match what preseed.cfg creates
3. Ensure QEMU guest agent is installed (needed for IP detection)

### Proxmox API authentication errors

- Verify `proxmox_api_user` format: `user@realm!token-name` (e.g., `root@pam!packer`)
- Ensure the API token has permissions: `VM.Allocate`, `VM.Config.*`, `Datastore.AllocateSpace`, `Sys.Modify`
- Check `proxmox_host` includes the port (`:8006`)

### Debug mode

```bash
PACKER_LOG=1 packer build .
```

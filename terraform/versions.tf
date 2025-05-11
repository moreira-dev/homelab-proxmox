terraform {

  cloud {
    // Organization and workspace name will be primarily sourced from
    // TF_CLOUD_ORGANIZATION and TF_WORKSPACE environment variables.
    workspaces {}
  }

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc8"
    }
  }
}

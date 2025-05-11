# The Proxmox provider attempts to get the IP from the QEMU guest agent.
output "k8s_control_plane_ip" {
  description = "IP address of the K8s Control Plane VM. May require QEMU Guest Agent to be running."
  value       = proxmox_vm_qemu.k8s_control_plane.default_ipv4_address
}
output "k8s_worker_node_ips" { # Renamed for clarity
  description = "List of IP addresses for the K8s Worker Node VMs. Requires QEMU Guest Agent."
  value       = proxmox_vm_qemu.k8s_worker_nodes[*].default_ipv4_address
}

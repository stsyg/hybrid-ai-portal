output "control_plane_ip" {
  value = azurerm_network_interface.k3s_cp.private_ip_address
}

output "worker_ips" {
  value = [for nic in azurerm_network_interface.k3s_worker : nic.private_ip_address]
}
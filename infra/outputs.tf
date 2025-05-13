output "control_plane_ip" {
  value = azurerm_network_interface.k3s_cp.private_ip_address
}

output "worker_ips" {
  value = [for nic in azurerm_network_interface.k3s_worker : nic.private_ip_address]
}

output "acr_login_server" {
  value = azurerm_container_registry.ollama.login_server
}

output "acr_admin_username" {
  value = azurerm_container_registry.ollama.admin_username
}

output "acr_admin_password" {
  value     = azurerm_container_registry.ollama.admin_password
  sensitive = true
}

output "kv_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

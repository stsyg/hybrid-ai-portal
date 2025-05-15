output "control_plane_ip" {
  value = azurerm_network_interface.k3s_cp.private_ip_address
}

output "worker_ips" {
  value = [for nic in azurerm_network_interface.k3s_worker : nic.private_ip_address]
}

output "acr_name" {
  description = "The name of the ACR instance"
  value       = azurerm_container_registry.ollama.name
}

output "acr_login_server" {
  description = "The fully qualified login server for ACR (eg. xyz.azurecr.io)"
  value       = azurerm_container_registry.ollama.login_server
}

output "acr_id" {
  description = "The resource ID of the ACR instance"
  value       = azurerm_container_registry.ollama.id
}

# output "acr_admin_username" {
#   value = azurerm_container_registry.ollama.admin_username
# }

# output "acr_admin_password" {
#   value     = azurerm_container_registry.ollama.admin_password
#   sensitive = true
# }

output "kv_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "k3s_cp_principal_id" {
  description = "The principal ID of the control‐plane VM's managed identity"
  value       = azurerm_linux_virtual_machine.k3s_cp.identity[0].principal_id
  sensitive   = true
}
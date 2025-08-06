# Terraform outputs for resource names, IPs, and credentials

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

output "kv_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "k3s_cp_principal_id" {
  description = "The principal ID of the control‐plane VM's managed identity"
  value       = azurerm_linux_virtual_machine.k3s_cp.identity[0].principal_id
  sensitive   = true
}

output "k3s_cp_cluster_name" {
  description = "The name of the Arc cluster for the control plane"
  value       = "${var.project_name}-arc-${random_integer.suffix.result}"
  # value       = azurerm_linux_virtual_machine.k3s_cp.name
}

output "k3s_resource_group" {
  description = "The resource group for the K3s deployment"
  value       = azurerm_resource_group.main.name
}

output "k3s_cp_vm_name" {
  description = "The name of the control plane VM"
  value       = azurerm_linux_virtual_machine.k3s_cp.name
}

output "k3s_lb_pip_name" {
  description = "The name of the public IP for the K3s load balancer"
  value       = azurerm_public_ip.k3s_lb.name
}

output "metallb_ip_range" {
  description = "The IP range configured for MetalLB"
  value       = var.metallb_ip_range
}

output "default_models" {
  description = "The list of default LLM models to install"
  value       = var.default_models
}
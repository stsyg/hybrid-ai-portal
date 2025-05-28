# Azure Container Registry and ACR secrets for Ollama API

resource "azurerm_container_registry" "ollama" {
  name                = "${replace(var.project_name, "-", "")}acr${random_integer.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = true

  tags = merge(var.default_tags, {
    Role = "ACR for Ollama API"
  })
}

resource "azurerm_key_vault_secret" "acr_admin_username" {
  name         = "acr-admin-username"
  value        = azurerm_container_registry.ollama.admin_username
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_container_registry.ollama,
    time_sleep.wait_for_keyvault_rbac
  ]
}

resource "azurerm_key_vault_secret" "acr_admin_password" {
  name         = "acr-admin-password"
  value        = azurerm_container_registry.ollama.admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_container_registry.ollama,
    time_sleep.wait_for_keyvault_rbac
  ]
}

// Grant your control-plane UAI the AcrPull role on the ACR
resource "azurerm_role_assignment" "acr_pull_cp" {
  scope                = azurerm_container_registry.ollama.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.k3s_cp.principal_id

  # ensure the registry exists before assigning
  depends_on = [
    azurerm_container_registry.ollama,
    azurerm_user_assigned_identity.k3s_cp,
  ]
}

// Grant workers to pull images from ACR:
resource "azurerm_role_assignment" "acr_pull_workers" {
  count                = var.worker_count > 0 ? var.worker_count : 0
  scope                = azurerm_container_registry.ollama.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_virtual_machine.k3s_worker[count.index].identity[0].principal_id

  depends_on = [
    azurerm_container_registry.ollama,
    azurerm_linux_virtual_machine.k3s_worker,
  ]
}
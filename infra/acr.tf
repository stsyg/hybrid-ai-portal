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

  depends_on = [azurerm_container_registry.ollama]
}

resource "azurerm_key_vault_secret" "acr_admin_password" {
  name         = "acr-admin-password"
  value        = azurerm_container_registry.ollama.admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_container_registry.ollama]
}
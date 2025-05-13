# Azure client metadata
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "${var.project_name}-kv-${random_integer.suffix.result}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  enable_rbac_authorization  = true

  tags = merge(var.default_tags, { Role = "SSH Key Store" })
}

# User Assigned Identity for Control Plane
resource "azurerm_user_assigned_identity" "k3s_cp" {
  name                = "${var.project_name}-identity-cp-${random_integer.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(var.default_tags, { Role = "Identity for K3s" })
}

# Allow Terraform to access Key Vault (to store/read SSH key)
resource "azurerm_role_assignment" "keyvault_access_for_tf" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Secrets Officer"
  scope                = azurerm_key_vault.main.id
}

# Allow control plane VM to read/write secrets
resource "azurerm_role_assignment" "keyvault_access_cp" {
  principal_id         = azurerm_user_assigned_identity.k3s_cp.principal_id
  role_definition_name = "Key Vault Secrets Officer"
  scope                = azurerm_key_vault.main.id
}

# Allow each worker VM to read secrets (token, etc.)
resource "azurerm_role_assignment" "keyvault_access_worker" {
  count                = var.worker_count
  principal_id         = azurerm_linux_virtual_machine.k3s_worker[count.index].identity[0].principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.main.id
}

# data "azurerm_key_vault_secret" "arc_ui_token" {
#   name         = "arc-ui-bearer-token"
#   key_vault_id = azurerm_key_vault.main.id
# }

# output "arc_ui_bearer_token" {
#   value     = data.azurerm_key_vault_secret.arc_ui_token.value
#   sensitive = true
# }

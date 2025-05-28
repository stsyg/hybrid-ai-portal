# Azure Bastion host and related resources for secure VM access

resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion && var.bastion_sku != "Developer" ? 1 : 0
  name                = "${var.project_name}-bastion-ip-${random_integer.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "bastion" {
  count                = var.enable_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/27"] # ensure it doesn't overlap
}

resource "azurerm_bastion_host" "main" {
  count               = var.enable_bastion ? 1 : 0
  name                = "${var.project_name}-bastion-${random_integer.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.bastion_sku # "Developer", "Standard", etc.
  tags                = merge(var.default_tags, { Role = "Bastion Host" })

  # Developer SKU requires virtual_network_id instead of ip_configuration
  virtual_network_id = var.bastion_sku == "Developer" ? azurerm_virtual_network.main.id : null

  # All other SKUs require ip_configuration
  dynamic "ip_configuration" {
    for_each = var.bastion_sku != "Developer" ? [1] : []
    content {
      name                 = "configuration"
      subnet_id            = azurerm_subnet.bastion[0].id
      public_ip_address_id = azurerm_public_ip.bastion[0].id
    }
  }

  depends_on = [
    azurerm_virtual_network.main
  ]

}
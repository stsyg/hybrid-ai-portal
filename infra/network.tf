# VNet, Subnet, NSG, and Associations
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet-${random_integer.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = merge(var.default_tags, { Role = "K3s Network" })
}

resource "azurerm_subnet" "main" {
  name                 = "${var.project_name}-subnet-${random_integer.suffix.result}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [azurerm_virtual_network.main]
}

resource "azurerm_network_security_group" "k3s" {
  name                = "${var.project_name}-nsg-${random_integer.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowInternalSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    source_port_range          = "*"
  }

  tags = merge(var.default_tags, { Role = "K3s Network NSG" })
}

resource "azurerm_network_interface_security_group_association" "k3s_cp" {
  network_interface_id      = azurerm_network_interface.k3s_cp.id
  network_security_group_id = azurerm_network_security_group.k3s.id
}

resource "azurerm_network_interface_security_group_association" "k3s_worker" {
  count                     = var.worker_count
  network_interface_id      = azurerm_network_interface.k3s_worker[count.index].id
  network_security_group_id = azurerm_network_security_group.k3s.id
}
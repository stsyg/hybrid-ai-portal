# Virtual Network, Subnet, and NSG for K3s cluster

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

resource "azurerm_subnet_network_security_group_association" "k3s_subnet" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.k3s.id
  depends_on = [
    azurerm_linux_virtual_machine.k3s_cp,
    azurerm_network_interface.k3s_cp,
    azurerm_linux_virtual_machine.k3s_worker,
    azurerm_network_interface.k3s_worker
  ]
}

resource "azurerm_network_security_group" "k3s" {
  name                = "${var.project_name}-nsg-${random_integer.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  # security_rule {
  #   name                       = "AllowInternalSSH"
  #   priority                   = 100
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_address_prefix      = "10.0.0.0/16"
  #   destination_address_prefix = "*"
  #   destination_port_range     = "22"
  #   source_port_range          = "*"
  # }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "80"
    source_port_range          = "*"
  }


  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    source_port_range          = "*"
  }

  security_rule {
    name                       = "AllowNodePorts"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "30000-32767"
    source_port_range          = "*"
  }

  # security_rule {
  #   name                       = "AllowSSH"
  #   priority                   = 500
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  #   destination_port_range     = "22"
  #   source_port_range          = "*"
  # }

  tags = merge(var.default_tags, { Role = "K3s Network NSG" })
}

# -----------------------------
# Load Balancer Public IP
# -----------------------------
resource "azurerm_public_ip" "k3s_lb" {
  name                = "${var.project_name}-k3s-cp-ip-${random_integer.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.default_tags, { Role = "K3s-Control-Plane-PublicIP" })
}
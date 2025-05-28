# Azure Load Balancer and NAT rule for K3s Traefik HTTP
resource "azurerm_lb" "k3s_public" {
  name                = "${var.project_name}-k3s-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.k3s_cp.id
  }
}

resource "azurerm_lb_backend_address_pool" "k3s_backend" {
  name            = "BackendPool"
  loadbalancer_id = azurerm_lb.k3s_public.id
}

resource "azurerm_lb_probe" "k3s_http" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.k3s_public.id
  protocol        = "Tcp"
  port            = 30090
}

resource "azurerm_lb_rule" "k3s_http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.k3s_public.id
  protocol                      = "Tcp"
  frontend_port                  = 80
  backend_port                   = 30090
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.k3s_backend.id]
  probe_id                       = azurerm_lb_probe.k3s_http.id
}

resource "azurerm_network_interface_backend_address_pool_association" "k3s_cp" {
  network_interface_id    = azurerm_network_interface.k3s_cp.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.k3s_backend.id
}

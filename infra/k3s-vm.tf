# K3s VM, NIC, and Arc onboarding for control plane and workers

# Pull public key from Key Vault
data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = azurerm_key_vault_secret.ssh_public_key.name
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_secret.ssh_public_key]
}

# Assign role to managed identity to unboard the VM

resource "azurerm_role_assignment" "arc_onboarding_cp" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Kubernetes Cluster - Azure Arc Onboarding"
  principal_id         = azurerm_user_assigned_identity.k3s_cp.principal_id

}

# -----------------------------
# Control Plane NIC
# -----------------------------
resource "azurerm_network_interface" "k3s_cp" {
  name                = "${var.project_name}-k3s-cp-${random_integer.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id removed for Azure LB usage
  }

  tags = merge(var.default_tags, { Role = "K3s-Control-Plane" })
}

# -----------------------------
# Control Plane VM
# -----------------------------
resource "azurerm_linux_virtual_machine" "k3s_cp" {
  name                            = "${var.project_name}-k3s-cp-${random_integer.suffix.result}"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.k3s_cp.id]

  custom_data = base64encode(templatefile("${path.module}/cloud-init-controlplane.tpl", {
    kv_name          = azurerm_key_vault.main.name,
    admin_username   = var.admin_username
    arc_cluster_name = "${var.project_name}-arc-${random_integer.suffix.result}",
    arc_cluster_rg   = azurerm_resource_group.main.name,
    arc_location     = var.location,
    subscription_id  = data.azurerm_client_config.current.subscription_id,
    acr_name         = azurerm_container_registry.ollama.name
  }))

  admin_ssh_key {
    username   = var.admin_username
    public_key = data.azurerm_key_vault_secret.ssh_public_key.value
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.k3s_cp.id]
  }

  tags = merge(var.default_tags, { Role = "K3s-Control-Plane" })

  depends_on = [
    azurerm_key_vault_secret.ssh_public_key,
    azurerm_role_assignment.keyvault_access_cp,
    azurerm_role_assignment.arc_onboarding_cp
  ]

  lifecycle {
    ignore_changes = [
      # Don’t force a rebuild when your cloud-init (custom_data) changes
      # custom_data,

      # Ignore these provider-driven defaults too
      patch_assessment_mode,
      patch_mode,
      bypass_platform_safety_checks_on_user_schedule_enabled,
    ]
  }
}

# -----------------------------
# Worker NICs (only created if count > 0)
# -----------------------------
resource "azurerm_network_interface" "k3s_worker" {
  count               = var.worker_count > 0 ? var.worker_count : 0
  name                = "${var.project_name}-k3s-wk-${random_integer.suffix.result}-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.default_tags, { Role = "K3s-Worker" })
}

# -----------------------------
# Worker VMs (only created if count > 0)
# -----------------------------
resource "azurerm_linux_virtual_machine" "k3s_worker" {
  count                           = var.worker_count > 0 ? var.worker_count : 0
  name                            = "${var.project_name}-k3s-wk-${random_integer.suffix.result}-${count.index}"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.k3s_worker[count.index].id]

  custom_data = base64encode(templatefile("${path.module}/cloud-init-worker.tpl", {
    kv_name = azurerm_key_vault.main.name,
    cp_ip   = azurerm_linux_virtual_machine.k3s_cp.private_ip_address
  }))


  admin_ssh_key {
    username   = var.admin_username
    public_key = data.azurerm_key_vault_secret.ssh_public_key.value
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.default_tags, { Role = "K3s-Worker" })
}

# SSH key generation and storage in Azure Key Vault

# Generate SSH key pair locally
resource "null_resource" "generate_ssh_key" {
  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ~/.ssh
      ssh-keygen -t rsa -b 2048 -f ~/.ssh/k3s-rsa-${random_integer.suffix.result} -q -N ""
    EOT
  }

  triggers = {
    key_name = "k3s-rsa-${random_integer.suffix.result}"
  }
}

# Load the public key file after it has been generated
data "local_file" "ssh_pub_key" {
  filename   = pathexpand("~/.ssh/k3s-rsa-${random_integer.suffix.result}.pub")
  depends_on = [null_resource.generate_ssh_key]
}

# Load the private key file after it has been generated
data "local_file" "ssh_private_key" {
  filename   = pathexpand("~/.ssh/k3s-rsa-${random_integer.suffix.result}")
  depends_on = [null_resource.generate_ssh_key]
}

# Store the public key in Azure Key Vault
resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "ssh-public-key"
  value        = data.local_file.ssh_pub_key.content
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault.main,
    time_sleep.wait_for_keyvault_rbac,
    null_resource.generate_ssh_key
  ]
}

# Store the private key in Azure Key Vault
resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "ssh-private-key"
  value        = data.local_file.ssh_private_key.content
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault.main,
    time_sleep.wait_for_keyvault_rbac,
    null_resource.generate_ssh_key
  ]
}

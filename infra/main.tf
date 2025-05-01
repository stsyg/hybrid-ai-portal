// Terraform main file
provider "azurerm" {
  features {}
}

resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Outputs (for debugging/demo)
output "suffix" {
  value = random_integer.suffix.result
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}

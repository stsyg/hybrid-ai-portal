# Main entry for resource group and random suffix for resource uniqueness
# This resource group is used to contain all the resources for the Hybrid AI Portal
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg-${random_integer.suffix.result}"
  location = var.location

  tags = var.default_tags
}

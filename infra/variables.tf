variable "project_name" {
  default = "js-haip"
}

variable "location" {
  default = "canadacentral"
}

variable "vm_size" {
  default = "Standard_B2s"
}

variable "admin_username" {
  default = "azureuser"
}

variable "worker_count" {
  type    = number
  default = 1
}

variable "default_tags" {
  type = map(string)
  default = {
    provisioner = "Terraform"
    environment = "Demo"
    designation = "Jumpstart Drops: Hybrid AI Portal"
  }
}

variable "kv_name" {
  description = "Name of the Azure Key Vault"
  default     = "js-haip-kv"
}

variable "enable_bastion" {
  description = "Enable Azure Bastion host"
  type        = bool
  default     = true
}

variable "bastion_sku" {
  description = "Bastion SKU. Valid: Developer, Basic, Standard, Premium"
  type        = string
  default     = "Basic"
}
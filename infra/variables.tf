variable "project_name" {
  description = "Base project name used for all resources"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "vm_size" {
  description = "VM size for all K3s nodes"
  type        = string
}

variable "admin_username" {
  description = "Default admin username for VMs"
  type        = string
}

variable "worker_count" {
  description = "Number of K3s worker nodes"
  type        = number
}

variable "default_tags" {
  type = map(string)
  default = {
    provisioner = "Terraform"
    environment = "Demo"
    designation = "Jumpstart Drops: Hybrid AI Portal"
  }
}

# variable "kv_name" {
#   description = "Name of the Azure Key Vault"
#   type        = string
# }

variable "enable_bastion" {
  description = "Enable Azure Bastion host"
  type        = bool
}

variable "bastion_sku" {
  description = "Bastion SKU. Valid: Developer, Basic, Standard, Premium"
  type        = string
}

# variable "arc_cluster_name" {
#   description = "Name of Azure Arc-enabled Kubernetes cluster"
#   type        = string
# }

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
}
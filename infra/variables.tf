# Input variables for project configuration

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

variable "enable_bastion" {
  description = "Enable Azure Bastion host"
  type        = bool
}

variable "bastion_sku" {
  description = "Bastion SKU. Valid: Developer, Basic, Standard, Premium"
  type        = string
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
}

# VM and Storage Configuration
variable "vm_disk_size_gb" {
  description = "OS disk size in GB for K3s VMs"
  type        = number
  default     = 64
}

variable "vm_disk_type" {
  description = "Storage type for VM OS disks (Standard_LRS, Premium_LRS, StandardSSD_LRS)"
  type        = string
  default     = "Premium_LRS"
}

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for subnets"
  type = object({
    k3s_subnet     = string
    bastion_subnet = string
  })
  default = {
    k3s_subnet     = "10.0.1.0/24"
    bastion_subnet = "10.0.2.0/24"
  }
}

variable "metallb_ip_range" {
  description = "IP range for MetalLB load balancer (should be within k3s_subnet)"
  type        = string
  default     = "10.0.1.100-10.0.1.110"
}

# Load Balancer Configuration
variable "lb_sku" {
  description = "SKU for Azure Load Balancer (Basic or Standard)"
  type        = string
  default     = "Standard"
}

variable "public_ip_sku" {
  description = "SKU for public IP addresses (Basic or Standard)"
  type        = string
  default     = "Standard"
}

# Key Vault Configuration
variable "kv_sku_name" {
  description = "SKU name for Azure Key Vault (standard or premium)"
  type        = string
  default     = "standard"
}

variable "kv_soft_delete_retention_days" {
  description = "Soft delete retention period in days for Key Vault"
  type        = number
  default     = 7
}

# Security Configuration
variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidrs" {
  description = "List of CIDR blocks allowed for HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Model Configuration
variable "default_models" {
  description = "List of LLM models to install by default"
  type        = list(string)
  default     = ["llama3.2:1b"]
}

variable "enable_gpu_support" {
  description = "Enable GPU support for model inference (requires GPU-capable VM sizes)"
  type        = bool
  default     = false
}
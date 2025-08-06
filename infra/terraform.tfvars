project_name   = "js-haip"
location       = "canadacentral"
vm_size        = "Standard_D4s_v3"
admin_username = "azureuser"
worker_count   = 1
enable_bastion = true
bastion_sku    = "Basic"
acr_sku        = "Basic"

# VM and Storage Configuration
vm_disk_size_gb = 64
vm_disk_type    = "Premium_LRS"

# Network Configuration
vnet_address_space = ["10.0.0.0/16"]
subnet_address_prefixes = {
  k3s_subnet     = "10.0.1.0/24"
  bastion_subnet = "10.0.2.0/24"
}
metallb_ip_range = "10.0.1.100-10.0.1.110"

# Load Balancer Configuration
lb_sku        = "Standard"
public_ip_sku = "Standard"

# Key Vault Configuration
kv_sku_name                   = "standard"
kv_soft_delete_retention_days = 7

# Security Configuration
allowed_ssh_cidrs  = ["0.0.0.0/0"]
allowed_http_cidrs = ["0.0.0.0/0"]

# Model Configuration
default_models = [
  "llama3.2:1b",
  "llama3.2:3b"
]
enable_gpu_support = false
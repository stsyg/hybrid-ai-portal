# Hybrid AI Portal (HAIP)

A fully automated, cloud-native LLM web portal powered by Ollama and a web chat UI, deployed on an Azure Arc-enabled K3s cluster.

---

## 📦 Prerequisites

To run the deployment scripts, you need:
- **WSL or Linux** (for Bash script execution)
- **Docker Engine** (or Docker Desktop) to build Ollama API and chat images
- **VS Code** (recommended, but any IDE is fine)
- **Azure Subscription** (all resources will be deployed here)
- **kubectl** (optional, to check K8s resources from your laptop after deployment)
- **Web browser** (e.g., Chrome) to interact with the Ollama chat UI
- **Azure CLI** (authenticate using device code: `az login --use-device-code` is the simplest)
- **Terraform**
- **Git**

---

## 🚀 Quick Start

1. **Clone the repository and move to the project folder:**
   ```bash
   git clone <your-repo-url>
   cd hybrid-ai-portal
   ```
2. **Authenticate with Azure:**
   ```bash
   az login --use-device-code
   ```
3. **Deploy everything (infra + app):**
   ```bash
   ./deploy-ollama.sh all
   ```
   - Provide subscription id where resources will be deployed.
   - End-to-end deployment may take up to 30 minutes, depending on your internet connectivity (Docker images are built and pushed to ACR).

4. **Destroy everything:**
   ```bash
   ./deploy-ollama.sh destroy
   ```

---

## 🏗️ Architecture Overview

- **Default deployment:**
  - Azure VMs: K3s control plane + workers (optional)
  - Multiple Ollama models can be deployed (configurable via terraform.tfvars)
  - Azure Bastion for SSH access to the VM
  - SSH keys stored in Azure Key Vault
  - K3s managed via Azure Arc (bearer token stored in Key Vault)
- **Components:**
  - **K3s Cluster** on Azure VMs (Arc-enabled)
  - **MetalLB** for LoadBalancer IPs
  - **Traefik** as Ingress Controller
  - **Ollama API** and **Web Chat** as Kubernetes Deployments
  - **Azure Container Registry (ACR)** for Docker images
  - **Azure Key Vault** for all the secrets
  - **Azure Bastion** for secure SSH to k3s VMs

Example of Ollama Chart interface (http://<public_ip>/chat).
![Ollama Chat UI](assets/ollama-chat.png)

Example of Ollama API (http://<public_ip>/ollama/api/tags)
![Ollama Chat API](assets/ollama-api.png)

Example of deployed Azure resources in the resource group.
![Azure Resource Group](assets/azure-rg.png)

---

## ⚙️ Deployment Workflow

- **All infrastructure** is deployed via Terraform. Azure resources parameters can be updated in `terraform.tfvars`
- **K3s** is installed and configured via shell scripts
- **Docker images** for Ollama API and chat are built and pushed to ACR
- **Kubernetes manifests** (YAML) are applied via `kubectl`
- **Ollama API** is accessed via `/api/tags`
- **Web chat** is accessed via `/chat` route

## 🔧 Configuration Options

The deployment can be customized by modifying the `infra/terraform.tfvars` file. Below are all available configuration options:

### Basic Configuration
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `project_name` | Base project name used for all resources | `"js-haip"` | `"my-ai-portal"` |
| `location` | Azure region for all resources | `"canadacentral"` | `"eastus"` |
| `admin_username` | Default admin username for VMs | `"azureuser"` | `"admin"` |
| `worker_count` | Number of K3s worker nodes | `1` | `2` |

### VM and Storage Configuration
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `vm_size` | VM size for all K3s nodes | `"Standard_D4s_v3"` | `"Standard_D8s_v3"` |
| `vm_disk_size_gb` | OS disk size in GB for K3s VMs | `64` | `128` |
| `vm_disk_type` | Storage type for VM OS disks | `"Premium_LRS"` | `"Standard_LRS"` |
| `enable_gpu_support` | Enable GPU support for model inference | `false` | `true` |

### Network Configuration
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `vnet_address_space` | Address space for the virtual network | `["10.0.0.0/16"]` | `["172.16.0.0/16"]` |
| `subnet_address_prefixes` | Address prefixes for subnets | See example below | See example below |
| `metallb_ip_range` | IP range for MetalLB load balancer | `"10.0.1.100-10.0.1.110"` | `"172.16.1.50-172.16.1.60"` |

**Subnet Configuration Example:**
```hcl
subnet_address_prefixes = {
  k3s_subnet     = "10.0.1.0/24"
  bastion_subnet = "10.0.2.0/24"
}
```

### Load Balancer Configuration
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `lb_sku` | SKU for Azure Load Balancer | `"Standard"` | `"Basic"` |
| `public_ip_sku` | SKU for public IP addresses | `"Standard"` | `"Basic"` |

### Bastion Configuration
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `enable_bastion` | Enable Azure Bastion host | `true` | `false` |
| `bastion_sku` | Bastion SKU | `"Basic"` | `"Standard"` |

### Azure Container Registry Configuration
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `acr_sku` | SKU for Azure Container Registry | `"Basic"` | `"Premium"` |

### Key Vault Configuration
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `kv_sku_name` | SKU name for Azure Key Vault | `"standard"` | `"premium"` |
| `kv_soft_delete_retention_days` | Soft delete retention period in days | `7` | `30` |

### Security Configuration
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `allowed_ssh_cidrs` | List of CIDR blocks allowed for SSH access | `["0.0.0.0/0"]` | `["192.168.1.0/24"]` |
| `allowed_http_cidrs` | List of CIDR blocks allowed for HTTP access | `["0.0.0.0/0"]` | `["0.0.0.0/0"]` |

### Model Configuration
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `default_models` | List of LLM models to install by default | `["llama3.2:1b", "llama3.2:3b"]` | `["llama3.1:8b", "codellama:7b"]` |

### Example terraform.tfvars

```hcl
project_name   = "my-ai-portal"
location       = "eastus"
vm_size        = "Standard_D8s_v3"
admin_username = "azureuser"
worker_count   = 2

# VM and Storage Configuration
vm_disk_size_gb = 128
vm_disk_type    = "Premium_LRS"

# Network Configuration
vnet_address_space = ["172.16.0.0/16"]
subnet_address_prefixes = {
  k3s_subnet     = "172.16.1.0/24"
  bastion_subnet = "172.16.2.0/24"
}
metallb_ip_range = "172.16.1.100-172.16.1.110"

# Load Balancer Configuration
lb_sku        = "Standard"
public_ip_sku = "Standard"

# Bastion Configuration
enable_bastion = true
bastion_sku    = "Standard"

# Container Registry
acr_sku = "Premium"

# Key Vault Configuration
kv_sku_name                   = "premium"
kv_soft_delete_retention_days = 30

# Security Configuration
allowed_ssh_cidrs  = ["192.168.1.0/24", "10.0.0.0/8"]
allowed_http_cidrs = ["0.0.0.0/0"]

# Model Configuration
default_models = [
  "llama3.1:8b",
  "codellama:7b",
  "mistral:7b"
]
enable_gpu_support = true
```

### Pre-configured Examples

The repository includes example configurations for different use cases in `infra/terraform.tfvars.example`:

- **Basic Configuration**: Minimal setup for development and testing
- **Production Configuration**: High-performance setup with multiple models  
- **Development Configuration**: Cost-optimized setup for development
- **Enterprise Configuration**: Maximum security and performance setup

Copy the relevant section from the example file to your `terraform.tfvars` and modify as needed:

```bash
# Copy example configurations
cp infra/terraform.tfvars.example infra/my-config.tfvars
# Edit and use your configuration  
mv infra/my-config.tfvars infra/terraform.tfvars
```

---

## 🌐 Accessing the Portal

- **Traefik LoadBalancer IP**: Assigned by MetalLB (see deployment output)
- **Ingress Routes**:
  - `/ollama` → Ollama API
  - `/chat`   → Web Chat UI
- **No static IPs in docs**: Use the IPs output by the script, or add to `/etc/hosts` as needed.

---

## 🛡️ Robustness & Automation

- All resource names, ports, and manifests are dynamically updated
- MetalLB and Traefik are installed and patched with readiness checks
- Key Vault and Arc proxy waits are robust
- Destroy/apply sequencing is dependency-safe (see Terraform `depends_on`)

---

## 📝 Management

### Kubernetes Resources
- View pod/service/ingress status:
  ```bash
  kubectl get pods,svc,ingress -A
  ```
- View logs:
  ```bash
  kubectl logs -f deployment/ollama-api
  kubectl logs -f deployment/ollama-chat
  ```
- Scale deployments:
  ```bash
  kubectl scale deployment ollama-chat --replicas=3
  ```

### Model Management
- Install additional models:
  ```bash
  ./scripts/install-model.sh llama3.1:8b
  ```
- Install multiple models:
  ```bash
  ./scripts/install-models.sh llama3.1:8b codellama:7b mistral:7b
  ```
- List installed models:
  ```bash
  kubectl exec -it deployment/ollama-api -- ollama list
  ```
- Remove a model:
  ```bash
  kubectl exec -it deployment/ollama-api -- ollama rm model-name
  ```
- Test models via API:
  ```bash
  # List all models
  curl http://<public_ip>/ollama/api/tags
  
  # Test a specific model
  curl -X POST http://<public_ip>/ollama/api/generate \
    -H 'Content-Type: application/json' \
    -d '{"model": "llama3.1:8b", "prompt": "Hello, world!", "stream": false}'
  ```

---

## ❓ Frequently Asked Questions

### How do I add more models after deployment?
You can install additional models using the provided scripts:
```bash
# Install a single model
./scripts/install-model.sh llama3.1:8b

# Install multiple models
./scripts/install-models.sh llama3.1:8b codellama:7b mistral:7b
```

### How do I change the VM size after deployment?
Modify the `vm_size` in `terraform.tfvars` and run:
```bash
cd infra
terraform apply
```

### How do I restrict access to specific IP addresses?
Update the security configuration in `terraform.tfvars`:
```hcl
allowed_ssh_cidrs  = ["YOUR_IP/32"]
allowed_http_cidrs = ["YOUR_NETWORK/24"]
```

### How do I enable GPU support?
1. Change to a GPU-capable VM size (e.g., `Standard_NC6s_v3`)
2. Set `enable_gpu_support = true` in `terraform.tfvars`
3. Deploy with `./deploy-ollama.sh all`

### How do I deploy to a different Azure region?
Change the `location` variable in `terraform.tfvars` to any supported Azure region:
```hcl
location = "westus2"
```

### How do I reduce costs?
1. Use smaller VM sizes (e.g., `Standard_B2s`)
2. Set `worker_count = 0` for single-node deployment
3. Use `Standard_LRS` disk type instead of `Premium_LRS`
4. Use `Basic` SKUs for load balancer and public IPs
5. Choose lightweight models like `llama3.2:1b`

### How do I increase security?
1. Restrict CIDR blocks in security configuration
2. Use `Premium` Key Vault SKU for HSM support
3. Enable Bastion with `Standard` or `Premium` SKU
4. Use private networks with appropriate firewall rules

### How do I troubleshoot deployment issues?
1. Check Terraform logs: `terraform apply` will show detailed error messages
2. Check Kubernetes pod status: `kubectl get pods -A`
3. Check pod logs: `kubectl logs -f deployment/ollama-api`
4. Check Arc connectivity: `az connectedk8s show -n <cluster-name> -g <resource-group>`
5. Check model installation: `kubectl exec -it deployment/ollama-api -- ollama list`

### How do I monitor resource usage?
```bash
# Check node resource usage
kubectl top nodes

# Check pod resource usage
kubectl top pods

# Check persistent volumes
kubectl get pv,pvc

# Check service status
kubectl get svc -A
```

### What models are supported?
The deployment supports any model available on [Ollama's model library](https://ollama.com/search). Popular options include:
- **General Purpose**: `llama3.1:8b`, `llama3.2:3b`, `mistral:7b`
- **Code Generation**: `codellama:7b`, `codellama:13b`, `starcoder:7b`
- **Specialized**: `llava:7b` (vision), `dolphin-mistral:7b` (uncensored)
- **Lightweight**: `llama3.2:1b`, `tinyllama:1.1b` (for testing)

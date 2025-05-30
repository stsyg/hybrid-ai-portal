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
   - End-to-end deployment may take up to 30 minutes, depending on your internet connectivity (Docker images are built and pushed to ACR).

4. **Destroy everything:**
   ```bash
   ./deploy-ollama.sh destroy
   ```

---

## 🏗️ Architecture Overview

- **Default deployment:**
  - One Azure VM (K3s control plane)
  - Llama3.2:1b Ollama model deployed by default
  - Azure Bastion for SSH access to the VM
  - SSH keys stored in Azure Key Vault
  - K3s managed via Azure Arc (bearer token stored in Key Vault)
- **Components:**
  - **K3s Cluster** on Azure VMs (Arc-enabled)
  - **MetalLB** for LoadBalancer IPs
  - **Traefik** as Ingress Controller (patched to LoadBalancer)
  - **Ollama API** and **Web Chat** as Kubernetes Deployments
  - **Azure Container Registry (ACR)** for images
  - **Azure Key Vault** for secrets
  - **Azure Bastion** for secure SSH

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  Web Client  │─▶│   Traefik    │─▶│  Ollama API  │
│  (Chat UI)   │   │ (LB+Ingress)│   │  + Web Chat  │
└──────────────┘   └──────────────┘   └──────────────┘
         │                │
         ▼                ▼
   MetalLB IP        Azure ACR
         │                │
         ▼                ▼
   Azure Bastion     Key Vault (SSH keys, Arc token)
         │
         ▼
   Azure Arc (K3s mgmt)
```

![Ollama Chat Screenshot](attachments/ollama-chat.png)

![Azure Resource Group Screenshot](attachments/azure-rg.png)

---

## ⚙️ Deployment Workflow

- **All infrastructure** is deployed via Terraform
- **K3s** is installed via shell scripts
- **Docker images** for Ollama API and chat are built and pushed to ACR
- **Kubernetes manifests** (YAML) are applied via `kubectl`
- **Ollama API** is accessed via `/api/tags` (see OLLAMA.md for more)
- **Web chat** is accessed via `/chat` route

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

---

## 📚 See also
- [OLLAMA.md](./OLLAMA.md) for detailed Ollama API usage and chat features
- [scripts/](./scripts/) for automation details

---

*This README reflects the latest robust, cloud-native, and automated deployment process. For troubleshooting, see the script outputs and comments in OLLAMA.md.*

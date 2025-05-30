# Hybrid AI Portal (HAIP)

A fully automated, cloud-native LLM web portal powered by Ollama and a web chat UI, deployed on an Azure Arc-enabled K3s cluster.

---

## 🚀 Quick Start

```bash
# Deploy all infrastructure and apps
./deploy-ollama.sh all

# Or deploy infra and app separately
./deploy-ollama.sh infra
./deploy-ollama.sh ollama

# Destroy everything
./deploy-ollama.sh destroy
```

---

## 🏗️ Architecture Overview

- **K3s Cluster** on Azure VMs (Arc-enabled)
- **MetalLB** for LoadBalancer IPs
- **Traefik** as Ingress Controller (patched to LoadBalancer)
- **Ollama API** and **Web Chat** as Kubernetes Deployments
- **Azure Container Registry (ACR)** for images
- **Azure Key Vault** for secrets

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  Web Client  │─▶│   Traefik    │─▶│  Ollama API  │
│  (Chat UI)   │   │ (LB+Ingress)│   │  + Web Chat  │
└──────────────┘   └──────────────┘   └──────────────┘
         │                │
         ▼                ▼
   MetalLB IP        Azure ACR
```

---

## 📦 Prerequisites

- Azure CLI, Terraform, Docker, kubectl
- Azure subscription with permissions

---

## ⚙️ Deployment Flow

1. **Provision Azure Resources** (VMs, NSG, LB, Key Vault, ACR, etc.)
2. **Install K3s, MetalLB, Traefik** (with robust patching and waits)
3. **Build & Push Images** to ACR
4. **Update K8s Manifests** with dynamic ACR image names
5. **Deploy Ollama API & Chat** via Kubernetes manifests
6. **Wait for Readiness** (Key Vault secret, Arc proxy, K8s deployments)
7. **Access via MetalLB IP** (Traefik LB, Ingress routes)

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

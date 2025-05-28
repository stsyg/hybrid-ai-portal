# Ollama API on K3s Cluster

This guide covers the complete deployment and usage of Ollama API on a K3s cluster in Azure, including a web chat interface.

## 🚀 Quick Start

### Deploy Everything
```bash
# Deploy Ollama API to K3s cluster
./deploy-ollama.sh

# Test the deployment
./scripts/test-ollama.sh
```

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Deployment](#deployment)
- [Managing Models](#managing-models)
- [Testing & Monitoring](#testing--monitoring)
- [Web Chat Interface](#web-chat-interface)
- [API Usage](#api-usage)
- [Troubleshooting](#troubleshooting)
- [Scaling & Performance](#scaling--performance)

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Web Browser   │    │   Traefik LB     │    │   Ollama Pod    │
│                 │───▶│   (10.0.1.4)     │───▶│   (Port 11434)  │
│ Chat Interface  │    │   Port 80/443    │    │   Llama Model   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   Azure ACR      │
                       │   Image Registry │
                       └──────────────────┘
```

### Components
- **Ollama Pod**: Runs the Ollama API server with AI models
- **Web Chat**: Simple HTML/JS interface for chatting with AI
- **Traefik Ingress**: Routes external traffic to services
- **Azure ACR**: Stores Docker images
- **Azure Key Vault**: Stores ACR credentials

## 📦 Prerequisites

1. **Azure Resources** (created via Terraform):
   - K3s cluster running on Azure VM
   - Azure Container Registry (ACR)
   - Azure Key Vault
   - Virtual Network with proper security groups

2. **Local Tools**:
   - `kubectl` configured for your K3s cluster
   - `docker` for building images
   - `az` CLI for Azure operations

3. **Access**:
   - SSH access to K3s cluster
   - ACR push/pull permissions
   - Key Vault read permissions

## 🚀 Deployment

### Automated Deployment

The complete deployment is automated with a single script:

```bash
./deploy-ollama.sh
```

This script performs:
1. ✅ Updates Kubernetes manifests with correct ACR image
2. ✅ Builds and pushes Docker image to ACR
3. ✅ Sets up ACR pull secrets in K3s
4. ✅ Deploys Ollama API to Kubernetes
5. ✅ Waits for deployment to be ready
6. ✅ Deploys web chat interface
7. ✅ Shows access information

### Manual Deployment Steps

If you need to deploy manually:

```bash
# 1. Update manifests
./scripts/update-k8s-manifests.sh

# 2. Build and push image
./scripts/build-and-push.sh

# 3. Setup ACR secret
./scripts/setup-acr-secret.sh

# 4. Deploy to K3s
kubectl apply -f ollama-api/k8s/

# 5. Deploy chat interface
./scripts/deploy-chat.sh

# 6. Wait for ready
kubectl wait --for=condition=available --timeout=300s deployment/ollama-api
kubectl wait --for=condition=available --timeout=300s deployment/ollama-chat
```

### Verification

Check deployment status:
```bash
# Check pod status
kubectl get pods -l app=ollama-api
kubectl get pods -l app=ollama-chat

# Check service and ingress
kubectl get svc,ingress

# View logs
kubectl logs -f deployment/ollama-api
kubectl logs -f deployment/ollama-chat
```

## 🤖 Managing Models

### Install Models

```bash
# Install a small model (recommended for testing)
kubectl exec -it deployment/ollama-api -- ollama pull llama3.2:1b

# Install larger models
kubectl exec -it deployment/ollama-api -- ollama pull llama3.2:3b
kubectl exec -it deployment/ollama-api -- ollama pull codellama:7b
kubectl exec -it deployment/ollama-api -- ollama pull mistral:7b
```

### List Available Models

```bash
# Via kubectl
kubectl exec -it deployment/ollama-api -- ollama list

# Via API
curl http://ollama.local/api/tags
```

### Remove Models

```bash
kubectl exec -it deployment/ollama-api -- ollama rm llama3.2:1b
```

### Model Information

| Model | Size | Use Case | Memory Required |
|-------|------|----------|----------------|
| `llama3.2:1b` | 1.3GB | Quick responses, testing | 2GB RAM |
| `llama3.2:3b` | 2.0GB | Balanced performance | 4GB RAM |
| `codellama:7b` | 3.8GB | Code generation | 8GB RAM |
| `mistral:7b` | 4.1GB | Advanced reasoning | 8GB RAM |

## 🧪 Testing & Monitoring

### Automated Testing

```bash
# Run comprehensive tests
./scripts/test-ollama.sh
```

### Manual API Testing

```bash
# Test health endpoint
curl http://ollama.local/api/tags

# Test text generation
curl -X POST http://ollama.local/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:1b",
    "prompt": "Explain quantum computing in simple terms",
    "stream": false
  }'

# Test with streaming (real-time responses)
curl -X POST http://ollama.local/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:1b",
    "prompt": "Write a story about AI",
    "stream": true
  }'
```

### Monitoring

```bash
# Watch pod status
kubectl get pods -l app=ollama-api -w

# Monitor resource usage
kubectl top pods -l app=ollama-api

# View detailed pod info
kubectl describe pod -l app=ollama-api

# Check ingress status
kubectl get ingress ollama-api -o yaml
```

## 💬 Web Chat Interface

A simple web-based chat interface is included for easy interaction with the AI models.

### Access the Chat Interface
- **URL**: `http://ollama.local/chat` or `http://10.0.1.4/chat`
- **Features**:
  - Real-time chat with AI models
  - Model selection dropdown
  - Conversation history
  - Responsive design
  - Markdown rendering for code blocks

### Deploy Chat Interface
```bash
# Deploy the web chat interface
kubectl apply -f ollama-api/k8s/chat-app.yaml
```

## 🔌 API Usage

### Base URL
- **Internal**: `http://ollama-api.default.svc.cluster.local`
- **External**: `http://ollama.local` or `http://10.0.1.4/ollama`

### Endpoints

#### List Models
```bash
GET /api/tags
```

#### Generate Text
```bash
POST /api/generate
Content-Type: application/json

{
  "model": "llama3.2:1b",
  "prompt": "Your question here",
  "stream": false
}
```

#### Chat Completion
```bash
POST /api/chat
Content-Type: application/json

{
  "model": "llama3.2:1b",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ]
}
```

### Response Format

```json
{
  "model": "llama3.2:1b",
  "created_at": "2025-05-27T05:03:52.533471021Z",
  "response": "Hello! How can I help you today?",
  "done": true,
  "total_duration": 3259310554,
  "load_duration": 33010154,
  "prompt_eval_count": 31,
  "eval_count": 23
}
```

## 🔧 Troubleshooting

### Common Issues

#### Pod Not Starting
```bash
# Check pod status
kubectl describe pod -l app=ollama-api

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check ACR pull secret
kubectl get secret acr-pull-secret -o yaml
```

#### Model Loading Issues
```bash
# Check available storage
kubectl exec -it deployment/ollama-api -- df -h

# Check ollama process
kubectl exec -it deployment/ollama-api -- ps aux | grep ollama

# Restart deployment
kubectl rollout restart deployment/ollama-api
```

#### API Not Responding
```bash
# Test internal connectivity
kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -- \
  curl -v http://ollama-api.default.svc.cluster.local/api/tags

# Check service endpoints
kubectl get endpoints ollama-api

# Check ingress configuration
kubectl describe ingress ollama-api
```

#### Out of Memory
```bash
# Check resource usage
kubectl top pods -l app=ollama-api

# Increase memory limits in deployment.yaml
kubectl edit deployment ollama-api
```

### Log Analysis

```bash
# View recent logs
kubectl logs -f deployment/ollama-api --tail=100

# Save logs to file
kubectl logs deployment/ollama-api > ollama-logs.txt

# Check for specific errors
kubectl logs deployment/ollama-api | grep -i error
```

## 📈 Scaling & Performance

### Horizontal Scaling
```bash
# Scale to multiple replicas
kubectl scale deployment ollama-api --replicas=3

# Auto-scaling (if HPA is configured)
kubectl autoscale deployment ollama-api --cpu-percent=70 --min=1 --max=5
```

### Resource Tuning

Edit `ollama-api/k8s/deployment.yaml`:

```yaml
resources:
  requests:
    memory: "2Gi"    # Minimum memory
    cpu: "1"         # Minimum CPU
  limits:
    memory: "8Gi"    # Maximum memory
    cpu: "4"         # Maximum CPU
```

### Performance Tips

1. **Model Selection**: Use smaller models (1B-3B) for faster responses
2. **Memory**: Ensure sufficient RAM for model loading
3. **CPU**: More CPU cores improve concurrent request handling
4. **Storage**: Use fast SSD storage for model files
5. **Network**: Ensure good network connectivity to ACR

### Monitoring Setup

```bash
# Install metrics server (if not present)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View resource metrics
kubectl top nodes
kubectl top pods --all-namespaces
```

## 🔐 Security Considerations

1. **ACR Authentication**: Uses Azure Key Vault for secure credential storage
2. **Network Security**: Ingress controls external access
3. **Resource Limits**: Prevents resource exhaustion
4. **Image Security**: Uses official Ollama base image

## 🔄 Updates & Maintenance

### Update Ollama Version
```bash
# Rebuild with latest Ollama image
./scripts/build-and-push.sh

# Restart deployment to use new image
kubectl rollout restart deployment/ollama-api
```

### Backup Models
```bash
# Export model
kubectl exec -it deployment/ollama-api -- ollama export llama3.2:1b > model-backup.tar

# Import model
kubectl exec -i deployment/ollama-api -- ollama import < model-backup.tar
```

### Clean Up
```bash
# Remove deployment
kubectl delete -f ollama-api/k8s/

# Remove images from ACR
az acr repository delete --name jshaipacr2508 --repository ollama-api
```

## 📞 Support

- **Logs**: Always check `kubectl logs deployment/ollama-api` first
- **Status**: Use `kubectl get pods,svc,ingress -l app=ollama-api`
- **Testing**: Run `./scripts/test-ollama.sh` to verify functionality
- **Documentation**: Ollama official docs at https://ollama.ai/

## 📝 Quick Reference

### Useful Commands
```bash
# Deploy everything
./deploy-ollama.sh

# Test deployment
./scripts/test-ollama.sh

# Install model
kubectl exec -it deployment/ollama-api -- ollama pull llama3.2:1b

# Check status
kubectl get pods -l app=ollama-api

# View logs
kubectl logs -f deployment/ollama-api

# Scale deployment
kubectl scale deployment ollama-api --replicas=2

# Update deployment
kubectl rollout restart deployment/ollama-api
```

### Access URLs
- **API**: `http://ollama.local/api/tags`
- **Chat**: `http://ollama.local/chat`
- **Direct IP**: `http://10.0.1.4/ollama`

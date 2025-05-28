#!/bin/bash

# Complete deployment script for Ollama API
set -e

# Set the model name to install (see https://ollama.com/search for available models)
MODEL_NAME="llama3.2:1b"

echo "🚀 Deploying Ollama API to K3s cluster..."
echo ""

# Help/usage output
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: $0 [infra|ollama|destroy]"
  echo ""
  echo "Options:"
  echo "  infra     Deploy all Azure infrastructure with Terraform only."
  echo "  ollama    Deploy Ollama API, chat UI, and models to Kubernetes only (assumes infra exists)."
  echo "  destroy   Destroy all Azure infrastructure (and K8s workloads within it)."
  echo "  -h, --help  Show this help message."
  echo ""
  echo "Examples:"
  echo "  $0 infra     # Deploy infra only"
  echo "  $0 ollama    # Deploy Ollama app only (assumes infra exists)"
  echo "  $0 destroy   # Destroy all infra (and K8s workloads)"
  exit 0
fi

# Infra only
if [[ "$1" == "infra" ]]; then
  ./scripts/deploy-infra.sh apply
  exit $?
fi

# Destroy option
if [[ "$1" == "destroy" ]]; then
  ./scripts/deploy-infra.sh destroy
  exit $?
fi

# Ollama only (default if no arg or 'ollama')
if [[ -z "$1" || "$1" == "ollama" ]]; then
  # Bootstrap MetalLB CRDs/namespace if needed
  ./scripts/bootstrap-metallb.sh

  # Step 1: Update manifests with correct ACR image
  echo "📝 Step 1: Updating Kubernetes manifests..."
  ./scripts/update-k8s-manifests.sh
  echo ""

  # Step 2: Build and push Docker image
  echo "🏗️  Step 2: Building and pushing Docker image..."
  ./scripts/build-and-push.sh
  echo ""

  # Step 3: Setup ACR pull secret
  echo "🔐 Step 3: Setting up ACR pull secret..."
  ./scripts/setup-acr-secret.sh
  echo ""

  # Step 4: Deploying Ollama to Kubernetes...
  echo "🎯 Step 4: Deploying Ollama to Kubernetes..."
  kubectl apply -f ollama-api/k8s/
  echo ""

  # Step 5: Wait for deployment
  echo "⏳ Step 5: Waiting for deployment to be ready..."
  kubectl wait --for=condition=available --timeout=300s deployment/ollama-api
  echo ""

  # Step 6: Show status
  echo "📊 Deployment Status:"
  kubectl get pods,svc,ingress -l app=ollama-api

  # Step 7: Get access information
  PRIVATE_IP=$(kubectl get svc traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  PUBLIC_IP=$(az network public-ip show --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw public_ip_name) --query ipAddress -o tsv 2>/dev/null)

  SEPARATOR="=============================="
  echo ""
  echo "$SEPARATOR"
  echo "🌐 Access Information:"
  if [ -n "$PUBLIC_IP" ]; then
      echo "   Public IP: $PUBLIC_IP"
      echo "   Access Ollama API: http://$PUBLIC_IP/ollama"
      echo "   Access Chat UI:   http://$PUBLIC_IP/chat"
      echo "   Add to /etc/hosts: $PUBLIC_IP ollama-public.local"
      echo "   Then access: http://ollama-public.local"
  fi
  if [ -n "$PRIVATE_IP" ]; then
      echo "   Traefik LoadBalancer IP: $PRIVATE_IP"
      echo "   Access Ollama API: http://$PRIVATE_IP/ollama"
      echo "   Access Chat UI:   http://$PRIVATE_IP/chat"
      echo "   Add to /etc/hosts: $PRIVATE_IP ollama.local"
      echo "   Then access: http://ollama.local"
  fi
  echo "$SEPARATOR"

  # Step 8: Install default LLM model
  echo "🤖 Step 8: Installing default LLM model ($MODEL_NAME)..."
  ./scripts/install-model.sh "$MODEL_NAME"

  # Step 9: Final output and test info
  POD_NAME=$(kubectl get pods -l app=ollama-api -o jsonpath='{.items[0].metadata.name}')
  echo "$SEPARATOR"
  echo "✅ Chat application deployed successfully!"
  echo ""
  echo "🌐 Access URLs:"
  if [ -n "$PUBLIC_IP" ]; then
      echo "   • http://$PUBLIC_IP/chat"
      echo "   • http://ollama-public.local/chat (if /etc/hosts set)"
  fi
  if [ -n "$PRIVATE_IP" ]; then
      echo "   • http://$PRIVATE_IP/chat"
      echo "   • http://ollama.local/chat (if /etc/hosts set)"
  fi
  echo ""
  echo "📝 Features:"
  echo "   • Real-time chat with AI models"
  echo "   • Model selection dropdown"
  echo "   • Conversation history"
  echo "   • Responsive design"
  echo "   • Markdown rendering"
  echo ""
  echo "🔧 Management commands:"
  echo "   • View logs: kubectl logs -f deployment/ollama-chat"
  echo "   • Scale: kubectl scale deployment ollama-chat --replicas=3"
  echo "   • Restart: kubectl rollout restart deployment/ollama-chat"
  echo ""
  echo "✅ Complete deployment finished!"
  echo ""
  echo "🧪 Test the API with:"
  if [ -n "$PUBLIC_IP" ]; then
      echo "   curl http://$PUBLIC_IP/ollama/api/tags"
      echo "   # or with hostname:"
      echo "   curl http://ollama-public.local/api/tags"
  fi
  if [ -n "$PRIVATE_IP" ]; then
      echo "   curl http://$PRIVATE_IP/ollama/api/tags"
      echo "   # or with hostname:"
      echo "   curl http://ollama.local/api/tags"
  fi
  echo ""
  echo "💬 Access the chat interface at:"
  if [ -n "$PUBLIC_IP" ]; then
      echo "   http://$PUBLIC_IP/chat"
      echo "   # or with hostname:"
      echo "   http://ollama-public.local/chat"
  fi
  if [ -n "$PRIVATE_IP" ]; then
      echo "   http://$PRIVATE_IP/chat"
      echo "   # or with hostname:"
      echo "   http://ollama.local/chat"
  fi
  echo "$SEPARATOR"
  exit 0
fi

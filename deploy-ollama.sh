#!/bin/bash

# Complete deployment script for Ollama API
set -e

# Set the model name to install (see https://ollama.com/search for available models)
MODEL_NAME="llama3.2:1b"

# Help/usage output
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: $0 [infra|ollama|destroy|all]"
  echo ""
  echo "Options:"
  echo "  infra     Deploy all Azure infrastructure with Terraform only."
  echo "  ollama    Deploy Ollama API, chat UI, and models to Kubernetes only (assumes infra exists)."
  echo "  destroy   Destroy all Azure infrastructure (and K8s workloads within it)."
  echo "  all       Deploy both infra and Ollama API sequentially."
  echo "  -h, --help  Show this help message."
  echo ""
  echo "Examples:"
  echo "  $0 infra     # Deploy infra only"
  echo "  $0 ollama    # Deploy Ollama app only (assumes infra exists)"
  echo "  $0 destroy   # Destroy all infra (and K8s workloads)"
  echo "  $0 all       # Deploy both infra and Ollama API sequentially"
  exit 0
fi

# Infra only
if [[ "$1" == "infra" ]]; then
  ./scripts/deploy-infra.sh
  exit $?
fi

# Destroy option
if [[ "$1" == "destroy" ]]; then
  ./scripts/deploy-infra.sh destroy
  echo "✅ Terraform destroy complete."
  exit $?
fi

# Run both infra and ollama if 'all' is specified or no argument is provided
if [[ -z "$1" || "$1" == "all" ]]; then
  "$0" infra
  INFRA_EXIT_CODE=$?
  if [[ $INFRA_EXIT_CODE -ne 0 ]]; then
    echo "❌ Infra deployment failed. Skipping Ollama deployment."
    exit $INFRA_EXIT_CODE
  fi
  "$0" ollama
  exit $?
fi

# Ollama only (if explicitly specified)
if [[ "$1" == "ollama" ]]; then
  # Start Azure Arc proxy if not already running
  CLUSTER_NAME=$(cd infra && terraform output -raw k3s_cp_cluster_name | sed 's/-rg.*//')
  RESOURCE_GROUP=$(cd infra && terraform output -raw k3s_resource_group)
  KV=$(cd infra && terraform output -raw kv_name)

  # Validate required variables
  if [[ -z "$CLUSTER_NAME" || -z "$RESOURCE_GROUP" || -z "$KV" ]]; then
    echo "❌ Error: One or more required variables (CLUSTER_NAME, RESOURCE_GROUP, KV) are empty."
    echo "   CLUSTER_NAME='$CLUSTER_NAME'"
    echo "   RESOURCE_GROUP='$RESOURCE_GROUP'"
    echo "   KV='$KV'"
    exit 1
  fi

  # Wait for arc-admin-bearer-token to appear in Key Vault
  echo "⏳ Waiting for arc-admin-bearer-token to be available in Key Vault $KV..."
  MAX_ATTEMPTS=60
  SLEEP_INTERVAL=10
  for ((i=1; i<=MAX_ATTEMPTS; i++)); do
    set +e
    TOKEN=$(az keyvault secret show --vault-name "$KV" --name arc-admin-bearer-token --query value -o tsv 2>/dev/null)
    AZ_EXIT=$?
    set -e
    if [[ $AZ_EXIT -eq 0 && -n "$TOKEN" && "$TOKEN" != "None" ]]; then
      echo "✅ arc-admin-bearer-token found in Key Vault (after $((i*SLEEP_INTERVAL)) seconds)."
      break
    fi
    echo "  [$(date '+%H:%M:%S')] Attempt $i/$MAX_ATTEMPTS: Secret not found yet. Waiting $SLEEP_INTERVAL seconds..."
    sleep $SLEEP_INTERVAL
    if [[ $i -eq $MAX_ATTEMPTS ]]; then
      echo "❌ Timed out waiting ($((MAX_ATTEMPTS*SLEEP_INTERVAL))s) for arc-admin-bearer-token in Key Vault $KV. Exiting."
      exit 1
    fi
  done

  TOKEN=$(az keyvault secret show --vault-name "$KV" --name arc-admin-bearer-token --query value -o tsv)
  if [[ -z "$TOKEN" ]]; then
    echo "❌ Error: Failed to retrieve arc-admin-bearer-token from Key Vault $KV."
    exit 1
  fi

  PROXY_PORT=$(( ( RANDOM % 1000 )  + 47011 ))
  echo "🔗 Starting Azure Arc proxy on port $PROXY_PORT..."
  az connectedk8s proxy -n "$CLUSTER_NAME" -g "$RESOURCE_GROUP" --token "$TOKEN" --port $PROXY_PORT > /dev/null 2>&1 &
  export KUBECONFIG=~/.kube/config  # Ensure kubectl uses the right config
  PROXY_PID=$!
  sleep 5
  # Wait for Kubernetes API to be available before proceeding
  NODE_NAME=$(cd infra && terraform output -raw k3s_cp_vm_name)
  echo "⏳ Waiting for Kubernetes API and node $NODE_NAME to be available..."
  for i in {1..60}; do
    NODE_CHECK=$(kubectl get nodes --no-headers 2>/dev/null | grep -w "$NODE_NAME" | awk '{print $2}')
    if [[ "$NODE_CHECK" == "Ready" ]]; then
      echo "✅ Kubernetes API is available and node $NODE_NAME is Ready."
      echo ""
      break
    fi
    sleep 5
    if [[ $i -eq 60 ]]; then
      echo "❌ Timed out waiting for Kubernetes API or node $NODE_NAME. Exiting."
      echo ""
      kill $PROXY_PID 2>/dev/null || true
      exit 1
    fi
  done
  
  # Bootstrap MetalLB CRDs/namespace if needed
  echo "🚀 Bootstrap MetalLB..."
  ./scripts/bootstrap-metallb.sh
  echo ""

  # Build and push Docker image
  echo "🏗️ Building and pushing Docker image..."
  ./scripts/build-and-push.sh
  echo ""

  # Update manifests with correct ACR image
  echo "📝 Updating Kubernetes manifests..."
  ./scripts/update-k8s-manifests.sh
  echo ""

  # Setup ACR pull secret
  echo "🔐 Setting up ACR pull secret..."
  ./scripts/setup-acr-secret.sh
  echo ""

  # Deploying Ollama to Kubernetes...
  echo "🎯 Deploying Ollama to Kubernetes..."
  kubectl apply -f ollama-api/k8s/
  echo ""

  # Wait for deployments
  echo "⏳ Waiting for deployments to be ready..."
  kubectl wait --for=condition=available --timeout=180s deployment/ollama-api || DEPLOY_API_STATUS=$?
  kubectl wait --for=condition=available --timeout=180s deployment/ollama-chat || DEPLOY_CHAT_STATUS=$?
  if [[ $DEPLOY_API_STATUS -ne 0 || $DEPLOY_CHAT_STATUS -ne 0 ]]; then
    echo "⚠️  Not all deployments are ready after first wait. Waiting 2 more minutes..."
    sleep 120
    kubectl wait --for=condition=available --timeout=60s deployment/ollama-api || DEPLOY_API_STATUS=$?
    kubectl wait --for=condition=available --timeout=60s deployment/ollama-chat || DEPLOY_CHAT_STATUS=$?
    if [[ $DEPLOY_API_STATUS -ne 0 || $DEPLOY_CHAT_STATUS -ne 0 ]]; then
      echo "❌ ERROR: ollama-api or ollama-chat deployment did not become ready. Exiting."
      kubectl get pods
      exit 1
    fi
  fi
  echo "✅ Both ollama-api and ollama-chat deployments are ready."
  echo ""

  # Show status
  echo "📊 Deployment Status:"
  kubectl get pods,svc,ingress -l app=ollama-api
  kubectl get pods,svc,ingress -l app=ollama-chat
  echo ""

  # Get access information
  PRIVATE_IP=$(kubectl get svc traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  PUBLIC_IP=$(az network public-ip show --resource-group $(cd infra && terraform output -raw k3s_resource_group) --name $(cd infra && terraform output -raw k3s_lb_pip_name) --query ipAddress -o tsv 2>/dev/null)

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

  # Install default LLM model
  echo "🤖 Installing default LLM model ($MODEL_NAME)..."
  ./scripts/install-model.sh "$MODEL_NAME"
  echo ""

  # Final output and test info
  # POD_NAME=$(kubectl get pods -l app=ollama-api -o jsonpath='{.items[0].metadata.name}')
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
      echo "   curl http://$PUBLIC_IP/api/tags"
  fi
  if [ -n "$PRIVATE_IP" ]; then
      echo "   curl http://$PRIVATE_IP/api/tags"
  fi
  echo ""
  echo "💬 Access the chat interface at:"
  if [ -n "$PUBLIC_IP" ]; then
      echo "   http://$PUBLIC_IP"
      echo "   http://$PUBLIC_IP/chat"
  fi
  if [ -n "$PRIVATE_IP" ]; then
      echo "   http://$PRIVATE_IP"
      echo "   http://$PRIVATE_IP/chat"
  fi
  echo "$SEPARATOR"
  exit 0
fi

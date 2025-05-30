#!/bin/bash

# Script to create ACR pull secret in Kubernetes
# Usage: ./setup-acr-secret.sh
# This script retrieves ACR credentials from Azure Key Vault and creates a Kubernetes secret for image pulls.
# Creates a Kubernetes secret for pulling images from Azure Container Registry (ACR)

set -e

echo "🔍 Getting ACR information from Terraform..."

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Change to infra directory to run terraform commands
cd "$PROJECT_ROOT/infra"

# Get ACR details from Terraform output
ACR_SERVER=$(terraform output -raw acr_login_server)
KV_NAME=$(terraform output -raw kv_name)

echo "📋 ACR Server: $ACR_SERVER"
echo "📋 Key Vault: $KV_NAME"

# Get ACR credentials from Key Vault
echo "🔑 Getting ACR credentials from Key Vault..."
ACR_USER=$(az keyvault secret show --vault-name "$KV_NAME" --name acr-admin-username --query value -o tsv)
ACR_PASS=$(az keyvault secret show --vault-name "$KV_NAME" --name acr-admin-password --query value -o tsv)

# Go back to project root
cd "$PROJECT_ROOT"

echo "🔐 Creating Kubernetes secret for ACR pull access..."

# Delete existing secret if it exists (ignore errors)
kubectl delete secret acr-pull-secret --ignore-not-found=true

# Create the pull secret
kubectl create secret docker-registry acr-pull-secret \
  --docker-server="$ACR_SERVER" \
  --docker-username="$ACR_USER" \
  --docker-password="$ACR_PASS" \
  --docker-email="user@example.com"

echo "✅ Successfully created ACR pull secret 'acr-pull-secret'"
echo "🎯 You can now deploy your Ollama API with:"
echo "   kubectl apply -f ollama-api/k8s/"
echo ""
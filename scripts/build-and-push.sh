#!/bin/bash

# Script to build and push Ollama API image to ACR
# Usage: ./build-and-push.sh
# This script logs into ACR, builds the Ollama API Docker image, and pushes it to ACR.

set -e

echo "🔍 Getting ACR information from Terraform..."

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Change to infra directory to run terraform commands
cd "$PROJECT_ROOT/infra"

# Get ACR details from Terraform output
ACR_SERVER=$(terraform output -raw acr_login_server)
ACR_NAME=$(terraform output -raw acr_name)
KV_NAME=$(terraform output -raw kv_name)

echo "📋 ACR Server: $ACR_SERVER"
echo "📋 ACR Name: $ACR_NAME"
echo "📋 Key Vault: $KV_NAME"

# Get ACR credentials from Key Vault
echo "🔑 Getting ACR credentials from Key Vault..."
ACR_USER=$(az keyvault secret show --vault-name "$KV_NAME" --name acr-admin-username --query value -o tsv)
ACR_PASS=$(az keyvault secret show --vault-name "$KV_NAME" --name acr-admin-password --query value -o tsv)

# Login to ACR
echo "🔐 Logging into ACR..."
echo "$ACR_PASS" | docker login "$ACR_SERVER" --username "$ACR_USER" --password-stdin

# Go back to project root
cd "$PROJECT_ROOT"

# Build and push the image
IMAGE_TAG="$ACR_SERVER/ollama-api:latest"
echo "🏗️  Building Docker image: $IMAGE_TAG"
docker build -t "$IMAGE_TAG" ./ollama-api

echo "📤 Pushing image to ACR..."
docker push "$IMAGE_TAG"

echo "✅ Successfully built and pushed $IMAGE_TAG"
echo ""
echo "📝 Update your Kubernetes manifests with this image:"
echo "   $IMAGE_TAG"

#!/bin/bash

# Script to build and push Ollama API image to ACR
# Builds and pushes the Ollama API Docker image to Azure Container Registry (ACR)
# Usage: ./build-and-push.sh
# This script:
# - logs into ACR
# - builds the Ollama API and Ollama Chat Docker images
# - pushes images to ACR

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

# Build and push the Ollama API image
IMAGE_TAG="$ACR_SERVER/ollama-api:latest"
echo "🏗️ Building Ollama Api Docker image: $IMAGE_TAG"
docker build -t "$IMAGE_TAG" ./ollama-api

echo "📤 Pushing Ollama API image to ACR..."
docker push "$IMAGE_TAG"

echo "✅ Successfully built and pushed $IMAGE_TAG"
echo ""
echo "📝 Next is to update your Kubernetes manifests with this image:"
echo "   $IMAGE_TAG"
echo ""

echo "🚀 Building and deploying Ollama Chat Interface..."

# Build and push the Ollama Chat image
CHAT_TAG="$ACR_SERVER/ollama-chat:latest"
CHAT_DIR="./ollama-api/web-chat"

# Check if chat directory exists
if [ ! -d "$CHAT_DIR" ]; then
    echo "❌ Chat directory not found: $CHAT_DIR"
    echo ""
    exit 1
fi

# Build chat application image
echo "📦 Building Ollama Chat Docker image: $CHAT_TAG"
cd "$CHAT_DIR"
docker build -t "$CHAT_TAG" .
cd - > /dev/null

echo "📤 Pushing Ollama Chat image to ACR..."
docker push "$CHAT_TAG"

echo "✅ Successfully built and pushed $CHAT_TAG"
echo ""
echo "📝 Next is to update your Kubernetes manifests with this image:"
echo "   $CHAT_TAG"
echo ""
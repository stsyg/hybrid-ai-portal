#!/bin/bash

# Updates Kubernetes manifests with the correct ACR image for Ollama API

# Script to update Kubernetes manifests with correct ACR image
set -e

echo "🔍 Getting ACR information from Terraform..."

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Change to infra directory to run terraform commands
cd "$PROJECT_ROOT/infra"

# Get ACR details from Terraform output
ACR_SERVER=$(terraform output -raw acr_login_server)

# Go back to project root
cd "$PROJECT_ROOT"

API_IMAGE_TAG="$ACR_SERVER/ollama-api:latest"

echo "🔄 Updating Kubernetes Ollama API deployment with image: $API_IMAGE_TAG"

# Update the Ollama API deployment file with the correct ACR image
sed -i "s|image: .*|image: $API_IMAGE_TAG|g" ollama-api/k8s/ollama-api.yaml

echo "✅ Updated ollama-api.yaml with correct ACR image"
echo "📝 Image in dollama-api.yaml is now: $API_IMAGE_TAG"
echo ""

# Also update the Ollama Chat deployment file with the correct ACR image
CHAT_IMAGE_TAG="$ACR_SERVER/ollama-chat:latest"

echo "🔄 Updating Kubernetes Ollama Chat deployment with image: $CHAT_IMAGE_TAG"

sed -i "s|image: .*|image: $CHAT_IMAGE_TAG|g" ollama-api/k8s/ollama-chat.yaml

echo "✅ Updated ollama-chat.yaml with correct ACR image: $CHAT_IMAGE_TAG"
echo "📝 Image in dollama-api.yaml is now: $CHAT_IMAGE_TAG"
echo ""
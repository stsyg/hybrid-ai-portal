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

IMAGE_TAG="$ACR_SERVER/ollama-api:latest"

echo "🔄 Updating Kubernetes deployment with image: $IMAGE_TAG"

# Update the deployment.yaml file with the correct ACR image
sed -i "s|image: .*|image: $IMAGE_TAG|g" ollama-api/k8s/deployment.yaml

echo "✅ Updated deployment.yaml with correct ACR image"
echo "📝 Image in deployment.yaml is now: $IMAGE_TAG"

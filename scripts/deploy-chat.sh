#!/bin/bash

# Build and deploy Ollama Chat Interface
# This script builds the chat UI Docker image, pushes it to ACR, and deploys it to Kubernetes.
# Usage: ./deploy-chat.sh

set -e

echo "🚀 Building and deploying Ollama Chat Interface..."

# Configuration
ACR_NAME="jshaipacr2508"
CHAT_IMAGE="${ACR_NAME}.azurecr.io/ollama-chat:latest"
CHAT_DIR="./ollama-api/web-chat"

# Check if chat directory exists
if [ ! -d "$CHAT_DIR" ]; then
    echo "❌ Chat directory not found: $CHAT_DIR"
    exit 1
fi

# Build chat application image
echo "📦 Building chat application Docker image..."
cd "$CHAT_DIR"
docker build -t "$CHAT_IMAGE" .
cd - > /dev/null

# Push to ACR
echo "📤 Pushing image to Azure Container Registry..."
docker push "$CHAT_IMAGE"

# Deploy to Kubernetes
echo "🔄 Deploying chat application to Kubernetes..."
kubectl apply -f ollama-api/k8s/chat-app.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for chat deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/ollama-chat

# Check deployment status
echo "📊 Deployment Status:"
kubectl get pods -l app=ollama-chat
kubectl get svc ollama-chat
kubectl get ingress ollama-chat

# Get access information
echo ""
echo "✅ Chat application deployed successfully!"
echo ""
echo "🌐 Access URLs:"
echo "   • http://ollama.local/chat"
echo "   • http://10.0.1.4/chat"
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

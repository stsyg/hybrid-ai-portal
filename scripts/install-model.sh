#!/bin/bash

# Script to install a model in the running Ollama instance
# Usage: ./install-model.sh [model_name]
# Default: llama3.2:1b
# This script finds the Ollama pod and pulls the specified model into it.
# The model will then be available via the API and chat UI.

set -e

MODEL_NAME=${1:-"llama3.2:1b"}

echo "🤖 Installing model: $MODEL_NAME"
echo "📡 Finding Ollama pod..."

# Get the Ollama pod name
POD_NAME=$(kubectl get pods -l app=ollama-api -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "❌ No Ollama pod found. Make sure the deployment is running."
    exit 1
fi

echo "📦 Found pod: $POD_NAME"
echo "⬇️  Downloading model $MODEL_NAME (this may take a while)..."

# Execute ollama pull command in the pod
kubectl exec -it "$POD_NAME" -- ollama pull "$MODEL_NAME"

echo "✅ Model $MODEL_NAME installed successfully!"
echo ""
echo "🧪 Test the model with:"
echo "   kubectl exec -it $POD_NAME -- ollama run $MODEL_NAME"
echo ""
echo "🌐 Or via API:"
TRAEFIK_IP=$(kubectl get svc traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -n "$TRAEFIK_IP" ]; then
    echo "   curl -X POST http://$TRAEFIK_IP/ollama/api/generate \\"
    echo "     -H 'Content-Type: application/json' \\"
    echo "     -d '{\"model\": \"$MODEL_NAME\", \"prompt\": \"Hello, world!\", \"stream\": false}'"
fi

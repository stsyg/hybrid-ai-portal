#!/bin/bash

# Script to install multiple models in the running Ollama instance
# Installs a list of LLM models into the running Ollama pod in Kubernetes
# Usage: ./install-models.sh [model1] [model2] [model3] ...
# Or use terraform output: ./install-models.sh $(cd infra && terraform output -json default_models | jq -r '.[]')
# This script finds the Ollama pod and pulls the specified models into it.
# The models will then be available via the API and chat UI.

set -e

# Get models from command line args or default
if [ $# -eq 0 ]; then
    # Try to get models from terraform output
    if command -v terraform &> /dev/null && [ -f "infra/terraform.tfstate" ]; then
        echo "📋 Getting default models from Terraform configuration..."
        cd infra
        MODELS=($(terraform output -json default_models | jq -r '.[]'))
        cd ..
    else
        # Fallback to default model
        echo "⚠️  No models specified and Terraform not available. Using default model."
        MODELS=("llama3.2:1b")
    fi
else
    MODELS=("$@")
fi

echo "🤖 Installing ${#MODELS[@]} models: ${MODELS[*]}"
echo "📡 Finding Ollama pod..."

# Get the Ollama pod name
POD_NAME=$(kubectl get pods -l app=ollama-api -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "❌ No Ollama pod found. Make sure the deployment is running."
    exit 1
fi

echo "📦 Found pod: $POD_NAME"

# Install each model
for MODEL in "${MODELS[@]}"; do
    echo "⬇️  Downloading model $MODEL (this may take a while)..."
    
    # Execute ollama pull command in the pod
    kubectl exec -it "$POD_NAME" -- ollama pull "$MODEL"
    
    echo "✅ Model $MODEL installed successfully!"
    echo ""
done

echo "🎉 All models installed successfully!"
echo ""
echo "🧪 Test the models with:"
for MODEL in "${MODELS[@]}"; do
    echo "   kubectl exec -it $POD_NAME -- ollama run $MODEL"
done
echo ""

echo "🌐 Or via API:"
TRAEFIK_IP=$(kubectl get svc traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -n "$TRAEFIK_IP" ]; then
    echo "   # List all models:"
    echo "   curl http://$TRAEFIK_IP/ollama/api/tags"
    echo ""
    echo "   # Test with a specific model:"
    for MODEL in "${MODELS[@]}"; do
        echo "   curl -X POST http://$TRAEFIK_IP/ollama/api/generate \\"
        echo "     -H 'Content-Type: application/json' \\"
        echo "     -d '{\"model\": \"$MODEL\", \"prompt\": \"Hello, world!\", \"stream\": false}'"
        echo ""
        break  # Only show one example
    done
fi
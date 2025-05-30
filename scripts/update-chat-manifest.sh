# #!/bin/bash
# # Updates Kubernetes chat-app manifest with the correct ACR image for Ollama Chat
# set -e

# # Get the absolute path to the project root
# PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# # Change to infra directory to run terraform commands
# cd "$PROJECT_ROOT/infra"

# # Get ACR details from Terraform output
# ACR_SERVER=$(terraform output -raw acr_login_server)

# # Go back to project root
# cd "$PROJECT_ROOT"

# IMAGE_TAG="$ACR_SERVER/ollama-chat:latest"

# # Update the chat-app.yaml file with the correct ACR image
# sed -i "s|image: .*|image: $IMAGE_TAG|g" ollama-api/k8s/chat-app.yaml

# echo "✅ Updated chat-app.yaml with correct ACR image: $IMAGE_TAG"

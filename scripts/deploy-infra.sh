#!/bin/bash
# Script to deploy (or destroy) all Terraform infrastructure
# Usage: ./scripts/deploy-infra.sh [apply|destroy]
set -e

# Check for ARM_SUBSCRIPTION_ID environment variable
if [[ -z "$ARM_SUBSCRIPTION_ID" ]]; then
  read -p "Enter your Azure Subscription ID (ARM_SUBSCRIPTION_ID): " ARM_SUBSCRIPTION_ID
  if [[ -z "$ARM_SUBSCRIPTION_ID" ]]; then
    echo "❌ Error: ARM_SUBSCRIPTION_ID is required. Exiting."
    exit 1
  fi
  export ARM_SUBSCRIPTION_ID
fi

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Change to infra directory to run terraform commands
cd "$PROJECT_ROOT/infra"

ACTION=$1

if [[ "$ACTION" == "destroy" ]]; then
  echo "⚠️  Destroying all infrastructure with Terraform..."
  terraform destroy --auto-approve
  exit $?
else
  echo "🚀 Deploying infrastructure with Terraform..."
  terraform init
  terraform apply --auto-approve
fi

# Go back to project root
cd "$PROJECT_ROOT"
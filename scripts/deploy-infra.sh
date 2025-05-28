#!/bin/bash
# Script to deploy (or destroy) all Terraform infrastructure
# Usage: ./scripts/deploy-infra.sh [apply|destroy]
set -e

cd infra

ACTION=${1:-apply}

if [[ "$ACTION" == "destroy" ]]; then
  echo "⚠️  Destroying all infrastructure with Terraform..."
  terraform destroy
  exit $?
fi

echo "🚀 Deploying infrastructure with Terraform..."
terraform init
terraform apply

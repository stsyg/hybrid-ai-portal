#!/bin/bash
# Script to bootstrap MetalLB CRDs and namespace from the official MetalLB manifest
# Usage: ./scripts/bootstrap-metallb.sh
set -e

# Official MetalLB manifest (update version as needed)
METALLB_MANIFEST_URL="https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml"

if kubectl get ns metallb-system &>/dev/null; then
  echo "✅ MetalLB namespace already exists. Skipping bootstrap."
  exit 0
fi

echo "🚦 Bootstrapping MetalLB CRDs and namespace from $METALLB_MANIFEST_URL ..."
kubectl apply -f "$METALLB_MANIFEST_URL"
echo "✅ MetalLB CRDs and namespace applied."

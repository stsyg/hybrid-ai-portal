#!/bin/bash
# Bootstrap MetalLB and patch Traefik service to LoadBalancer with ports 80/443
set -e

# Install MetalLB CRDs and namespace if not already present
if ! kubectl get ns metallb-system &>/dev/null; then
  echo "🔄 Installing MetalLB CRDs and namespace from GitHub..."
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
else
  echo "✅ MetalLB CRDs and namespace already installed."
  echo ""
fi

echo "📝 Updating MetalLB configuration and patching Traefik..."
echo ""

# Wait for MetalLB controller deployment to be ready
kubectl -n metallb-system rollout status deployment/controller --timeout=120s

# Wait for MetalLB webhook service endpoints to be ready
for i in {1..24}; do
  ENDPOINTS=$(kubectl -n metallb-system get endpoints metallb-webhook-service -o jsonpath='{.subsets}' 2>/dev/null)
  if [[ -n "$ENDPOINTS" && "$ENDPOINTS" != "null" ]]; then
    echo "✅ MetalLB webhook service endpoints are ready."
    break
  fi
  echo "⏳ Waiting for MetalLB webhook service endpoints... ($i/24)"
  sleep 5
  if [[ $i -eq 24 ]]; then
    echo "❌ Timed out waiting for MetalLB webhook service endpoints. Exiting."
    exit 1
  fi
done

kubectl apply -f ollama-api/k8s/metallb-config.yaml

# Patch Traefik service to LoadBalancer with ports 80/443
kubectl -n kube-system patch svc traefik --type='merge' -p '{
  "spec": {
    "type": "LoadBalancer",
    "ports": [
      {
        "name": "web",
        "port": 80,
        "targetPort": 8000,
        "protocol": "TCP"
      },
      {
        "name": "websecure",
        "port": 443,
        "targetPort": 8443,
        "protocol": "TCP"
      }
    ]
  }
}'

# Wait for external IP assignment
for i in {1..30}; do
  EXTERNAL_IP=$(kubectl -n kube-system get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  if [[ -n "$EXTERNAL_IP" ]]; then
    echo "✅ Traefik LoadBalancer external IP: $EXTERNAL_IP"
    echo ""
    break
  fi
  echo "⏳ Waiting for Traefik external IP... ($i/30)"
  sleep 5
  if [[ $i -eq 30 ]]; then
    echo "❌ Timed out waiting for Traefik external IP."
    echo ""
    exit 1
  fi

done

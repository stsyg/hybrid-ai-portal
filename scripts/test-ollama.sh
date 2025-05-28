#!/bin/bash

# Manual test script for verifying Ollama API deployment and model functionality
# Test script for Ollama API deployment
# Usage: ./test-ollama.sh
# This script checks API health, lists models, and runs a test generation.

set -e

echo "🧪 Testing Ollama API deployment..."
echo ""

# Test 1: Check API health
echo "📋 Test 1: Checking API health..."
kubectl run test-health --image=curlimages/curl --rm -it --restart=Never -- curl -s http://ollama-api.default.svc.cluster.local/api/tags
echo ""

# Test 2: List available models
echo "📋 Test 2: Listing available models..."
MODELS=$(kubectl run test-models --image=curlimages/curl --rm -it --restart=Never -- curl -s http://ollama-api.default.svc.cluster.local/api/tags 2>/dev/null)
echo "$MODELS"
echo ""

# Test 3: Simple generation test
echo "📋 Test 3: Testing model generation..."
kubectl run test-generate --image=curlimages/curl --rm -it --restart=Never -- curl -s -X POST http://ollama-api.default.svc.cluster.local/api/generate -H "Content-Type: application/json" -d '{"model":"llama3.2:1b","prompt":"Write a haiku about AI","stream":false}' 2>/dev/null
echo ""

echo "✅ All tests completed!"
echo ""
echo "🌐 Access Information:"
echo "   Internal (cluster): http://ollama-api.default.svc.cluster.local"
echo "   External (ingress): http://10.0.1.4/ollama"
echo "   With hostname: http://ollama.local (add to /etc/hosts: 10.0.1.4 ollama.local)"
echo ""
echo "📝 Example API calls:"
echo "   List models: curl http://ollama.local/api/tags"
echo "   Generate text: curl -X POST http://ollama.local/api/generate -H 'Content-Type: application/json' -d '{\"model\":\"llama3.2:1b\",\"prompt\":\"Hello!\",\"stream\":false}'"

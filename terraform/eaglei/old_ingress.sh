#!/bin/bash
set -euo pipefail

NAMESPACE="ingress-nginx"
RELEASE_NAME="ingress-nginx"

echo "📦 Adding ingress-nginx Helm repo..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

echo "🛠️ Creating namespace $NAMESPACE..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "🚀 Installing NGINX Ingress Controller..."
helm upgrade --install "$RELEASE_NAME" ingress-nginx/ingress-nginx \
  --namespace "$NAMESPACE" \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.service.externalTrafficPolicy=Local \
   --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="external" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"="internet-facing" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-nlb-target-type"="ip" \
  --set controller.publishService.enabled=true

echo "⏳ Waiting for LoadBalancer external IP..."
LB=""
for i in {1..30}; do
  LB=$(kubectl get svc "$RELEASE_NAME"-controller -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || true)
  if [[ -n "$LB" ]]; then
    echo "🌐 LoadBalancer hostname: $LB"
    break
  fi
  echo "⏳ Still waiting for external IP..."
  sleep 10
done

if [[ -z "$LB" ]]; then
  echo "❌ LoadBalancer hostname not assigned. Check service status:"
  kubectl get svc -n "$NAMESPACE"
  exit 1
fi

echo "✅ NGINX Ingress Controller installed and available at:"
echo "http://$LB"
#!/bin/bash
set -euo pipefail

NAMESPACE="cert-manager"
CLUSTER_ISSUER_NAME="letsencrypt-production"

echo "📦 Adding Jetstack Helm repo..."
helm repo add jetstack https://charts.jetstack.io
helm repo update

echo "🛠️ Creating namespace $NAMESPACE..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "🚀 Installing cert-manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace "$NAMESPACE" \
  --version v1.12.2 \
  --set installCRDs=true

echo "⏳ Waiting for cert-manager pods to be ready..."
kubectl -n "$NAMESPACE" rollout status deployment cert-manager
kubectl -n "$NAMESPACE" rollout status deployment cert-manager-webhook
kubectl -n "$NAMESPACE" rollout status deployment cert-manager-cainjector

echo "📄 Creating ClusterIssuer manifest..."

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: $CLUSTER_ISSUER_NAME
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ypf@ornl.gov
    privateKeySecretRef:
      name: $CLUSTER_ISSUER_NAME-account-key
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

echo "✅ cert-manager installed and ClusterIssuer '$CLUSTER_ISSUER_NAME' created."

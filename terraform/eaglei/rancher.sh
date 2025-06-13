#!/bin/bash

set -e

# Configurable variables
NAMESPACE="cattle-system"
HOSTNAME="rancher.anaeleboo.com"
EMAIL="admin@anaeleboo.com"   # update this if needed
REPLICAS=3
# CLUSTER_NAME="eagle-i"

echo "🚀 Creating namespace $NAMESPACE if it doesn't exist..."
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "📦 Adding Rancher Helm repo..."
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

echo "🚀 Installing Rancher with $REPLICAS replicas..."
helm upgrade --install rancher rancher-latest/rancher \
  --namespace $NAMESPACE \
  --set replicas=$REPLICAS \
  --set hostname=$HOSTNAME \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=$EMAIL \
  --set letsEncrypt.ingress.class=nginx

echo "⏳ Waiting for Rancher pods to be ready..."
kubectl rollout status deploy/rancher -n $NAMESPACE

echo "🌐 Rancher should be available at: https://$HOSTNAME"

echo "✅ Done. Now open Rancher UI and rename the cluster to \"$CLUSTER_NAME\" manually in the UI."


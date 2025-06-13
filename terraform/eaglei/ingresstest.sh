#!/bin/bash

set -e

# Configuration
CLUSTER_NAME="eagle-i-default"
REGION="us-east-1"
AWS_ACCOUNT_ID="729855611727"
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
SA_NAMESPACE="kube-system"
SA_NAME="aws-load-balancer-controller"
VERSION="v2.7.1"

export AWS_REGION=$REGION
export AWS_DEFAULT_REGION=$REGION

echo "📄 Downloading IAM policy for AWS Load Balancer Controller..."
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/$VERSION/docs/install/iam_policy.json

echo "🔐 Creating IAM policy (if not exists)..."
if ! aws iam get-policy --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$POLICY_NAME >/dev/null 2>&1; then
  aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document file://iam-policy.json
else
  echo "IAM policy $POLICY_NAME already exists, skipping creation."
fi

echo "🔗 Creating IAM service account via eksctl..."
eksctl create iamserviceaccount \
  --region $REGION \
  --cluster $CLUSTER_NAME \
  --namespace $SA_NAMESPACE \
  --name $SA_NAME \
  --attach-policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$POLICY_NAME \
  --approve \
  --override-existing-serviceaccounts

echo "📦 Adding EKS Helm repo..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

echo "🌐 Getting VPC ID for cluster $CLUSTER_NAME..."
VPC_ID=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text)

echo "🚀 Installing AWS Load Balancer Controller with Helm..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n $SA_NAMESPACE \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=$SA_NAME \
  --set region=$REGION \
  --set vpcId=$VPC_ID \
  --set image.tag="$VERSION"

echo "⏳ Waiting for controller deployment to be ready..."
kubectl rollout status deployment aws-load-balancer-controller -n $SA_NAMESPACE

echo "✅ AWS Load Balancer Controller installed successfully on cluster $CLUSTER_NAME"

#!/bin/bash
set -euo pipefail

# 👉 Update these variables
AWS_ACCOUNT_ID="729855611727"
# REGION="us-east-1"
# CLUSTER_NAME="eagle-i-default"
DOMAIN="anaeleboo.com"
ROLE_NAME="AmazonEKSExternalDNSRole"
POLICY_NAME="ExternalDNSRoute53Policy"
NAMESPACE="kube-system"
SERVICE_ACCOUNT_NAME="external-dns"

echo "🔍 Verifying EKS cluster exists..."
aws eks describe-cluster --region "$REGION" --name "$CLUSTER_NAME" >/dev/null

# OIDC setup
OIDC_PROVIDER_URL=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query "cluster.identity.oidc.issuer" --output text)
OIDC_PROVIDER=$(echo "$OIDC_PROVIDER_URL" | sed -e "s/^https:\/\///")

echo "🔍 Checking if OIDC provider is associated..."
if ! aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[*].Arn" --output text | grep -q "$OIDC_PROVIDER"; then
  echo "🔗 Associating OIDC provider..."
  eksctl utils associate-iam-oidc-provider --region "$REGION" --cluster "$CLUSTER_NAME" --approve
else
  echo "✅ OIDC provider already exists."
fi

# Create IAM policy
cat > externaldns-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets",
        "route53:ListHostedZonesByName"
      ],
      "Resource": "*"
    }
  ]
}
EOF

POLICY_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:policy/$POLICY_NAME"
if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
  echo "🔁 Updating existing IAM policy..."
  VERSIONS=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text)
  for v in $VERSIONS; do aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$v" || true; done
  aws iam create-policy-version --policy-arn "$POLICY_ARN" --policy-document file://externaldns-policy.json --set-as-default
else
  echo "📜 Creating new IAM policy..."
  aws iam create-policy --policy-name "$POLICY_NAME" --policy-document file://externaldns-policy.json
fi

# Create trust policy
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/$OIDC_PROVIDER"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "$OIDC_PROVIDER:sub": "system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT_NAME"
        }
      }
    }
  ]
}
EOF

echo "🔐 Creating or updating IAM role..."
if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://trust-policy.json
else
  echo "ℹ️ Role exists, updating trust policy..."
  aws iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document file://trust-policy.json
fi

echo "🔗 Attaching policy to role..."
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN"

# Kubernetes service account setup
echo "🔧 Creating service account with annotation..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount "$SERVICE_ACCOUNT_NAME" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl annotate serviceaccount "$SERVICE_ACCOUNT_NAME" -n "$NAMESPACE" \
  eks.amazonaws.com/role-arn="arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME" --overwrite

# Helm values
cat > values.yaml <<EOF
provider: aws
aws:
  region: $REGION
domainFilters:
  - $DOMAIN
policy: upsert-only
registry: txt
txtOwnerId: my-identifier

serviceAccount:
  create: false
  name: $SERVICE_ACCOUNT_NAME
EOF

echo "📦 Installing ExternalDNS with Helm..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install externaldns bitnami/external-dns \
  -n "$NAMESPACE" -f values.yaml

echo "✅ ExternalDNS deployed successfully. Verify with:"
echo "kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=external-dns"

#!/bin/bash
cd shared-state
terraform init -upgrade
terraform apply --auto-approve
cd ..

cd eaglei-vpc
terraform init -upgrade
terraform apply --auto-approve
echo "Populate the subnets, vpc with IDs"
./output-topackt.sh
cd ..

cd eaglei
terraform init -upgrade
terraform apply --auto-approve
aws eks --region $(terraform output -raw aws_region) update-kubeconfig --name $(terraform output -raw cluster_full_name)
export CLUSTER_NAME=$(terraform output -raw cluster_full_name)
export REGION=$(terraform output -raw aws_region)
terraform output -raw authconfig | kubectl -n kube-system create -f -
echo "deploy Eternal DNS"
 sleep 60
 ./dns-external.sh
echo "deploy Ingress Controller"
 sleep 120
 ./ingress-controller.sh

echo "deploy cert-manager"
 sleep 10
 ./cert-manager.sh
echo "deploy rancher"
 sleep 10
 ./rancher.sh

cd ..
 

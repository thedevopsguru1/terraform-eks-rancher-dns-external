#!/bin/bash
cd eaglei
terraform init -upgrade
terraform destroy --auto-approve
cd ..

cd eaglei-vpc
terraform init -upgrade
terraform destroy --auto-approve
cd ..






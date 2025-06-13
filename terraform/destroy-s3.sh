cd shared-state
aws s3 rm s3://eagle-i-terraform-state --recursive
aws s3 rm s3://eagle-i-vpc-terraform-state --recursive
aws s3 rb s3://eagle-i-terraform-state --force
aws s3 rb s3://eagle-i-vpc-terraform-state --force
terraform init -upgrade
terraform destroy --auto-approve
cd ..
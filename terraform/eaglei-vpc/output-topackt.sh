#!/bin/bash

# Target tfvars file to write
output_file="../eaglei/terraform.tfvars"
sed -i '' '8,$d' $output_file

terraform output >>$output_file

echo "Terraform outputs appended to $output_file:"
cat "$output_file"

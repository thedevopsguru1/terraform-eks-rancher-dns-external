terraform {
  backend "s3" {
    bucket         = "eagle-i-terraform-state"
    key            = "eagle-i.tfstate"
    region         = "us-east-1"
    use_lockfile   = true 
    encrypt       = true
   
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.31.0"
    }
  }
 
}

data "aws_ssm_parameter" "workers_ami_id" {
  name            = "/aws/service/eks/optimized-ami/1.32/amazon-linux-2/recommended/image_id"
  with_decryption = false
}
provider "aws" {
  region = "us-east-1" # or your preferred AWS region
}
terraform {
  backend "s3" {
    bucket         = "eagle-i-vpc-terraform-state"
    key            = "eagle-i-vpc.tfstate"
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

provider "aws" {
  region = "us-east-1" # or your preferred AWS region
}

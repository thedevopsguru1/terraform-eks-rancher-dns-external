resource "aws_s3_bucket" "clusters_tf_state_s3_bucket" {
  bucket = "${var.clusters_name_prefix}-terraform-state"
 
  
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    Name      = "${var.clusters_name_prefix} S3 Remote Terraform State Store"
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket" "clusters_vpc_tf_state_s3_bucket" {
  bucket = "${var.clusters_name_prefix}-vpc-terraform-state"
  
 
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    Name      = "${var.clusters_name_prefix} VPC S3 Remote Terraform State Store"
    ManagedBy = "terraform"
  }
}

# Add versioning & ACL

#resource "aws_s3_bucket_acl" "clusters_tf_state_s3_bucket" {
#  bucket = aws_s3_bucket.clusters_tf_state_s3_bucket.id
#  acl    = "private"
#}


#resource "aws_s3_bucket_versioning" "versioning_clusters_tf_state_s3_bucket" {
#  bucket = aws_s3_bucket.clusters_tf_state_s3_bucket.id
#  versioning_configuration {
#    status = "Enabled"
#  }
#}


#resource "aws_s3_bucket_acl" "clusters_vpc_tf_state_s3_bucket" {
#  bucket = aws_s3_bucket.clusters_vpc_tf_state_s3_bucket.id
#  acl    = "private"
#}

#resource "aws_s3_bucket_versioning" "versioning_clusters_vpc_tf_state_s3_bucket" {
#  bucket = aws_s3_bucket.clusters_vpc_tf_state_s3_bucket.id
#  versioning_configuration {
#    status = "Enabled"
#  }
#}




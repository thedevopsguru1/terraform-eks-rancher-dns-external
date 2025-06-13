aws_region = "us-east-1"
clusters_name_prefix  = "eagle-i"
cluster_version       = "1.32"
workers_instance_type = "t3.medium"
workers_number_min    = 3
workers_number_max    = 5
workers_storage_size  = 50
private_subnet_ids = [
  "subnet-0e07f736376d4a4bc",
  "subnet-056e17460693439d1",
  "subnet-06cb7626bcddf59e8",
]
public_subnet_ids = [
  "subnet-045640741479862b2",
  "subnet-099e06cc6ac7e13a4",
  "subnet-0cf2a72241915bda9",
]
vpc_id = "vpc-01d7b92b5a64156ed"

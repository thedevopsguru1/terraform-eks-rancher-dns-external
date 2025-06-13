output "aws_region" {
  value = var.aws_region
}

output "cluster_full_name" {
  value = "${var.clusters_name_prefix}-${terraform.workspace}"
}

output "cluster_version" {
  value = var.cluster_version
}

output "cluster_api" {
  value = module.eaglei.cluster_api
}

output "cluster_tag" {
  value = module.eaglei.cluster_tag
}

output "worker_iam_role_arn" {
  value = module.eaglei.worker_iam_role_arn
}

output "authconfig" {
  value = module.eaglei.authconfig
}

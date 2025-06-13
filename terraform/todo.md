1- add keypair 
2- change all packt to eagle-i
tags = merge(
    var.common_tags,
    {
      Name                             = "eks-public-${var.clusters_name_prefix}-${data.aws_availability_zones.availability_zones.names[count.index]}"
      "kubernetes.io/cluster/${var.clusters_name_prefix}" = "owned"
      "kubernetes.io/role/elb"                            = "1"
    },
  )


  aws ec2 create-tags --resources subnet-0a12626a15a175c1d --tags Key=kubernetes.io/cluster/eagle-i,Value=owned --region us-east-1
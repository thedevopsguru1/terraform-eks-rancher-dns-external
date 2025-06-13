locals {
  kubelet_extra_args = <<ARGS
--v=3 \
ARGS

  userdata = <<USERDATA
#!/bin/bash
set -o xtrace

# Install Longhorn dependencies
yum install -y iscsi-initiator-utils nfs-utils open-iscsi curl jq

# Enable and start iSCSI service
systemctl enable iscsid
systemctl start iscsid

# Load required kernel modules
modprobe iscsi_tcp
modprobe br_netfilter

# EKS bootstrap
/etc/eks/bootstrap.sh --b64-cluster-ca "${var.cluster_ca}" --apiserver-endpoint "${var.cluster_endpoint}" \
USERDATA

  workers_userdata = "${local.userdata} --kubelet-extra-args \"${local.kubelet_extra_args}\"  \"${var.cluster_full_name}\""
}

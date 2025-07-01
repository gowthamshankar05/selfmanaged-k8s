
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data

  lifecycle {
    # We are ignoring the data here since we will manage it with the resource below
    # This is only intended to be used in scenarios where the configmap does not exist
    ignore_changes = [data, metadata[0].labels, metadata[0].annotations]
  }
  depends_on = [aws_eks_cluster.eks_cluster, aws_iam_role_policy_attachment.eks_worker_node_policy, aws_iam_role_policy_attachment.eks_cni_policy, aws_iam_role_policy_attachment.eks_container_registry_policy, aws_iam_role_policy_attachment.eks_autoscaling_policy]
}

locals {
  aws_auth_configmap_data = {
    "mapRoles" = jsonencode([
      {
        "rolearn"  = data.terraform_remote_state.resources.outputs.iam_node_role_arn
        "username" = "system:node:{{EC2PrivateDNSName}}"
        "groups"   = ["system:bootstrappers", "system:nodes"]
      },
      {
        "rolearn"  = "arn:aws:iam::717340753727:user/gowtham"
        "username" = "gowtham"
        "groups"   = ["system:masters"]
      }
    ])
  }
}
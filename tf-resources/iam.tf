resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_autoscaling_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_instance_profile" "eks_node_role_profile" {
  name = "${var.cluster_name}-node-profile"
  role = aws_iam_role.eks_node_role.name
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

data "aws_eks_cluster" "this" {
  name = "cbe-blr"
}

data "aws_eks_cluster_auth" "this" {
  name = "cbe-blr"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}


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

  depends_on = [ aws_iam_role.eks_node_role, aws_iam_role_policy_attachment.eks_worker_node_policy, aws_iam_role_policy_attachment.eks_cni_policy, aws_iam_role_policy_attachment.eks_container_registry_policy, aws_iam_role_policy_attachment.eks_autoscaling_policy]
}
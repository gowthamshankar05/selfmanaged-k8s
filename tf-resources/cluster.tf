resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = aws_subnet.eks_subnets[*].id
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}



data "aws_ssm_parameter" "eks_ami" {
  depends_on = [aws_eks_cluster.eks_cluster]
  name       = "/aws/service/eks/optimized-ami/${var.eks_version}/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "eks_nodes" {
  name                   = "${var.cluster_name}-node-template"
  instance_type          = "t2.micro"
  image_id               = data.aws_ssm_parameter.eks_ami.value
  vpc_security_group_ids = [aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.eks_node_role_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -o xtrace
    /etc/eks/bootstrap.sh ${var.cluster_name}
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-node"
    }
  }
}

resource "aws_autoscaling_group" "eks_nodes" {
  name                = "${var.cluster_name}-nodes"
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  target_group_arns   = []
  vpc_zone_identifier = aws_subnet.eks_subnets[*].id

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.eks_vpc.id
}

output "subnet_ids" {
  description = "IDs of the created subnets"
  value       = aws_subnet.eks_subnets[*].id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.eks_cluster_role.name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "node_group_name" {
  description = "Name of the EKS node group"
  value       = aws_autoscaling_group.eks_nodes.name
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks get-token --cluster-name ${aws_eks_cluster.eks_cluster.name} | kubectl apply -f -"
}
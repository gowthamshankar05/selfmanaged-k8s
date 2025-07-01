output "iam_node_role_arn" {
  description = "ARN of the IAM role for EKS nodes"
  value       = aws_iam_role.eks_node_role.arn
}
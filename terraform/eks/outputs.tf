output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS Kubernetes API endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS Kubernetes version."
  value       = module.eks.cluster_version
}

output "cluster_oidc_provider_arn" {
  description = "EKS OIDC provider ARN."
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private worker subnet IDs."
  value       = module.vpc.private_subnets
}

output "control_plane_subnet_ids" {
  description = "Dedicated EKS control-plane subnet IDs."
  value       = module.vpc.intra_subnets
}

output "ecr_repository_url" {
  description = "ECR repository URL."
  value       = aws_ecr_repository.go_web_app.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN."
  value       = aws_ecr_repository.go_web_app.arn
}

output "cloudwatch_log_group_name" {
  description = "EKS control-plane CloudWatch log group."
  value       = module.eks.cloudwatch_log_group_name
}

output "github_actions_role_arn" {
  description = "IAM role assumed by GitHub Actions through OIDC."
  value       = aws_iam_role.github_actions_ecr.arn
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_oidc_subject" {
  description = "OIDC subject trusted by the GitHub Actions role."
  value       = local.github_oidc_subject
}

variable "region" {
  description = "AWS region where the EKS platform will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Logical project name."
  type        = string
  default     = "go-web-app-sre"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version."
  type        = string
  default     = "1.36"
}

variable "vpc_cidr" {
  description = "CIDR block for the EKS VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones."
  type        = number
  default     = 4

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be 2 or 4."
  }
}

variable "admin_cidr" {
  description = "Public IPv4 CIDR allowed to access the EKS Kubernetes API endpoint. Use x.x.x.x/32."
  type        = string
}

variable "single_nat_gateway" {
  description = "Use one NAT Gateway for the lab. Set false for one NAT Gateway per AZ."
  type        = bool
  default     = true
}

variable "ecr_force_delete" {
  description = "Allow Terraform to delete ECR repositories even when images exist. Useful for a lab."
  type        = bool
  default     = true
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the general managed node group"
  type        = number
  default     = 3
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the general managed node group"
  type        = number
  default     = 3
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the general managed node group"
  type        = number
  default     = 4
}

variable "github_owner" {
  description = "GitHub account or organization that owns the application repository."
  type        = string
}

variable "github_owner_id" {
  description = "Immutable GitHub owner ID."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name."
  type        = string
}

variable "github_repository_id" {
  description = "Immutable GitHub repository ID."
  type        = string
}

variable "github_branch" {
  description = "GitHub branch trusted to publish container images."
  type        = string
  default     = "main"
}

variable "github_use_immutable_oidc_subjects" {
  description = "Use GitHub immutable owner/repository IDs in the OIDC subject claim."
  type        = bool
  default     = true
}

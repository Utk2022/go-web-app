variable "region" {
  description = "AWS region where the Terraform state bucket will be created."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as the prefix for the Terraform state bucket."
  type        = string
  default     = "go-web-app-sre"
}

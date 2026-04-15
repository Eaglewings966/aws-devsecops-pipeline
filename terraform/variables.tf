variable "aws_region" {
  description = "AWS region for ECR repository"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "devsecops-pipeline"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "owner" {
  description = "Owner tag value for all resources"
  type        = string
  default     = "emmanuel-ubani"
}

variable "ecr_repo_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "devops-demo-app"
}

variable "image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 10
}

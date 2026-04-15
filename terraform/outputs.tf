output "ecr_repository_url" {
  description = "ECR repository URL for Docker push"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.app.arn
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC"
  value       = aws_iam_role.github_actions.arn
}

output "ecr_login_command" {
  description = "Command to authenticate Docker with ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}"
}

output "github_secrets_to_set" {
  description = "GitHub Actions secrets required for this pipeline"
  value = {
    AWS_ROLE_ARN   = aws_iam_role.github_actions.arn
    ECR_REGISTRY   = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
    ECR_REPOSITORY = var.ecr_repo_name
  }
}

output "destroy_command" {
  description = "Command to destroy all resources"
  value       = "terraform destroy --auto-approve"
}

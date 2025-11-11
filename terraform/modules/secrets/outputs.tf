# ============================================================================
# Secrets Module Outputs
# ============================================================================
# Export secret ARNs for use in other modules (Lambda functions, etc.)

output "github_token_secret_arn" {
  description = "ARN of the GitHub Personal Access Token secret"
  value       = aws_secretsmanager_secret.github_token.arn
}

output "youtube_api_key_secret_arn" {
  description = "ARN of the YouTube Data API key secret"
  value       = aws_secretsmanager_secret.youtube_api_key.arn
}

output "ai_api_key_secret_arn" {
  description = "ARN of the Anthropic Claude API key secret"
  value       = aws_secretsmanager_secret.ai_api_key.arn
}

output "github_token_secret_name" {
  description = "Name of the GitHub token secret (for GitHub Actions updates)"
  value       = aws_secretsmanager_secret.github_token.name
}

output "youtube_api_key_secret_name" {
  description = "Name of the YouTube API key secret (for GitHub Actions updates)"
  value       = aws_secretsmanager_secret.youtube_api_key.name
}

output "ai_api_key_secret_name" {
  description = "Name of the AI API key secret (for GitHub Actions updates)"
  value       = aws_secretsmanager_secret.ai_api_key.name
}

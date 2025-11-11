# ============================================================================
# Terraform Outputs
# ============================================================================
# These outputs provide important information about deployed resources
# Access them with: terraform output <output_name>

# ----------------------------------------------------------------------------
# Frontend Outputs
# ----------------------------------------------------------------------------

output "frontend_bucket_name" {
  description = "S3 bucket name hosting the React frontend"
  value       = module.frontend.bucket_name
}

output "frontend_url" {
  description = "CloudFront distribution URL (your public website URL)"
  value       = module.frontend.cloudfront_url
}

output "website_url" {
  description = "Custom domain website URL (main access point)"
  value       = module.frontend.website_url
}

output "website_url_www" {
  description = "Custom domain website URL with www subdomain"
  value       = module.frontend.website_url_www
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = module.frontend.cloudfront_distribution_id
}

output "certificate_arn" {
  description = "ACM certificate ARN for the custom domain"
  value       = module.frontend.certificate_arn
}

# ----------------------------------------------------------------------------
# API Outputs
# ----------------------------------------------------------------------------

output "api_endpoint" {
  description = "API Gateway endpoint URL (for frontend configuration)"
  value       = module.api.api_endpoint
}

# ----------------------------------------------------------------------------
# Database Outputs
# ----------------------------------------------------------------------------

output "github_repos_table_name" {
  description = "DynamoDB table name for GitHub repositories"
  value       = module.database.github_repos_table_name
}

output "medium_posts_table_name" {
  description = "DynamoDB table name for Medium posts"
  value       = module.database.medium_posts_table_name
}

output "youtube_videos_table_name" {
  description = "DynamoDB table name for YouTube videos"
  value       = module.database.youtube_videos_table_name
}

# ----------------------------------------------------------------------------
# Secrets Outputs (for GitHub Actions)
# ----------------------------------------------------------------------------

output "github_token_secret_name" {
  description = "Name of GitHub token secret in AWS Secrets Manager"
  value       = module.secrets.github_token_secret_name
}

output "youtube_api_key_secret_name" {
  description = "Name of YouTube API key secret in AWS Secrets Manager"
  value       = module.secrets.youtube_api_key_secret_name
}

output "ai_api_key_secret_name" {
  description = "Name of AI API key secret in AWS Secrets Manager"
  value       = module.secrets.ai_api_key_secret_name
}

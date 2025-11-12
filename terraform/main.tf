# ============================================================================
# Main Terraform Configuration
# ============================================================================
# This file orchestrates all infrastructure modules for the Portfolio Aggregator
# Modules are deployed in the following order:
# 1. Frontend (S3 + CloudFront)
# 2. Database (DynamoDB tables)
# 3. API (Lambda + API Gateway)
# 4. Sync (Lambda functions + EventBridge schedules)

# ----------------------------------------------------------------------------
# Local Values
# ----------------------------------------------------------------------------
# Define common tags to be applied across all modules

locals {
  common_tags = {
    Project     = var.project_name # Used for cost allocation and resource grouping
    Environment = var.environment  # Distinguishes prod/staging/dev resources
  }
}

# ============================================================================
# Secrets Module
# ============================================================================
# Creates AWS Secrets Manager secrets for API keys
# Secrets are created with placeholders and populated by GitHub Actions
# This must be deployed first as other modules depend on secret ARNs

module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

# ============================================================================
# Frontend Module
# ============================================================================
# Deploys S3 bucket for static website hosting and CloudFront CDN distribution
# Handles: React app hosting, HTTPS redirection, global content delivery
# Custom domain: Uses Route 53 for DNS and ACM for SSL/TLS certificate

module "frontend" {
  source = "./modules/frontend"

  # Module configuration
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Custom domain configuration
  domain_name     = var.domain_name     # e.g., vloidcloudtech.com
  route53_zone_id = var.route53_zone_id # Route 53 hosted zone ID

  # Pass provider configuration for us-east-1 (required for ACM with CloudFront)
  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}

# ============================================================================
# Database Module
# ============================================================================
# Creates DynamoDB tables for storing aggregated content
# Tables:
#   - github_repos: GitHub repositories with AI summaries
#   - medium_posts: Medium blog posts
#   - youtube_videos: YouTube videos with metadata
#   - sync_metadata: Tracks sync status and timestamps

module "database" {
  source = "./modules/database"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

# ============================================================================
# API Module
# ============================================================================
# Deploys API Gateway and Lambda function for serving content to frontend
# Endpoints:
#   - GET /api/repos: List all GitHub repositories
#   - GET /api/repos/{id}: Get single repository with summaries
#   - GET /api/posts: List all Medium posts
#   - GET /api/videos: List all YouTube videos

module "api" {
  source = "./modules/api"

  # Module configuration
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Lambda layer ARN from sync module
  shared_layer_arn = module.sync.shared_layer_arn

  # DynamoDB table names passed from database module
  github_repos_table_name   = module.database.github_repos_table_name
  github_repos_table_arn    = module.database.github_repos_table_arn
  medium_posts_table_name   = module.database.medium_posts_table_name
  medium_posts_table_arn    = module.database.medium_posts_table_arn
  youtube_videos_table_name = module.database.youtube_videos_table_name
  youtube_videos_table_arn  = module.database.youtube_videos_table_arn
  sync_metadata_table_name  = module.database.sync_metadata_table_name
  sync_metadata_table_arn   = module.database.sync_metadata_table_arn
}

# ============================================================================
# Sync Module
# ============================================================================
# Deploys Lambda functions for syncing content from external platforms
# Functions:
#   - github_sync: Fetches repos and generates AI summaries (runs every 12 hours)
#   - medium_sync: Fetches posts from RSS feed (runs every 12 hours)
#   - youtube_sync: Fetches videos via YouTube API (runs every 12 hours)

module "sync" {
  source = "./modules/sync"

  # Module configuration
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  # Content source identifiers
  github_username    = var.github_username
  medium_username    = var.medium_username
  youtube_channel_id = var.youtube_channel_id

  # AWS Secrets Manager ARNs from secrets module
  # Secrets are auto-populated by GitHub Actions during deployment
  github_token_secret_arn    = module.secrets.github_token_secret_arn
  youtube_api_key_secret_arn = module.secrets.youtube_api_key_secret_arn
  ai_api_key_secret_arn      = module.secrets.ai_api_key_secret_arn

  # DynamoDB table names and ARNs passed from database module
  github_repos_table_name   = module.database.github_repos_table_name
  github_repos_table_arn    = module.database.github_repos_table_arn
  medium_posts_table_name   = module.database.medium_posts_table_name
  medium_posts_table_arn    = module.database.medium_posts_table_arn
  youtube_videos_table_name = module.database.youtube_videos_table_name
  youtube_videos_table_arn  = module.database.youtube_videos_table_arn
  sync_metadata_table_name  = module.database.sync_metadata_table_name
  sync_metadata_table_arn   = module.database.sync_metadata_table_arn
}

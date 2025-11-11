# ============================================================================
# AWS Secrets Manager Resources
# ============================================================================
# This module creates empty secrets in AWS Secrets Manager that will be
# populated by GitHub Actions during CI/CD deployment.
#
# Why GitHub Secrets → AWS Secrets Manager?
# 1. Centralized secret management in AWS
# 2. Lambda functions can access secrets via IAM roles
# 3. Secrets can be rotated without code changes
# 4. CloudWatch logs track secret access
# 5. GitHub Actions populates secrets automatically during deployment

# ----------------------------------------------------------------------------
# GitHub Personal Access Token Secret
# ----------------------------------------------------------------------------
# This secret stores the GitHub PAT used to fetch repositories
# Required GitHub permissions: repo (read)

resource "aws_secretsmanager_secret" "github_token" {
  name        = "${var.project_name}-github-token-${var.environment}"
  description = "GitHub Personal Access Token for repository access (populated by GitHub Actions)"

  # Recovery window for accidental deletion (0-30 days)
  # Set to 0 for immediate deletion (useful for dev/testing)
  recovery_window_in_days = var.environment == "production" ? 30 : 0

  tags = merge(
    var.tags,
    {
      Name        = "GitHub Token"
      SecretType  = "API Key"
      PopulatedBy = "GitHub Actions"
    }
  )
}

# Initial version with placeholder value
# GitHub Actions will update this with actual token
resource "aws_secretsmanager_secret_version" "github_token" {
  secret_id = aws_secretsmanager_secret.github_token.id

  # Placeholder JSON structure
  # Format: {"token": "ghp_XXXXX"}
  secret_string = jsonencode({
    token = "PLACEHOLDER_TO_BE_UPDATED_BY_GITHUB_ACTIONS"
  })

  # Lifecycle policy to prevent Terraform from reverting GitHub Actions updates
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# ----------------------------------------------------------------------------
# YouTube Data API Key Secret
# ----------------------------------------------------------------------------
# This secret stores the YouTube Data API v3 key for fetching videos
# Get key from: https://console.cloud.google.com/apis/credentials

resource "aws_secretsmanager_secret" "youtube_api_key" {
  name        = "${var.project_name}-youtube-key-${var.environment}"
  description = "YouTube Data API v3 key for video fetching (populated by GitHub Actions)"

  recovery_window_in_days = var.environment == "production" ? 30 : 0

  tags = merge(
    var.tags,
    {
      Name        = "YouTube API Key"
      SecretType  = "API Key"
      PopulatedBy = "GitHub Actions"
    }
  )
}

# Initial version with placeholder
resource "aws_secretsmanager_secret_version" "youtube_api_key" {
  secret_id = aws_secretsmanager_secret.youtube_api_key.id

  # Placeholder JSON structure
  # Format: {"api_key": "AIzaSyXXXXX"}
  secret_string = jsonencode({
    api_key = "PLACEHOLDER_TO_BE_UPDATED_BY_GITHUB_ACTIONS"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# ----------------------------------------------------------------------------
# Anthropic Claude API Key Secret
# ----------------------------------------------------------------------------
# This secret stores the Anthropic API key for Claude AI summaries
# Get key from: https://console.anthropic.com/

resource "aws_secretsmanager_secret" "ai_api_key" {
  name        = "${var.project_name}-ai-key-${var.environment}"
  description = "Anthropic Claude API key for AI summaries (populated by GitHub Actions)"

  recovery_window_in_days = var.environment == "production" ? 30 : 0

  tags = merge(
    var.tags,
    {
      Name        = "Anthropic API Key"
      SecretType  = "API Key"
      PopulatedBy = "GitHub Actions"
    }
  )
}

# Initial version with placeholder
resource "aws_secretsmanager_secret_version" "ai_api_key" {
  secret_id = aws_secretsmanager_secret.ai_api_key.id

  # Placeholder JSON structure
  # Format: {"api_key": "sk-ant-XXXXX"}
  secret_string = jsonencode({
    api_key = "PLACEHOLDER_TO_BE_UPDATED_BY_GITHUB_ACTIONS"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

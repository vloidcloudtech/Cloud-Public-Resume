# ============================================================================
# Terraform Variables
# ============================================================================
# This file defines all input variables used across the Terraform configuration
# Values can be set in terraform.tfvars or passed via command line

# ----------------------------------------------------------------------------
# Infrastructure Configuration Variables
# ----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1" # US East (N. Virginia) - lowest cost region
}

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production" # Default to production environment
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "portfolio-aggregator" # Base name for all resources
}

# ----------------------------------------------------------------------------
# Content Source Configuration Variables
# ----------------------------------------------------------------------------

variable "github_username" {
  description = "GitHub username for fetching repositories"
  type        = string
  # No default - must be provided by user
}

variable "medium_username" {
  description = "Medium username for fetching blog posts via RSS"
  type        = string
  # No default - must be provided by user
}

variable "youtube_channel_id" {
  description = "YouTube channel ID for fetching videos (found in channel URL)"
  type        = string
  # No default - must be provided by user
}

# ----------------------------------------------------------------------------
# Note: API Keys Configuration
# ----------------------------------------------------------------------------
# API keys are stored as GitHub Secrets and automatically deployed to
# AWS Secrets Manager via GitHub Actions. No manual secret creation needed!
#
# Required GitHub Secrets (configure in repository settings):
#   - GITHUB_TOKEN_PAT: GitHub Personal Access Token (repo:read permission)
#   - YOUTUBE_API_KEY: YouTube Data API v3 key
#   - ANTHROPIC_API_KEY: Anthropic Claude API key
#
# GitHub Actions automatically:
#   1. Creates AWS Secrets Manager secrets via Terraform
#   2. Populates them with values from GitHub Secrets
#   3. Updates secrets on every deployment
#
# Get API keys from:
#   - GitHub: https://github.com/settings/tokens (needs repo:read scope)
#   - YouTube: https://console.cloud.google.com/apis/credentials
#   - Anthropic: https://console.anthropic.com/

# ----------------------------------------------------------------------------
# Custom Domain Configuration Variables
# ----------------------------------------------------------------------------

variable "domain_name" {
  description = "Custom domain name for the website (e.g., vloidcloudtech.com)"
  type        = string
  # No default - must be provided by user
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for the domain (find in Route 53 console)"
  type        = string
  # No default - must be provided by user
  # Note: The hosted zone must already exist in Route 53
  # Create it via AWS Console or import existing domain
}

# ============================================================================
# Terraform Configuration
# ============================================================================
# This file configures the Terraform version and AWS provider settings
# for the Portfolio Aggregator infrastructure

terraform {
  # Require Terraform version 1.0 or higher for compatibility
  required_version = ">= 1.0"

  # Specify required provider versions
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Official AWS provider
      version = "~> 5.0"        # Use AWS provider version 5.x
    }
  }
}

# ============================================================================
# AWS Provider Configuration
# ============================================================================
# Configure the AWS provider with region and default tags

provider "aws" {
  region = var.aws_region # AWS region from variables (default: us-east-1)

  # Apply these tags to all resources created by Terraform
  default_tags {
    tags = {
      Project     = "portfolio-aggregator" # Project identifier
      Environment = var.environment        # Environment (production/staging/dev)
      ManagedBy   = "terraform"            # Indicates infrastructure is managed by Terraform
    }
  }
}

# ============================================================================
# AWS Provider Configuration for us-east-1 (ACM Certificates)
# ============================================================================
# CloudFront requires ACM certificates to be created in us-east-1 region
# This provider alias is used by the frontend module for certificate creation

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  # Apply the same default tags as the main provider
  default_tags {
    tags = {
      Project     = "portfolio-aggregator"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

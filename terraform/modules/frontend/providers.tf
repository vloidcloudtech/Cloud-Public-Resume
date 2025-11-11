# ============================================================================
# Provider Configuration for Frontend Module
# ============================================================================
# ACM certificates for CloudFront MUST be created in us-east-1 region
# This requires an additional provider alias

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

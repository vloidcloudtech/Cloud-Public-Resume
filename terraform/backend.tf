# ============================================================================
# Terraform State Backend Configuration (S3)
# ============================================================================
# This backend configuration stores Terraform state in S3 with versioning.
#
# ENABLED: Remote backend is now active for all deployments.
# State file location: s3://vloidcloudtech-terraform-state/portfolio-aggregator/terraform.tfstate
# ============================================================================

terraform {
  backend "s3" {
    bucket  = "vloidcloudtech-terraform-state"
    key     = "portfolio-aggregator/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

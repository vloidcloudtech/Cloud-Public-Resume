# ============================================================================
# Terraform State Backend Configuration (S3 with Native State Locking)
# ============================================================================
# Uses S3's native state locking feature (available since AWS provider >= 5.0)
# No DynamoDB table needed!
#
# IMPORTANT: For first deployment:
#   1. Comment out this entire backend block
#   2. Run terraform apply to create infrastructure
#   3. Manually create the S3 bucket: vloidcloudtech-terraform-state
#   4. Enable versioning on the bucket
#   5. Uncomment this backend configuration
#   6. Run: terraform init -migrate-state
#
# For now: COMMENT OUT the backend block below for first deployment
# ============================================================================

terraform {
  backend "s3" {
    bucket  = "vloidcloudtech-terraform-state"
    key     = "portfolio-aggregator/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
#
#     # S3 native state locking (no DynamoDB needed)
#     # Requires AWS provider >= 5.0
    use_lockfile = true
  }
}

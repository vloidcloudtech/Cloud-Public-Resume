#!/bin/bash
# Import existing CloudWatch Log Groups into Terraform state
# Run this once before deploying the updated Terraform configuration

cd terraform

echo "Importing existing CloudWatch Log Groups..."

terraform import module.sync.aws_cloudwatch_log_group.github_sync /aws/lambda/portfolio-aggregator-github-sync-production
terraform import module.sync.aws_cloudwatch_log_group.medium_sync /aws/lambda/portfolio-aggregator-medium-sync-production
terraform import module.sync.aws_cloudwatch_log_group.youtube_sync /aws/lambda/portfolio-aggregator-youtube-sync-production

echo "Import complete!"
echo "Now you can run: terraform apply"

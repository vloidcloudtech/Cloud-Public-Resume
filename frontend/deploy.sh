#!/bin/bash

set -e

echo "Building frontend..."

# Install dependencies
npm install

# Build for production
npm run build

echo "✓ Frontend built successfully!"
echo ""
echo "Deploying to S3..."

# Get bucket name from Terraform output
BUCKET_NAME=$(cd ../terraform && terraform output -raw frontend_bucket_name)

# Sync to S3 (Vite builds to dist/ directory, not build/)
aws s3 sync dist/ s3://$BUCKET_NAME --delete

echo "✓ Deployed to S3!"
echo ""
echo "Invalidating CloudFront cache..."

# Get distribution ID
DIST_ID=$(cd ../terraform && terraform output -raw cloudfront_distribution_id)

# Create invalidation
aws cloudfront create-invalidation \
    --distribution-id $DIST_ID \
    --paths "/*"

echo "✓ CloudFront cache invalidated!"
echo ""
echo "🚀 Deployment complete!"

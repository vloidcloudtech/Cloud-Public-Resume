#!/bin/bash

set -e

echo "Deploying Lambda functions..."

# Array of Lambda function directories
FUNCTIONS=("github_sync" "medium_sync" "youtube_sync" "api_handler")

for FUNCTION in "${FUNCTIONS[@]}"; do
    echo "Building $FUNCTION..."

    cd lambda_functions/$FUNCTION

    # Install dependencies
    pip install -r requirements.txt -t package/

    # Copy handler
    cp handler.py package/

    # Create deployment package
    cd package
    zip -r ../deployment.zip .
    cd ..

    # Clean up
    rm -rf package

    echo "✓ Built $FUNCTION"
    cd ../..
done

# Create Lambda layer for shared code
echo "Building shared layer..."
cd shared
mkdir -p python
cp *.py python/
zip -r ../layer.zip python
rm -rf python
cd ..

echo "✓ All Lambda functions built successfully!"
echo ""
echo "Now run: terraform apply"

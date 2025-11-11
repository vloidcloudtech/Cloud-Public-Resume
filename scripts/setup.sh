#!/bin/bash

set -e

echo "🚀 Setting up Portfolio Aggregator..."
echo ""

# Check prerequisites
echo "Checking prerequisites..."
command -v terraform >/dev/null 2>&1 || { echo "Error: terraform not installed"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "Error: aws-cli not installed"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Error: node not installed"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 not installed"; exit 1; }

echo "✓ All prerequisites installed"
echo ""

# Configure AWS CLI
echo "Configuring AWS CLI..."
aws configure

echo ""
echo "Creating Secrets Manager secrets..."

# Prompt for API keys
read -p "Enter GitHub Personal Access Token: " GITHUB_TOKEN
read -p "Enter YouTube API Key: " YOUTUBE_KEY
read -p "Enter AI API Key (Anthropic/OpenAI): " AI_KEY

# Create secrets
aws secretsmanager create-secret \
    --name portfolio-aggregator-github-token \
    --secret-string "{\"token\":\"$GITHUB_TOKEN\"}"

aws secretsmanager create-secret \
    --name portfolio-aggregator-youtube-key \
    --secret-string "{\"api_key\":\"$YOUTUBE_KEY\"}"

aws secretsmanager create-secret \
    --name portfolio-aggregator-ai-key \
    --secret-string "{\"api_key\":\"$AI_KEY\"}"

echo "✓ Secrets created"
echo ""

# Initialize Terraform
echo "Initializing Terraform..."
cd terraform
terraform init

echo "✓ Terraform initialized"
echo ""

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update terraform/terraform.tfvars with your usernames"
echo "2. Run: terraform plan"
echo "3. Run: terraform apply"
echo "4. Run: cd ../frontend && npm install"

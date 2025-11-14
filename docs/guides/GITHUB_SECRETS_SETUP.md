# GitHub Secrets Setup Guide

## Overview

This project uses **GitHub Secrets** to manage API keys and credentials securely. The workflow automatically deploys secrets from GitHub to AWS Secrets Manager during CI/CD deployment.

## Why GitHub Secrets → AWS Secrets Manager?

This two-tier approach provides:

1. **Security**: API keys never stored in code or Terraform files
2. **Automation**: GitHub Actions automatically updates AWS secrets
3. **Version Control**: Secret changes tracked through GitHub (values hidden)
4. **Easy Rotation**: Update GitHub secrets, push to trigger redeployment
5. **Centralized Management**: AWS Lambda functions read from Secrets Manager

## Architecture Flow

```
GitHub Secrets (in repo settings)
        ↓
GitHub Actions Workflow (on push to main)
        ↓
AWS Secrets Manager (created by Terraform)
        ↓
Lambda Functions (read secrets via IAM)
```

## Required GitHub Secrets

Navigate to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

### AWS Credentials

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key | [AWS IAM Console](https://console.aws.amazon.com/iam/) → Users → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key | Created with access key (shown once) |

**Required IAM Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:*",
        "lambda:*",
        "apigateway:*",
        "s3:*",
        "cloudfront:*",
        "dynamodb:*",
        "iam:*",
        "events:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### API Keys

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `GH_PERSONAL_ACCESS_TOKEN` | GitHub Personal Access Token | [GitHub Settings](https://github.com/settings/tokens) → Generate new token (classic) |
| `YOUTUBE_API_KEY` | YouTube Data API v3 key | [Google Cloud Console](https://console.cloud.google.com/apis/credentials) |
| `ANTHROPIC_API_KEY` | Anthropic Claude API key | [Anthropic Console](https://console.anthropic.com/) |

**Note:** GitHub doesn't allow secret names starting with `GITHUB_`, so we use `GH_` prefix instead.

### Content Source Identifiers

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `GH_USERNAME` | Your GitHub username | `vloidcloudtech` |
| `MEDIUM_USERNAME` | Your Medium username | `@vloidcloudtech` |
| `YOUTUBE_CHANNEL_ID` | Your YouTube channel ID | `UCxxxxxxxxxxxxxxxxxxxxx` |

## Step-by-Step Setup

### 1. Create GitHub Personal Access Token

1. Go to [GitHub Settings → Tokens](https://github.com/settings/tokens)
2. Click **Generate new token (classic)**
3. Name it: `VloidCloudTech Portfolio`
4. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `public_repo` (Access public repositories)
5. Click **Generate token**
6. **Copy the token immediately** (shown only once)
7. Add to GitHub Secrets as `GH_PERSONAL_ACCESS_TOKEN`

**Important:** GitHub restricts secret names from starting with `GITHUB_`, so we use `GH_PERSONAL_ACCESS_TOKEN` instead.

### 2. Get YouTube Data API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable **YouTube Data API v3**:
   - Navigation menu → APIs & Services → Library
   - Search "YouTube Data API v3"
   - Click Enable
4. Create credentials:
   - APIs & Services → Credentials
   - Create Credentials → API key
   - Copy the key
5. Add to GitHub Secrets as `YOUTUBE_API_KEY`

**Find your YouTube Channel ID:**
- Go to [YouTube Studio](https://studio.youtube.com/)
- Settings → Channel → Advanced settings
- Copy the Channel ID

### 3. Get Anthropic API Key

1. Go to [Anthropic Console](https://console.anthropic.com/)
2. Sign up or log in
3. Navigate to API Keys
4. Click **Create Key**
5. Name it: `Portfolio Aggregator`
6. Copy the key (starts with `sk-ant-`)
7. Add to GitHub Secrets as `ANTHROPIC_API_KEY`

### 4. Add All Secrets to GitHub

1. Navigate to your repository on GitHub
2. Settings → Secrets and variables → Actions
3. Click **New repository secret** for each:

```bash
# AWS Credentials
AWS_ACCESS_KEY_ID = AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# API Keys
GITHUB_TOKEN_PAT = ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
YOUTUBE_API_KEY = AIzaSyXxxxxxxxxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY = sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Content Sources
GITHUB_USERNAME = your-github-username
MEDIUM_USERNAME = your-medium-username
YOUTUBE_CHANNEL_ID = UCxxxxxxxxxxxxxxxxxxxxx
```

## How It Works

### During Deployment

When you push to main branch, GitHub Actions:

1. **Terraform Apply**
   - Creates AWS Secrets Manager secrets (with placeholders)
   - Deploys all infrastructure (S3, Lambda, DynamoDB, etc.)
   - Outputs secret names

2. **Populate Secrets Job**
   - Reads GitHub Secrets
   - Updates AWS Secrets Manager with actual API keys
   - Uses AWS CLI `put-secret-value` command

3. **Deploy Backend**
   - Builds Lambda functions
   - Deploys to AWS
   - Functions can now read secrets from Secrets Manager

4. **Deploy Frontend**
   - Builds React app
   - Uploads to S3
   - Invalidates CloudFront cache

### Secret Update Process

```yaml
# In GitHub Actions workflow
- name: Update GitHub Token Secret
  run: |
    aws secretsmanager put-secret-value \
      --secret-id portfolio-aggregator-github-token-production \
      --secret-string '{"token":"${{ secrets.GITHUB_TOKEN_PAT }}"}'
```

### Lambda Functions Read Secrets

```python
# In Lambda function
import boto3
import json

def get_secret(secret_arn):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_arn)
    return json.loads(response['SecretString'])

# Usage
github_secret = get_secret(os.environ['GITHUB_TOKEN_SECRET'])
github_token = github_secret['token']
```

## Rotating Secrets

To rotate an API key:

1. Generate new key from the service (GitHub, YouTube, Anthropic)
2. Update the GitHub Secret with new value
3. Commit any code change or manually trigger workflow
4. GitHub Actions will automatically update AWS Secrets Manager
5. Lambda functions will use new key on next invocation

## Security Best Practices

### ✅ DO

- Use GitHub Secrets for all sensitive values
- Rotate API keys every 90 days
- Use minimal IAM permissions
- Enable MFA on AWS account
- Review CloudWatch logs for unauthorized access

### ❌ DON'T

- Never commit API keys to code
- Don't share secrets in Slack/email
- Avoid using root AWS credentials
- Don't store secrets in Terraform files
- Never log full secret values

## Troubleshooting

### Secret Not Found Error

```
Error: ResourceNotFoundException: Secrets Manager can't find the specified secret
```

**Solution**: Ensure Terraform has been applied first to create the secrets.

### Permission Denied

```
Error: AccessDeniedException: User is not authorized to perform: secretsmanager:GetSecretValue
```

**Solution**: Check Lambda IAM role has `secretsmanager:GetSecretValue` permission.

### Invalid Secret Format

```
Error: JSONDecodeError: Expecting property name enclosed in double quotes
```

**Solution**: Secrets must be valid JSON. Check format: `{"key": "value"}`

## Verifying Secrets

After deployment, verify secrets are populated:

```bash
# List all secrets
aws secretsmanager list-secrets --query 'SecretList[?Name contains `portfolio-aggregator`]'

# Get secret value (use with caution in production)
aws secretsmanager get-secret-value \
  --secret-id portfolio-aggregator-github-token-production \
  --query SecretString \
  --output text
```

## Cost

AWS Secrets Manager pricing:
- **Secrets storage**: $0.40 per secret per month
- **API calls**: $0.05 per 10,000 API calls
- **Total**: ~$1.60/month for 4 secrets (minimal API calls)

## Next Steps

1. ✅ Set up all GitHub Secrets
2. ✅ Push code to main branch
3. ✅ Watch GitHub Actions deploy
4. ✅ Verify secrets in AWS Console
5. ✅ Test Lambda functions
6. ✅ Access your portfolio!

## Support

If you encounter issues:
1. Check GitHub Actions logs
2. Review CloudWatch Logs
3. Verify IAM permissions
4. Ensure secret JSON format is correct
5. Check Terraform outputs for secret names

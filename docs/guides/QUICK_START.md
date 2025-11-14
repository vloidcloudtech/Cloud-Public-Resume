# Quick Start Guide - Cloud Public Resume

## 🚀 Deploy Your Portfolio in 4 Steps

### Prerequisites
- ✅ AWS Account
- ✅ Domain purchased: vloidcloudtech.com
- ✅ GitHub account
- ✅ API keys: GitHub, YouTube, Anthropic

---

## Step 1: Configure Route 53 (One-time setup)

### If domain is from external registrar (GoDaddy, Namecheap, etc.):

1. **Create Route 53 Hosted Zone**:
   ```bash
   aws route53 create-hosted-zone \
     --name vloidcloudtech.com \
     --caller-reference $(date +%s)
   ```

2. **Get nameservers**:
   ```bash
   aws route53 list-hosted-zones \
     --query 'HostedZones[?Name==`vloidcloudtech.com.`]'
   ```

3. **Update nameservers at your domain registrar** with the 4 Route 53 nameservers

4. **Wait 1-48 hours for DNS propagation**

### If domain is already in Route 53:
✅ Skip to Step 2!

---

## Step 2: Configure Terraform Variables

1. **Copy example file**:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars**:
   ```hcl
   # Infrastructure
   aws_region     = "us-east-1"
   environment    = "production"
   project_name   = "portfolio-aggregator"

   # Content Sources
   github_username    = "YOUR_GITHUB_USERNAME"
   medium_username    = "YOUR_MEDIUM_USERNAME"
   youtube_channel_id = "YOUR_YOUTUBE_CHANNEL_ID"

   # Custom Domain
   domain_name      = "vloidcloudtech.com"
   route53_zone_id  = "Z1234567890ABC"  # Get from Route 53 console
   ```

3. **Save file**

---

## Step 3: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:

### AWS Credentials
- `AWS_ACCESS_KEY_ID` = Your AWS access key
- `AWS_SECRET_ACCESS_KEY` = Your AWS secret key

### API Keys
- `GH_PERSONAL_ACCESS_TOKEN` = GitHub Personal Access Token ([create here](https://github.com/settings/tokens))
- `YOUTUBE_API_KEY` = YouTube Data API v3 key ([create here](https://console.cloud.google.com/apis/credentials))
- `ANTHROPIC_API_KEY` = Anthropic Claude API key ([create here](https://console.anthropic.com/))

### Content Sources
- `GH_USERNAME` = Your GitHub username (e.g., `vloidcloudtech`)
- `MEDIUM_USERNAME` = Your Medium username (e.g., `@vloidcloudtech`)
- `YOUTUBE_CHANNEL_ID` = Your YouTube channel ID

**Important:** GitHub doesn't allow secret names starting with `GITHUB_`, so we use `GH_` prefix.

**Detailed setup**: See [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)

---

## Step 4: Deploy Infrastructure

### Option A: Deploy via GitHub Actions (Recommended)

```bash
# Commit and push to trigger deployment
git add .
git commit -m "Configure custom domain and secrets"
git push origin main
```

Watch deployment at: `https://github.com/YOUR_USERNAME/YOUR_REPO/actions`

### Option B: Deploy Locally

```bash
# Configure AWS credentials
aws configure

# Deploy infrastructure
cd terraform
terraform init
terraform apply

# Deploy backend
cd ../backend
./deploy.sh  # or use GitHub Actions

# Deploy frontend
cd ../frontend
npm install
npm run build
npm run deploy
```

---

## Verify Deployment

### Check Terraform Outputs

```bash
cd terraform
terraform output

# Should show:
# website_url = "https://vloidcloudtech.com"
# website_url_www = "https://www.vloidcloudtech.com"
# api_endpoint = "https://xxxxxx.execute-api.us-east-1.amazonaws.com/prod"
```

### Test Website

```bash
# Test DNS
nslookup vloidcloudtech.com

# Test HTTPS
curl -I https://vloidcloudtech.com
curl -I https://www.vloidcloudtech.com
```

### Open in Browser
- https://vloidcloudtech.com ✅
- https://www.vloidcloudtech.com ✅

Both should show your portfolio with valid SSL! 🎉

---

## Common Commands

### Terraform
```bash
# View planned changes
terraform plan

# Apply changes
terraform apply

# Destroy all resources
terraform destroy

# View specific output
terraform output website_url
```

### CloudFront
```bash
# Create cache invalidation
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

### Route 53
```bash
# List hosted zones
aws route53 list-hosted-zones

# View DNS records
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234567890ABC
```

### ACM
```bash
# List certificates
aws acm list-certificates --region us-east-1

# Describe certificate
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw certificate_arn) \
  --region us-east-1
```

---

## Troubleshooting

### Issue: Certificate validation stuck
**Solution**: Wait for DNS propagation (verify nameservers updated)

### Issue: Domain shows "AccessDenied"
**Solution**: Deploy frontend build to S3, wait 10 minutes for CloudFront

### Issue: SSL shows as invalid
**Solution**: Wait for certificate validation to complete (check ACM console)

### Issue: GitHub Actions fails
**Solution**: Verify all GitHub Secrets are configured correctly

**Full troubleshooting guide**: See [DOMAIN_SETUP_GUIDE.md](DOMAIN_SETUP_GUIDE.md)

---

## Architecture Overview

```
User → Route 53 DNS → CloudFront CDN → S3 (Frontend)
                           ↓
                      API Gateway → Lambda Functions → DynamoDB
                           ↓
                      AWS Secrets Manager (API Keys)
```

---

## File Structure

```
Cloud-Public-Resume/
├── terraform/
│   ├── main.tf                    # Main infrastructure
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── provider.tf                # AWS provider config
│   ├── terraform.tfvars          # Your configuration (gitignored)
│   └── modules/
│       ├── frontend/              # S3 + CloudFront + ACM + Route53
│       ├── database/              # DynamoDB tables
│       ├── api/                   # API Gateway + Lambda
│       ├── sync/                  # Sync Lambda functions
│       └── secrets/               # AWS Secrets Manager
├── backend/
│   ├── lambda_functions/          # Python Lambda functions
│   └── shared/                    # Shared Python modules
├── frontend/
│   ├── src/                       # React application
│   └── package.json
├── .github/workflows/
│   └── deploy.yml                 # CI/CD pipeline
└── docs/
    ├── DOMAIN_SETUP_GUIDE.md      # Detailed domain setup
    ├── GITHUB_SECRETS_SETUP.md    # GitHub Secrets configuration
    ├── DOMAIN_CONFIGURATION_SUMMARY.md
    └── QUICK_START.md             # This file
```

---

## Documentation

- **[QUICK_START.md](QUICK_START.md)** - This file (quick deployment)
- **[DOMAIN_SETUP_GUIDE.md](DOMAIN_SETUP_GUIDE.md)** - Detailed domain configuration
- **[GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)** - API keys and secrets setup
- **[DOMAIN_CONFIGURATION_SUMMARY.md](DOMAIN_CONFIGURATION_SUMMARY.md)** - Technical changes summary
- **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** - Previous infrastructure changes

---

## Support

Need help?
1. Check troubleshooting sections in documentation
2. Review GitHub Actions logs
3. Check AWS CloudWatch Logs
4. Verify Route 53 and ACM configuration in AWS Console

---

## Next Steps After Deployment

1. ✅ Website is live at https://vloidcloudtech.com
2. ⏭️ Customize React frontend (frontend/src/)
3. ⏭️ Test Lambda functions (check CloudWatch Logs)
4. ⏭️ Monitor costs (AWS Cost Explorer)
5. ⏭️ Set up CloudWatch alarms
6. ⏭️ Configure WAF for security (optional)
7. ⏭️ Add Google Analytics (optional)

---

**Your portfolio is ready to impress! 🌟**

Website: https://vloidcloudtech.com

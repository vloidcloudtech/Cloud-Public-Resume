# Custom Domain Setup Guide - vloidcloudtech.com

## Overview

This guide walks you through configuring your custom domain **vloidcloudtech.com** to work with your portfolio website hosted on AWS CloudFront.

## Architecture

```
vloidcloudtech.com (Domain Registrar)
        ↓
Route 53 Hosted Zone (AWS DNS)
        ↓
ACM Certificate (us-east-1)
        ↓
CloudFront Distribution
        ↓
S3 Bucket (React App)
```

## Prerequisites

- ✅ Domain purchased: vloidcloudtech.com
- ⏳ AWS Account with appropriate permissions
- ⏳ Domain registrar access (to update nameservers)

## Step 1: Create Route 53 Hosted Zone

### Option A: If you bought the domain through AWS Route 53

**Good news!** The hosted zone is already created automatically.

1. Go to [Route 53 Console](https://console.aws.amazon.com/route53/)
2. Click **Hosted zones** in the left sidebar
3. Find **vloidcloudtech.com**
4. Copy the **Hosted zone ID** (starts with Z) - you'll need this for terraform.tfvars

### Option B: If you bought the domain from another registrar (GoDaddy, Namecheap, etc.)

1. Go to [Route 53 Console](https://console.aws.amazon.com/route53/)
2. Click **Create hosted zone**
3. Enter:
   - **Domain name**: `vloidcloudtech.com`
   - **Type**: Public hosted zone
   - **Description**: Portfolio website DNS
4. Click **Create hosted zone**
5. **IMPORTANT**: Note the 4 nameservers listed (e.g., ns-123.awsdns-12.com)
6. Copy the **Hosted zone ID** (starts with Z)

**Next: Update nameservers at your domain registrar**

Go to your domain registrar (GoDaddy, Namecheap, Google Domains, etc.) and update the nameservers to point to the 4 Route 53 nameservers.

Example for GoDaddy:
1. Log in to GoDaddy
2. My Products → Domains → vloidcloudtech.com → Manage
3. DNS → Nameservers → Change
4. Select "Custom nameservers"
5. Enter the 4 Route 53 nameservers
6. Save

**Note**: DNS propagation can take 24-48 hours, but usually completes in 1-2 hours.

## Step 2: Verify DNS Propagation (Optional but Recommended)

Before deploying Terraform, verify that your domain's nameservers have propagated:

```bash
# Check nameservers
nslookup -type=NS vloidcloudtech.com

# Should show Route 53 nameservers:
# ns-123.awsdns-12.com
# ns-456.awsdns-45.org
# ns-789.awsdns-78.net
# ns-012.awsdns-01.co.uk
```

Or use online tools:
- [WhatsMyDNS.net](https://www.whatsmydns.net/)
- [DNS Checker](https://dnschecker.org/)

## Step 3: Update Terraform Configuration

1. **Copy the example file**:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars** with your actual values:
   ```hcl
   # Infrastructure
   aws_region     = "us-east-1"
   environment    = "production"
   project_name   = "portfolio-aggregator"

   # Content sources
   github_username    = "your-actual-github-username"
   medium_username    = "your-actual-medium-username"
   youtube_channel_id = "your-actual-youtube-channel-id"

   # Custom domain
   domain_name      = "vloidcloudtech.com"
   route53_zone_id  = "Z1234567890ABC"  # Replace with your actual hosted zone ID
   ```

3. **Save the file**

## Step 4: Deploy Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes (creates ACM certificate, CloudFront, S3, etc.)
terraform apply
```

**What Terraform will create:**

1. ✅ ACM SSL/TLS Certificate (in us-east-1)
2. ✅ Certificate validation DNS records in Route 53
3. ✅ CloudFront distribution with custom domain aliases
4. ✅ Route 53 A records pointing to CloudFront
5. ✅ S3 bucket for website hosting
6. ✅ DynamoDB tables, Lambda functions, API Gateway, etc.

**Important**: Certificate validation can take 5-30 minutes. Terraform will wait for validation to complete.

## Step 5: Verify Deployment

After `terraform apply` completes successfully, verify the outputs:

```bash
# View all outputs
terraform output

# Specific outputs
terraform output website_url          # https://vloidcloudtech.com
terraform output website_url_www      # https://www.vloidcloudtech.com
terraform output certificate_arn      # ACM certificate ARN
```

## Step 6: Test Your Website

Wait 5-10 minutes for CloudFront distribution to deploy, then test:

```bash
# Test DNS resolution
nslookup vloidcloudtech.com

# Test HTTPS (should show CloudFront response)
curl -I https://vloidcloudtech.com
curl -I https://www.vloidcloudtech.com
```

**Visit in browser:**
- https://vloidcloudtech.com
- https://www.vloidcloudtech.com

Both URLs should work and show your portfolio website with a valid SSL certificate! 🎉

## What Happens Behind the Scenes

### 1. Certificate Creation (ACM)

Terraform creates an SSL/TLS certificate in us-east-1:
- Domain: vloidcloudtech.com
- SAN (Subject Alternative Name): www.vloidcloudtech.com
- Validation: DNS (automatic via Route 53)

### 2. DNS Records (Route 53)

Terraform creates these DNS records:

| Record Type | Name | Value |
|-------------|------|-------|
| A (Alias) | vloidcloudtech.com | CloudFront distribution |
| A (Alias) | www.vloidcloudtech.com | CloudFront distribution |
| CNAME | _validation.vloidcloudtech.com | ACM validation |

### 3. CloudFront Configuration

```
User request: https://vloidcloudtech.com
        ↓
Route 53 DNS lookup → CloudFront IP
        ↓
CloudFront edge location (closest to user)
        ↓
TLS handshake using ACM certificate
        ↓
Fetch from S3 bucket (if not cached)
        ↓
Return HTML/CSS/JS to user
```

## Troubleshooting

### Issue: Certificate validation stuck

**Symptom**: `terraform apply` hangs at certificate validation

**Solution**:
1. Verify nameservers are updated at your registrar
2. Check DNS propagation: `nslookup -type=NS vloidcloudtech.com`
3. Wait for DNS to propagate (can take up to 48 hours)
4. If stuck after 1 hour, cancel and retry

### Issue: "HostedZoneNotFound" error

**Symptom**: Terraform error about Route 53 hosted zone

**Solution**:
1. Verify hosted zone exists in Route 53 console
2. Double-check the `route53_zone_id` in terraform.tfvars
3. Ensure the zone ID starts with "Z"

### Issue: CloudFront returns "AccessDenied"

**Symptom**: Website shows XML error message

**Solution**:
1. Wait 10-15 minutes for CloudFront to fully deploy
2. Deploy frontend: `cd ../frontend && npm run build && npm run deploy`
3. Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"`

### Issue: SSL certificate shows as invalid

**Symptom**: Browser shows "Not secure" warning

**Solution**:
1. Verify certificate ARN in CloudFront settings
2. Check certificate status in ACM console (should be "Issued")
3. Clear browser cache and retry
4. Use incognito/private browsing mode

### Issue: www subdomain doesn't work

**Symptom**: www.vloidcloudtech.com shows error

**Solution**:
1. Verify Route 53 has A record for www subdomain
2. Check CloudFront aliases include www.vloidcloudtech.com
3. Verify ACM certificate includes www as SAN

## DNS Propagation Timeline

| Time | What's Happening |
|------|------------------|
| 0 min | Update nameservers at registrar |
| 5 min | Some DNS servers start seeing new nameservers |
| 1 hour | Most DNS servers updated |
| 6 hours | ~95% global propagation |
| 24 hours | ~99% global propagation |
| 48 hours | Full global propagation guaranteed |

## Cost Breakdown

| Service | Cost |
|---------|------|
| Route 53 Hosted Zone | $0.50/month |
| Route 53 DNS Queries | $0.40 per million queries (~$0.01/month) |
| ACM Certificate | **FREE** |
| CloudFront | Free tier: 1TB/month, then $0.085/GB |
| S3 Storage | $0.023/GB/month (~$0.50/month for small site) |
| **Total** | **~$1-2/month** for typical portfolio site |

## Security Best Practices

✅ **Enabled by default:**
- HTTPS-only (HTTP redirects to HTTPS)
- TLS 1.2 minimum protocol version
- Modern cipher suites
- SNI for SSL (Server Name Indication)

✅ **Recommended:**
- Enable CloudFront WAF (Web Application Firewall) for production
- Set up CloudWatch alarms for high traffic
- Enable CloudFront access logging
- Configure S3 bucket policies to restrict access

## Next Steps

1. ✅ Configure domain nameservers
2. ✅ Create Route 53 hosted zone
3. ✅ Deploy Terraform infrastructure
4. ✅ Wait for certificate validation
5. ✅ Deploy frontend React app
6. ✅ Test website at https://vloidcloudtech.com
7. ⏭️ Set up GitHub Actions for CI/CD (see [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md))
8. ⏭️ Configure GitHub Secrets for API keys
9. ⏭️ Deploy backend Lambda functions
10. ⏭️ Test API endpoints

## Support Resources

- [Route 53 Documentation](https://docs.aws.amazon.com/route53/)
- [ACM Documentation](https://docs.aws.amazon.com/acm/)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Quick Reference Commands

```bash
# Check DNS nameservers
nslookup -type=NS vloidcloudtech.com

# Check A record
nslookup vloidcloudtech.com

# Test HTTPS connection
curl -I https://vloidcloudtech.com

# Terraform commands
terraform init
terraform plan
terraform apply
terraform output

# View Route 53 hosted zone ID
aws route53 list-hosted-zones --query 'HostedZones[?Name==`vloidcloudtech.com.`]'

# View ACM certificate status
aws acm list-certificates --region us-east-1

# Create CloudFront invalidation
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

---

**Ready to deploy?** Follow the steps above and your portfolio will be live at https://vloidcloudtech.com! 🚀

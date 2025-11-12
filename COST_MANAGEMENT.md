# Cost Management Guide

Complete guide to understanding and managing AWS costs for your Portfolio Aggregator application.

---

## Monthly Cost Breakdown

### Fixed Costs (Predictable)

| Service | Resource | Cost | Notes |
|---------|----------|------|-------|
| **Secrets Manager** | 3 secrets | **$1.20/month** | Biggest fixed cost |
| **Route 53** | 1 hosted zone | **$0.50/month** | Plus $0.40 per million queries (free tier) |
| **TOTAL FIXED** | | **$1.70/month** | Minimum monthly cost |

### Variable Costs (Usage-Based)

| Service | Free Tier | After Free Tier | Your Estimate |
|---------|-----------|-----------------|---------------|
| **Lambda** | 1M requests + 400K GB-sec | $0.20/1M requests | **Free** (low traffic) |
| **DynamoDB** | 25GB + 25 RCU/WCU | $0.25/GB + $0.00013/RCU | **Free** (< 1GB data) |
| **CloudFront** | 1TB transfer + 10M requests | $0.085/GB + $0.01/10K req | **$0-3/month** |
| **CloudWatch Logs** | 5GB ingestion + 5GB storage | $0.50/GB ingestion | **$0-2/month** |
| **S3** | 5GB storage + 20K GET | $0.023/GB | **< $0.01/month** |
| **API Gateway** | 1M HTTP API calls | $1.00/1M calls | **Free** (low traffic) |
| **ACM** | Unlimited certificates | FREE | **$0/month** |

### Total Estimated Cost

- **Minimum**: $1.70/month ($20.40/year)
- **Typical**: $3-5/month ($36-60/year)
- **High Traffic**: $8-15/month ($96-180/year)

---

## Cost Optimization Already Implemented

### ✅ CloudWatch Logs Retention
**Status**: Implemented via Terraform
**Savings**: $2-10/month

All Lambda log groups now have 7-day retention:
- `/aws/lambda/portfolio-aggregator-api-production`
- `/aws/lambda/portfolio-aggregator-github-sync-production`
- `/aws/lambda/portfolio-aggregator-medium-sync-production`
- `/aws/lambda/portfolio-aggregator-youtube-sync-production`

**Before**: Logs grow indefinitely
**After**: Logs auto-delete after 7 days

### ✅ CloudFront Price Class Optimization
**Status**: Implemented via Terraform
**Savings**: 20-30% on CloudFront costs

Price Class: `PriceClass_100` (US, Canada, Europe only)

### ✅ DynamoDB On-Demand Billing
**Status**: Implemented via Terraform
**Benefit**: Pay only for what you use (no provisioned capacity)

### ✅ HTTP API Gateway (vs REST API)
**Status**: Implemented via Terraform
**Savings**: 70% cheaper than REST API ($1/M vs $3.50/M requests)

---

## Running the Audit Script

### Prerequisites
```bash
# Install AWS CLI if not already installed
# Windows (PowerShell):
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# macOS:
brew install awscli

# Linux:
sudo apt-get install awscli  # Ubuntu/Debian
sudo yum install awscli       # Amazon Linux/RHEL
```

### Configure AWS Credentials
```bash
aws configure
# Enter your AWS_ACCESS_KEY_ID
# Enter your AWS_SECRET_ACCESS_KEY
# Region: us-east-1
# Output: json
```

### Run the Audit
```bash
cd scripts
chmod +x audit-aws-resources.sh
./audit-aws-resources.sh
```

### What It Checks
- ✅ All deployed resources
- ✅ Duplicate resources (e.g., multiple CloudFront distributions)
- ✅ Log groups without retention policies
- ✅ Cost estimates
- ✅ Optimization recommendations

---

## Setting Up Cost Alerts

### Option 1: SNS Email Notifications (Recommended)

Your Terraform creates an SNS topic for cost alerts. Subscribe to it:

```bash
# Get the SNS topic ARN
cd terraform
terraform output cost_alert_topic_arn

# Subscribe your email
aws sns subscribe \
  --topic-arn <TOPIC_ARN_FROM_OUTPUT> \
  --protocol email \
  --notification-endpoint your-email@example.com

# Confirm subscription in your email inbox
```

**Alert Threshold**: $10/month

### Option 2: AWS Budgets (Manual Setup)

1. Go to [AWS Budgets Console](https://console.aws.amazon.com/billing/home#/budgets)
2. Click **Create budget**
3. Select **Cost budget**
4. Set amount: **$10.00** monthly
5. Set alert threshold: **80%** (triggers at $8)
6. Enter your email
7. Click **Create budget**

**Cost**: FREE (first 2 budgets are free)

### Option 3: AWS Cost Anomaly Detection

1. Go to [Cost Anomaly Detection](https://console.aws.amazon.com/cost-management/home#/anomaly-detection/overview)
2. Click **Get started**
3. Create a monitor for **All services**
4. Set threshold: **$1** (alerts for any unusual $1+ spike)
5. Enter your email
6. Click **Create monitor**

**Cost**: FREE

---

## Monitoring Costs in AWS Console

### View Current Month's Costs

```bash
# Via CLI
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter file://<(echo '{"Tags":{"Key":"Project","Values":["portfolio-aggregator"]}}')
```

### Via AWS Console

1. Go to [Cost Explorer](https://console.aws.amazon.com/cost-management/home#/cost-explorer)
2. Enable Cost Explorer (if not enabled)
3. Select date range: **This month**
4. Group by: **Service**
5. Filter by: **Tag: Project = portfolio-aggregator**

---

## Additional Cost Optimization Options

### 1. Reduce Lambda Sync Frequency

**Current**: Every 12 hours (4 executions/day per function)
**Proposed**: Every 24 hours (2 executions/day per function)
**Savings**: 50% reduction in Lambda invocations

**To implement**:
Edit [terraform/modules/sync/main.tf](terraform/modules/sync/main.tf#L163-L173) and change:
```hcl
schedule_expression = "rate(12 hours)"
# TO:
schedule_expression = "rate(24 hours)"
```

Then deploy:
```bash
cd terraform
terraform apply
```

### 2. Switch to SSM Parameter Store (Instead of Secrets Manager)

**Current**: Secrets Manager ($0.40/secret/month)
**Alternative**: SSM Parameter Store (FREE for standard parameters)
**Savings**: $1.20/month ($14.40/year)

**Trade-offs**:
- ❌ No automatic rotation
- ❌ Less audit logging
- ✅ FREE for standard parameters
- ✅ Same security (encrypted at rest)

**Recommendation**: Keep Secrets Manager for production security best practices.

### 3. Enable DynamoDB TTL (Auto-Delete Old Items)

**Purpose**: Automatically delete old posts/videos after 2 years
**Savings**: Keeps database lean, reduces storage costs
**Cost Impact**: Minimal (currently < 1GB anyway)

**To implement**:
Add to [terraform/modules/database/main.tf](terraform/modules/database/main.tf):
```hcl
resource "aws_dynamodb_table" "medium_posts" {
  # ... existing config ...

  ttl {
    enabled        = true
    attribute_name = "expires_at"  # Unix timestamp
  }
}
```

### 4. CloudFront Reserved Capacity

**When**: If you get consistent high traffic (> 10TB/month)
**Savings**: 30-40% discount on data transfer
**Commitment**: 12 months
**Recommendation**: Wait until you have predictable traffic patterns

---

## Understanding Your Bill

### What Each Service Costs You

#### Secrets Manager ($1.20/month)
- 3 secrets × $0.40/month
- Stores GitHub token, YouTube API key, Anthropic API key
- **How to reduce**: Switch to SSM Parameter Store (saves $1.20/month)

#### Route 53 ($0.50/month)
- 1 hosted zone for vloidcloudtech.com
- A records are FREE (alias records to CloudFront)
- Queries: $0.40/million (you won't hit this)
- **How to reduce**: Can't be reduced (need hosted zone for custom domain)

#### CloudWatch Logs ($0-2/month)
- First 5GB ingestion: FREE
- First 5GB storage: FREE
- Beyond that: $0.50/GB ingestion, $0.03/GB storage
- **How to reduce**: Already optimized with 7-day retention

#### CloudFront ($0-3/month)
- First 1TB transfer: FREE
- First 10M requests: FREE
- Beyond that: $0.085/GB + $0.01/10K requests
- **How to reduce**: Already using cheapest price class

#### Lambda (FREE with low traffic)
- First 1M requests: FREE
- First 400K GB-seconds compute: FREE
- Your usage: ~8 sync runs/day + API calls = well within free tier
- **How to reduce**: Reduce sync frequency to 24h intervals

---

## Detecting Cost Spikes

### Common Causes of Unexpected Costs

1. **Lambda Infinite Loop**
   - **Symptom**: Lambda costs suddenly spike
   - **Prevention**: CloudWatch alarms on Lambda invocations
   - **Detection**: Check Lambda invocation metrics

2. **DDoS Attack on API**
   - **Symptom**: API Gateway + Lambda costs spike
   - **Prevention**: AWS Shield Standard (free) + rate limiting
   - **Detection**: API Gateway request count metrics

3. **Log Retention Not Applied**
   - **Symptom**: CloudWatch costs grow month over month
   - **Prevention**: Already fixed! (7-day retention)
   - **Detection**: Run audit script monthly

4. **Data Transfer Out**
   - **Symptom**: S3 or CloudFront costs spike
   - **Prevention**: CloudFront caching + gzip compression
   - **Detection**: Check CloudFront data transfer metrics

### Setting Up Anomaly Detection

```bash
# Create CloudWatch alarm for Lambda invocations
aws cloudwatch put-metric-alarm \
  --alarm-name high-lambda-invocations \
  --alarm-description "Alert when Lambda invocations exceed 100K/day" \
  --metric-name Invocations \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 86400 \
  --evaluation-periods 1 \
  --threshold 100000 \
  --comparison-operator GreaterThanThreshold
```

---

## Monthly Cost Checklist

### Run This Checklist on the 1st of Every Month

- [ ] Run the audit script: `./scripts/audit-aws-resources.sh`
- [ ] Check AWS billing dashboard for current month charges
- [ ] Verify no log groups without retention policies
- [ ] Check for duplicate resources (CloudFront, Lambda, etc.)
- [ ] Review Lambda invocation counts (should be ~240/month per sync function)
- [ ] Verify EventBridge schedules are still ENABLED (not accidentally disabled)
- [ ] Check DynamoDB table sizes (should be < 1GB)
- [ ] Review CloudWatch Logs size (should not grow unbounded)

---

## FAQ

### Q: What if I go over $10/month?

**A**: You'll receive an email alert (if SNS configured). Check:
1. Run audit script to identify the issue
2. Check CloudWatch Logs size (main culprit if logs retention wasn't applied)
3. Check Lambda invocation counts (could indicate an issue)
4. Review Cost Explorer for service breakdown

### Q: Can I reduce costs to $0?

**A**: No. Fixed costs are:
- Secrets Manager: $1.20/month (or switch to SSM Parameter Store for free)
- Route 53: $0.50/month (required for custom domain)

**Minimum possible**: $0.50/month (if using SSM Parameter Store instead of Secrets Manager)

### Q: What happens if I don't pay?

**A**: AWS will:
1. Send email notifications
2. Suspend services after 90 days non-payment
3. Delete resources after 180 days

**Recommendation**: Set up cost alerts and budget limits.

### Q: How do I completely delete everything?

**A**: Use the destroy workflow:
```bash
# Via GitHub Actions
Go to Actions → Run "Destroy Infrastructure" workflow

# Or via Terraform locally
cd terraform
terraform destroy
```

**Cost after deletion**: $0/month (except Route 53 hosted zone stays until manually deleted)

---

## Support & Resources

- **AWS Cost Calculator**: https://calculator.aws/
- **AWS Pricing**: https://aws.amazon.com/pricing/
- **Cost Optimization Hub**: https://console.aws.amazon.com/cost-management/home#/cost-optimization-hub
- **AWS Support**: https://console.aws.amazon.com/support/

---

**Last Updated**: 2025-11-12
**Current Estimated Cost**: $3-8/month

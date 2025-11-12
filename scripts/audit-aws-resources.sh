#!/bin/bash

# ============================================================================
# AWS Infrastructure Audit Script
# ============================================================================
# This script audits your AWS infrastructure to identify:
# - All deployed resources
# - Potential duplicates
# - Orphaned resources
# - Cost optimization opportunities
#
# Usage:
#   chmod +x audit-aws-resources.sh
#   ./audit-aws-resources.sh
#
# Requirements:
#   - AWS CLI installed and configured
#   - AWS credentials with read permissions
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
PROJECT_PREFIX="portfolio-aggregator"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}AWS Infrastructure Audit Report${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "Project: $PROJECT_PREFIX"
echo "Region: $AWS_REGION"
echo "Date: $(date)"
echo ""

# ============================================================================
# 1. CloudFront Distributions
# ============================================================================
echo -e "${BLUE}[1/10] Checking CloudFront Distributions...${NC}"
CLOUDFRONT_COUNT=$(aws cloudfront list-distributions --query "DistributionList.Items | length(@)" --output text 2>/dev/null || echo "0")

if [ "$CLOUDFRONT_COUNT" -gt 1 ]; then
  echo -e "${YELLOW}⚠ Warning: Found $CLOUDFRONT_COUNT CloudFront distributions (expected: 1)${NC}"
  aws cloudfront list-distributions --query "DistributionList.Items[].{ID:Id,Aliases:join(',',Aliases.Items),Status:Status,Enabled:Enabled}" --output table
else
  echo -e "${GREEN}✓ CloudFront: $CLOUDFRONT_COUNT distribution(s) found${NC}"
fi
echo ""

# ============================================================================
# 2. Lambda Functions
# ============================================================================
echo -e "${BLUE}[2/10] Checking Lambda Functions...${NC}"
LAMBDA_FUNCTIONS=$(aws lambda list-functions --region $AWS_REGION --query "Functions[?starts_with(FunctionName, '$PROJECT_PREFIX')].FunctionName" --output text 2>/dev/null)

EXPECTED_LAMBDAS=(
  "${PROJECT_PREFIX}-api-production"
  "${PROJECT_PREFIX}-github-sync-production"
  "${PROJECT_PREFIX}-medium-sync-production"
  "${PROJECT_PREFIX}-youtube-sync-production"
)

FOUND_COUNT=$(echo "$LAMBDA_FUNCTIONS" | wc -w)
EXPECTED_COUNT=${#EXPECTED_LAMBDAS[@]}

if [ "$FOUND_COUNT" -gt "$EXPECTED_COUNT" ]; then
  echo -e "${YELLOW}⚠ Warning: Found $FOUND_COUNT Lambda functions (expected: $EXPECTED_COUNT)${NC}"
elif [ "$FOUND_COUNT" -lt "$EXPECTED_COUNT" ]; then
  echo -e "${RED}✗ Error: Found only $FOUND_COUNT Lambda functions (expected: $EXPECTED_COUNT)${NC}"
else
  echo -e "${GREEN}✓ Lambda Functions: $FOUND_COUNT found (expected: $EXPECTED_COUNT)${NC}"
fi

aws lambda list-functions --region $AWS_REGION --query "Functions[?starts_with(FunctionName, '$PROJECT_PREFIX')].{Name:FunctionName,Memory:MemorySize,Runtime:Runtime,Size:CodeSize}" --output table 2>/dev/null
echo ""

# ============================================================================
# 3. DynamoDB Tables
# ============================================================================
echo -e "${BLUE}[3/10] Checking DynamoDB Tables...${NC}"
DYNAMO_TABLES=$(aws dynamodb list-tables --region $AWS_REGION --query "TableNames[?contains(@, '$PROJECT_PREFIX')]" --output text 2>/dev/null)

EXPECTED_TABLES=(
  "${PROJECT_PREFIX}-github-repos-production"
  "${PROJECT_PREFIX}-medium-posts-production"
  "${PROJECT_PREFIX}-youtube-videos-production"
  "${PROJECT_PREFIX}-sync-metadata-production"
)

TABLE_COUNT=$(echo "$DYNAMO_TABLES" | wc -w)
EXPECTED_TABLE_COUNT=${#EXPECTED_TABLES[@]}

if [ "$TABLE_COUNT" -gt "$EXPECTED_TABLE_COUNT" ]; then
  echo -e "${YELLOW}⚠ Warning: Found $TABLE_COUNT DynamoDB tables (expected: $EXPECTED_TABLE_COUNT)${NC}"
elif [ "$TABLE_COUNT" -lt "$EXPECTED_TABLE_COUNT" ]; then
  echo -e "${RED}✗ Error: Found only $TABLE_COUNT DynamoDB tables (expected: $EXPECTED_TABLE_COUNT)${NC}"
else
  echo -e "${GREEN}✓ DynamoDB Tables: $TABLE_COUNT found (expected: $EXPECTED_TABLE_COUNT)${NC}"
fi

for table in $DYNAMO_TABLES; do
  echo "  - $table"
done
echo ""

# ============================================================================
# 4. CloudWatch Log Groups & Retention
# ============================================================================
echo -e "${BLUE}[4/10] Checking CloudWatch Log Groups...${NC}"
LOG_GROUPS=$(aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/$PROJECT_PREFIX" --region $AWS_REGION --query "logGroups[]" --output json 2>/dev/null)

NO_RETENTION_COUNT=0
for log_group in $(echo "$LOG_GROUPS" | jq -r '.[].logGroupName'); do
  retention=$(echo "$LOG_GROUPS" | jq -r ".[] | select(.logGroupName==\"$log_group\") | .retentionInDays // \"Never\"")
  size_bytes=$(echo "$LOG_GROUPS" | jq -r ".[] | select(.logGroupName==\"$log_group\") | .storedBytes // 0")
  size_mb=$((size_bytes / 1024 / 1024))

  if [ "$retention" == "Never" ] || [ "$retention" == "null" ]; then
    echo -e "${YELLOW}⚠ $log_group: NO RETENTION (${size_mb}MB) - COST RISK!${NC}"
    NO_RETENTION_COUNT=$((NO_RETENTION_COUNT + 1))
  else
    echo -e "${GREEN}✓ $log_group: ${retention} days (${size_mb}MB)${NC}"
  fi
done

if [ "$NO_RETENTION_COUNT" -gt 0 ]; then
  echo -e "${RED}⚠ WARNING: $NO_RETENTION_COUNT log group(s) without retention policy!${NC}"
  echo -e "${YELLOW}  → These logs will grow indefinitely and increase costs${NC}"
  echo -e "${YELLOW}  → Recommend setting 7-14 day retention${NC}"
fi
echo ""

# ============================================================================
# 5. Secrets Manager Secrets
# ============================================================================
echo -e "${BLUE}[5/10] Checking Secrets Manager Secrets...${NC}"
SECRETS=$(aws secretsmanager list-secrets --region $AWS_REGION --query "SecretList[?contains(Name, '$PROJECT_PREFIX')].Name" --output text 2>/dev/null)

EXPECTED_SECRETS=(
  "${PROJECT_PREFIX}-github-token-production"
  "${PROJECT_PREFIX}-youtube-key-production"
  "${PROJECT_PREFIX}-ai-key-production"
)

SECRET_COUNT=$(echo "$SECRETS" | wc -w)
EXPECTED_SECRET_COUNT=${#EXPECTED_SECRETS[@]}

if [ "$SECRET_COUNT" -gt "$EXPECTED_SECRET_COUNT" ]; then
  echo -e "${YELLOW}⚠ Warning: Found $SECRET_COUNT secrets (expected: $EXPECTED_SECRET_COUNT)${NC}"
elif [ "$SECRET_COUNT" -lt "$EXPECTED_SECRET_COUNT" ]; then
  echo -e "${RED}✗ Error: Found only $SECRET_COUNT secrets (expected: $EXPECTED_SECRET_COUNT)${NC}"
else
  echo -e "${GREEN}✓ Secrets Manager: $SECRET_COUNT secrets (expected: $EXPECTED_SECRET_COUNT)${NC}"
fi

echo -e "${BLUE}Cost: $SECRET_COUNT × \$0.40/month = \$$(awk "BEGIN {print $SECRET_COUNT * 0.40}")/month${NC}"
for secret in $SECRETS; do
  echo "  - $secret"
done
echo ""

# ============================================================================
# 6. S3 Buckets
# ============================================================================
echo -e "${BLUE}[6/10] Checking S3 Buckets...${NC}"
S3_BUCKETS=$(aws s3 ls | grep -E "(portfolio|vloidcloudtech)" | awk '{print $3}' || echo "")

if [ -z "$S3_BUCKETS" ]; then
  echo -e "${RED}✗ No S3 buckets found${NC}"
else
  echo -e "${GREEN}✓ S3 Buckets found:${NC}"
  for bucket in $S3_BUCKETS; do
    size=$(aws s3 ls s3://$bucket --recursive --summarize 2>/dev/null | grep "Total Size" | awk '{print $3}' || echo "0")
    size_mb=$((size / 1024 / 1024))
    echo "  - $bucket (${size_mb}MB)"
  done
fi
echo ""

# ============================================================================
# 7. EventBridge Rules
# ============================================================================
echo -e "${BLUE}[7/10] Checking EventBridge Schedules...${NC}"
EVENT_RULES=$(aws events list-rules --region $AWS_REGION --query "Rules[?contains(Name, '$PROJECT_PREFIX')]" --output json 2>/dev/null)

RULE_COUNT=$(echo "$EVENT_RULES" | jq '. | length')
echo -e "${GREEN}✓ EventBridge Rules: $RULE_COUNT found${NC}"
echo "$EVENT_RULES" | jq -r '.[] | "  - \(.Name): \(.ScheduleExpression // "N/A") (\(.State))"'
echo ""

# ============================================================================
# 8. IAM Roles
# ============================================================================
echo -e "${BLUE}[8/10] Checking IAM Roles...${NC}"
IAM_ROLES=$(aws iam list-roles --query "Roles[?contains(RoleName, '$PROJECT_PREFIX')].RoleName" --output text 2>/dev/null)

EXPECTED_ROLES=(
  "${PROJECT_PREFIX}-api-lambda-role-production"
  "${PROJECT_PREFIX}-sync-lambda-role-production"
)

ROLE_COUNT=$(echo "$IAM_ROLES" | wc -w)
EXPECTED_ROLE_COUNT=${#EXPECTED_ROLES[@]}

if [ "$ROLE_COUNT" -gt "$EXPECTED_ROLE_COUNT" ]; then
  echo -e "${YELLOW}⚠ Warning: Found $ROLE_COUNT IAM roles (expected: $EXPECTED_ROLE_COUNT)${NC}"
elif [ "$ROLE_COUNT" -lt "$EXPECTED_ROLE_COUNT" ]; then
  echo -e "${RED}✗ Error: Found only $ROLE_COUNT IAM roles (expected: $EXPECTED_ROLE_COUNT)${NC}"
else
  echo -e "${GREEN}✓ IAM Roles: $ROLE_COUNT found (expected: $EXPECTED_ROLE_COUNT)${NC}"
fi

for role in $IAM_ROLES; do
  echo "  - $role"
done
echo ""

# ============================================================================
# 9. API Gateway
# ============================================================================
echo -e "${BLUE}[9/10] Checking API Gateway...${NC}"
API_GATEWAYS=$(aws apigatewayv2 get-apis --region $AWS_REGION --query "Items[?contains(Name, '$PROJECT_PREFIX')]" --output json 2>/dev/null)

API_COUNT=$(echo "$API_GATEWAYS" | jq '. | length')
if [ "$API_COUNT" -gt 1 ]; then
  echo -e "${YELLOW}⚠ Warning: Found $API_COUNT API Gateways (expected: 1)${NC}"
else
  echo -e "${GREEN}✓ API Gateway: $API_COUNT found${NC}"
fi

echo "$API_GATEWAYS" | jq -r '.[] | "  - \(.Name): \(.ApiEndpoint) (\(.ProtocolType))"'
echo ""

# ============================================================================
# 10. Route 53 Records
# ============================================================================
echo -e "${BLUE}[10/10] Checking Route 53 DNS Records...${NC}"
HOSTED_ZONE_ID="Z0393886EJ0V2CL9B9Y0"
RECORDS=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query "ResourceRecordSets[?contains(Name, 'vloidcloudtech.com')]" --output json 2>/dev/null)

RECORD_COUNT=$(echo "$RECORDS" | jq '. | length')
echo -e "${GREEN}✓ Route 53 Records: $RECORD_COUNT found${NC}"
echo "$RECORDS" | jq -r '.[] | "  - \(.Name) (\(.Type))"'
echo ""

# ============================================================================
# Cost Summary
# ============================================================================
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Cost Estimation${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}Fixed Monthly Costs:${NC}"
echo "  - Secrets Manager: $SECRET_COUNT × \$0.40 = \$$(awk "BEGIN {print $SECRET_COUNT * 0.40}")"
echo "  - Route 53 Hosted Zone: \$0.50"
echo "  - Fixed Total: ~\$$(awk "BEGIN {print $SECRET_COUNT * 0.40 + 0.50}")/month"
echo ""
echo -e "${YELLOW}Variable Costs (depends on usage):${NC}"
echo "  - Lambda invocations (likely free tier)"
echo "  - CloudFront data transfer (first 1TB free)"
echo "  - DynamoDB reads/writes (likely free tier)"
echo "  - CloudWatch Logs (check retention policies above)"
echo ""
echo -e "${BLUE}Estimated Total: \$3-8/month${NC}"
echo ""

# ============================================================================
# Recommendations
# ============================================================================
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Recommendations${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

if [ "$NO_RETENTION_COUNT" -gt 0 ]; then
  echo -e "${RED}⚠ URGENT: Set retention policy on CloudWatch Logs${NC}"
  echo "  → Prevents unbounded log growth"
  echo "  → Savings: \$2-10/month"
  echo ""
fi

if [ "$CLOUDFRONT_COUNT" -gt 1 ]; then
  echo -e "${YELLOW}⚠ Review duplicate CloudFront distributions${NC}"
  echo "  → Only 1 distribution is needed"
  echo ""
fi

if [ "$FOUND_COUNT" -gt "$EXPECTED_COUNT" ]; then
  echo -e "${YELLOW}⚠ Review extra Lambda functions${NC}"
  echo "  → Delete unused functions"
  echo ""
fi

echo -e "${GREEN}✓ Enable AWS Cost Explorer for detailed cost tracking${NC}"
echo -e "${GREEN}✓ Set up AWS Budgets alert for \$10/month threshold${NC}"
echo -e "${GREEN}✓ Review logs regularly to monitor function health${NC}"
echo ""

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Audit Complete!${NC}"
echo -e "${BLUE}============================================${NC}"

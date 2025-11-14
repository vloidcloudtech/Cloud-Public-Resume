#!/bin/bash
# Trigger all sync functions and check their status

echo "Triggering sync functions..."
echo ""

echo "1. GitHub Sync (with AI summaries)..."
aws lambda invoke --function-name portfolio-aggregator-github-sync-production \
  --invocation-type RequestResponse \
  /tmp/github-sync-output.json > /dev/null
echo "Response:"
cat /tmp/github-sync-output.json | python -m json.tool
echo ""

echo "2. Medium Sync (with clean text)..."
aws lambda invoke --function-name portfolio-aggregator-medium-sync-production \
  --invocation-type RequestResponse \
  /tmp/medium-sync-output.json > /dev/null
echo "Response:"
cat /tmp/medium-sync-output.json | python -m json.tool
echo ""

echo "3. YouTube Sync..."
aws lambda invoke --function-name portfolio-aggregator-youtube-sync-production \
  --invocation-type RequestResponse \
  /tmp/youtube-sync-output.json > /dev/null
echo "Response:"
cat /tmp/youtube-sync-output.json | python -m json.tool
echo ""

echo "✅ All sync functions triggered!"
echo ""
echo "Check DynamoDB to verify data was updated:"
echo "  aws dynamodb scan --table-name portfolio-aggregator-github-repos-production --select COUNT"
echo "  aws dynamodb scan --table-name portfolio-aggregator-medium-posts-production --select COUNT"

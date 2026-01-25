#!/bin/bash
set -e

echo "=============================================="
echo "   Attach AWS WAF to CloudFront"
echo "=============================================="

if [ -z "$CF_ID" ]; then
  echo "Error: CF_ID environment variable not set"
  echo "Usage: export CF_ID=\"YOUR_DISTRIBUTION_ID\" && ./attach-waf.sh"
  exit 1
fi

REGION="us-east-1"

# Get WAF ARN
WAF_ARN=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region "$REGION" \
  --query 'WebACLs[?Name==`static-site-waf`].ARN' --output text)

if [ -z "$WAF_ARN" ] || [ "$WAF_ARN" == "None" ]; then
  echo "Error: Web ACL not found. Run deploy-waf.sh first."
  exit 1
fi

# Get current CloudFront configuration
aws cloudfront get-distribution-config --id "$CF_ID" > /tmp/cf-config.json
ETAG=$(jq -r '.ETag' /tmp/cf-config.json)

# Add WAF to distribution
jq --arg waf "$WAF_ARN" '.DistributionConfig | .WebACLId = $waf' \
  /tmp/cf-config.json > /tmp/cf-config-with-waf.json

# Update distribution
aws cloudfront update-distribution --id "$CF_ID" --if-match "$ETAG" \
  --distribution-config file:///tmp/cf-config-with-waf.json

echo "Waiting for CloudFront deployment..."
aws cloudfront wait distribution-deployed --id "$CF_ID"
echo "WAF successfully attached to CloudFront!"

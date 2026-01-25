#!/bin/bash
set -e

echo "=============================================="
echo "   AWS WAF Cleanup"
echo "=============================================="

REGION="us-east-1"
WAF_NAME="static-site-waf"

# Get WAF ID
WAF_ID=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region "$REGION" \
  --query "WebACLs[?Name=='$WAF_NAME'].Id" --output text 2>/dev/null || echo "")

if [ -z "$WAF_ID" ] || [ "$WAF_ID" == "None" ]; then
  echo "No Web ACL found. Nothing to clean up."
  exit 0
fi

# Remove from CloudFront if CF_ID is set
if [ -n "$CF_ID" ]; then
  echo "Removing WAF from CloudFront..."
  aws cloudfront get-distribution-config --id "$CF_ID" > /tmp/cf-config.json
  ETAG=$(jq -r '.ETag' /tmp/cf-config.json)
  jq '.DistributionConfig | .WebACLId = ""' /tmp/cf-config.json > /tmp/cf-no-waf.json
  aws cloudfront update-distribution --id "$CF_ID" --if-match "$ETAG" \
    --distribution-config file:///tmp/cf-no-waf.json
  aws cloudfront wait distribution-deployed --id "$CF_ID"
fi

# Delete Web ACL
LOCK_TOKEN=$(aws wafv2 get-web-acl --name "$WAF_NAME" --scope CLOUDFRONT \
  --id "$WAF_ID" --region "$REGION" --query 'LockToken' --output text)

aws wafv2 delete-web-acl --name "$WAF_NAME" --scope CLOUDFRONT \
  --id "$WAF_ID" --lock-token "$LOCK_TOKEN" --region "$REGION"

echo "Cleanup complete!"

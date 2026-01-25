#!/bin/bash
set -e

echo "=============================================="
echo "   AWS WAF Deployment for CloudFront"
echo "=============================================="

WAF_NAME="static-site-waf"
REGION="us-east-1"

# Check if WAF already exists
EXISTING_WAF=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region "$REGION" \
  --query "WebACLs[?Name=='$WAF_NAME'].Id" --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_WAF" ] && [ "$EXISTING_WAF" != "None" ]; then
  echo "Web ACL '$WAF_NAME' already exists. Skipping creation."
  exit 0
fi

# Create Web ACL
aws wafv2 create-web-acl \
  --name "$WAF_NAME" \
  --scope CLOUDFRONT \
  --default-action Allow={} \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=StaticSiteWAF \
  --rules '[
    {
      "Name": "AWS-AWSManagedRulesCommonRuleSet",
      "Priority": 1,
      "Statement": {"ManagedRuleGroupStatement": {"VendorName": "AWS", "Name": "AWSManagedRulesCommonRuleSet"}},
      "OverrideAction": {"None": {}},
      "VisibilityConfig": {"SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "CommonRuleSet"}
    },
    {
      "Name": "AWS-AWSManagedRulesKnownBadInputsRuleSet",
      "Priority": 2,
      "Statement": {"ManagedRuleGroupStatement": {"VendorName": "AWS", "Name": "AWSManagedRulesKnownBadInputsRuleSet"}},
      "OverrideAction": {"None": {}},
      "VisibilityConfig": {"SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "KnownBadInputs"}
    }
  ]' \
  --region "$REGION"

echo "WAF Web ACL created successfully!"
echo "Next: Run ./attach-waf.sh to attach WAF to CloudFront"

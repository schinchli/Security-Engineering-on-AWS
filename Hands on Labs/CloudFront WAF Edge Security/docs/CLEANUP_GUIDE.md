# Cleanup Guide: AWS WAF CloudFront Edge Security

## Quick Cleanup

```bash
export CF_ID="YOUR_DISTRIBUTION_ID"
./scripts/cleanup.sh
```

## Manual Cleanup

### Step 1: Remove WAF from CloudFront

```bash
aws cloudfront get-distribution-config --id "$CF_ID" > /tmp/cf-config.json
ETAG=$(jq -r '.ETag' /tmp/cf-config.json)
jq '.DistributionConfig | .WebACLId = ""' /tmp/cf-config.json > /tmp/cf-no-waf.json
aws cloudfront update-distribution --id "$CF_ID" --if-match "$ETAG" \
  --distribution-config file:///tmp/cf-no-waf.json
```

### Step 2: Delete Web ACL

```bash
WAF_ID=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 \
  --query "WebACLs[?Name=='static-site-waf'].Id" --output text)
LOCK_TOKEN=$(aws wafv2 get-web-acl --name static-site-waf --scope CLOUDFRONT \
  --id "$WAF_ID" --region us-east-1 --query 'LockToken' --output text)
aws wafv2 delete-web-acl --name static-site-waf --scope CLOUDFRONT \
  --id "$WAF_ID" --lock-token "$LOCK_TOKEN" --region us-east-1
```

## Cost After Cleanup

| Resource | Cost |
|----------|------|
| Web ACL | $0 |
| Rules | $0 |
| **Total** | **$0** |

---

*Author: Shashank Chinchli, AWS Solutions Architect*

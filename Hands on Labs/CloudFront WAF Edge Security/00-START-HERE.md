# AWS WAF CloudFront Security Lab - Quick Start Guide

## Welcome!

Secure your static website with AWS WAF edge protection, OWASP Top 10 defense, and DDoS mitigation - all integrated with Amazon CloudFront.

---

## Quick Start (10 Minutes)

```bash
# 1. Set your CloudFront distribution ID
export CF_ID="YOUR_DISTRIBUTION_ID"

# 2. Deploy WAF
./scripts/deploy-waf.sh

# 3. Attach WAF to CloudFront
./scripts/attach-waf.sh

# 4. Test protection
./scripts/test-waf.sh

# 5. Cleanup (when done)
./scripts/cleanup.sh
```

---

## Folder Structure

```
CloudFront WAF Edge Security/
├── README.md                   # Complete lab guide
├── 00-START-HERE.md            # This file
├── docs/                       # Documentation
├── scripts/                    # Automation scripts
└── src/configs/                # Configuration files
```

---

## Cost Estimate

- **WAF Web ACL:** ~$5.00/month
- **Managed Rules:** ~$1.00/month
- **1M Requests:** ~$0.60/month
- **Total:** ~$6.60/month

---

## Prerequisites

- AWS Account with CLI configured
- Existing CloudFront distribution
- 25 minutes

---

## Success Criteria

1. WAF Web ACL created in us-east-1
2. WAF attached to CloudFront distribution
3. Normal requests succeed (HTTP 200)
4. Malicious requests blocked (HTTP 403)

---

**Duration:** 25 minutes | **Level:** Intermediate | **Cost:** ~$6.60/month

**Author:** Shashank Chinchli, AWS Solutions Architect

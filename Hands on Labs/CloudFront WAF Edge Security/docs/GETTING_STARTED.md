# Getting Started: AWS WAF CloudFront Edge Security

## Prerequisites

- AWS Account with admin permissions
- AWS CLI v2 configured
- Existing CloudFront distribution
- jq installed

## Step-by-Step Implementation

### Step 1: Set Environment Variables

```bash
export CF_ID="E1234567890ABC"
export AWS_REGION="us-east-1"
```

### Step 2: Deploy WAF

```bash
./scripts/deploy-waf.sh
```

### Step 3: Attach to CloudFront

```bash
./scripts/attach-waf.sh
```

### Step 4: Test Protection

```bash
./scripts/test-waf.sh
```

### Step 5: Cleanup (when done)

```bash
./scripts/cleanup.sh
```

---

**Duration:** 25 minutes | **Level:** Intermediate | **Cost:** ~$6.60/month

*Author: Shashank Chinchli, AWS Solutions Architect*

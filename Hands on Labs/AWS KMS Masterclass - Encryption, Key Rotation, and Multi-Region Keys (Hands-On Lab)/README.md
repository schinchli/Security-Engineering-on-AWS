# AWS KMS Masterclass: Symmetric and Asymmetric Encryption, Key Rotation, and Multi-Region Keys (Hands-On Lab)

[![AWS](https://img.shields.io/badge/AWS-Security-FF9900?logo=amazon-aws)](https://aws.amazon.com/security/)
[![KMS](https://img.shields.io/badge/Service-KMS-blue)](https://aws.amazon.com/kms/)
[![Encryption](https://img.shields.io/badge/Feature-Encryption-green)](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html)
[![Difficulty](https://img.shields.io/badge/Difficulty-Intermediate-yellow)]()
[![Duration](https://img.shields.io/badge/Duration-45%20mins-lightgrey)]()

> **Security Engineering on AWS** - Hands-on Lab Series
> **Level:** Intermediate | **Time:** 45 minutes | **Cost:** ~$4/month

---

Data encryption is the foundation of cloud security. AWS Key Management Service (KMS) provides a centralized, managed service to create, rotate, and control cryptographic keys used across 100+ AWS services and your own applications. This comprehensive lab teaches you how to implement symmetric and asymmetric encryption, enable automatic key rotation for compliance, and deploy multi-region keys for disaster recovery—all through hands-on practice with real AWS resources.

---

## Table of Contents

- [What Are We Building Today?](#what-are-we-building-today)
- [Why Is This Important?](#why-is-this-important)
- [AWS KMS Fundamentals](#aws-kms-fundamentals)
- [Symmetric vs Asymmetric Encryption](#symmetric-vs-asymmetric-encryption)
- [AWS Services Used](#aws-services-used)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Hands-On Labs](#hands-on-labs)
  - [Lab 1: Symmetric Key Encryption](#lab-1-symmetric-key-encryption-10-mins)
  - [Lab 2: Asymmetric Key Encryption](#lab-2-asymmetric-key-encryption-10-mins)
  - [Lab 3: Key Rotation](#lab-3-key-rotation-10-mins)
  - [Lab 4: Multi-Region Keys](#lab-4-multi-region-keys-15-mins)
- [Important KMS Actions Reference](#important-kms-actions-reference)
- [Envelope Encryption](#envelope-encryption)
- [KMS Key Policies](#kms-key-policies)
- [Cost Breakdown](#cost-breakdown)
- [What We Learned Today](#what-we-learned-today)
- [Best Practices](#best-practices)
- [AWS Well-Architected Alignment](#aws-well-architected-alignment)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)
- [AWS Documentation References](#aws-documentation-references)

---

## What Are We Building Today?

In this masterclass, we build **four hands-on encryption scenarios** using AWS KMS:

| Lab | What You'll Build | Key Concepts |
|-----|-------------------|--------------|
| **Lab 1** | Symmetric encryption system | AES-256-GCM, single-key encryption |
| **Lab 2** | Asymmetric encryption with PKI | RSA-2048, public/private key pairs |
| **Lab 3** | Automatic key rotation | Compliance, backward compatibility |
| **Lab 4** | Multi-region disaster recovery | Cross-region encryption, replicas |

By the end, you'll understand how to:
- Create and manage customer-managed KMS keys (CMKs)
- Encrypt and decrypt data using symmetric and asymmetric algorithms
- Enable automatic key rotation for compliance requirements
- Deploy multi-region keys for global applications and disaster recovery
- Apply least-privilege access controls to your encryption keys

---

## Why Is This Important?

### The Problem with Data Security

| Challenge | Risk | KMS Solution |
|-----------|------|--------------|
| Unencrypted data at rest | Data breach exposure | Automatic encryption with managed keys |
| Hardcoded encryption keys | Keys leaked in source control | Centralized key management |
| Manual key rotation | Compliance failures, stale keys | Automatic annual rotation |
| Single-region keys | Data unavailable during outages | Multi-region key replication |
| No audit trail | Compliance violations | CloudTrail integration |

### Real-World Use Cases

- **Financial Services**: PCI-DSS requires encryption of cardholder data
- **Healthcare**: HIPAA mandates encryption of Protected Health Information (PHI)
- **SaaS Applications**: Encrypt customer data with customer-managed keys
- **Global Applications**: Multi-region keys for low-latency encryption worldwide
- **Disaster Recovery**: Cross-region decryption for business continuity
- **DevOps Pipelines**: Secure secrets and configuration encryption

---

## AWS KMS Fundamentals

### What is AWS KMS?

AWS Key Management Service (KMS) is a fully managed service that enables you to create and control cryptographic keys for data encryption. KMS integrates with 100+ AWS services and provides:

- **Centralized Key Management**: Single location for all encryption keys
- **Hardware Security Modules (HSMs)**: FIPS 140-2 validated hardware protection
- **Automatic Rotation**: Annual key rotation without re-encrypting data
- **Audit Logging**: Every key use logged in CloudTrail
- **Fine-Grained Access Control**: IAM and key policies for authorization

### Key Types in AWS KMS

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        AWS KMS KEY TYPES                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────┐    ┌─────────────────────────────────────┐ │
│  │  AWS Managed Keys       │    │  Customer Managed Keys (CMKs)       │ │
│  │  ────────────────────   │    │  ─────────────────────────────────  │ │
│  │  • Created by AWS       │    │  • You create and control           │ │
│  │  • aws/s3, aws/ebs      │    │  • Full policy control              │ │
│  │  • Auto-rotated yearly  │    │  • Optional rotation                │ │
│  │  • No direct API access │    │  • $1.00/month per key              │ │
│  │  • FREE                 │    │  • Deletable (7-30 day wait)        │ │
│  └─────────────────────────┘    └─────────────────────────────────────┘ │
│                                                                          │
│  ┌─────────────────────────┐    ┌─────────────────────────────────────┐ │
│  │  AWS Owned Keys         │    │  Custom Key Stores                  │ │
│  │  ────────────────────   │    │  ─────────────────────────────────  │ │
│  │  • Used internally      │    │  • CloudHSM cluster backed          │ │
│  │  • Not visible to you   │    │  • External key store (XKS)         │ │
│  │  • No charges           │    │  • Full HSM control                 │ │
│  │  • Automatic rotation   │    │  • Additional costs                 │ │
│  └─────────────────────────┘    └─────────────────────────────────────┘ │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Symmetric vs Asymmetric Encryption

Understanding when to use symmetric vs asymmetric encryption is critical for designing secure systems.

### Symmetric Encryption

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     SYMMETRIC ENCRYPTION                                 │
│                     (Same key for both operations)                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│    Plaintext ─────► [ ENCRYPT ] ─────► Ciphertext                       │
│                          │                   │                           │
│                          │                   │                           │
│                     ┌────▼────┐         ┌────▼────┐                      │
│                     │ KMS Key │         │ KMS Key │                      │
│                     │ (Same)  │         │ (Same)  │                      │
│                     └────┬────┘         └────┬────┘                      │
│                          │                   │                           │
│                          │                   │                           │
│    Plaintext ◄───── [ DECRYPT ] ◄───── Ciphertext                       │
│                                                                          │
│    Algorithm: AES-256-GCM (SYMMETRIC_DEFAULT)                           │
│    Max Direct Encryption: 4 KB                                          │
│    Use Case: Encrypt data at rest, database encryption                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

| Attribute | Symmetric Key |
|-----------|---------------|
| **Key Spec** | `SYMMETRIC_DEFAULT` (AES-256-GCM) |
| **Key Usage** | `ENCRYPT_DECRYPT` |
| **Key Location** | Never leaves KMS unencrypted |
| **Max Data Size** | 4 KB directly (use envelope encryption for larger) |
| **Performance** | Faster than asymmetric |
| **Cost** | $0.03 per 10,000 requests |
| **Rotation** | Automatic rotation supported |
| **Best For** | Most encryption use cases |

### Asymmetric Encryption

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     ASYMMETRIC ENCRYPTION                                │
│                     (Different keys for each operation)                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│    Plaintext ─────► [ ENCRYPT ] ─────► Ciphertext                       │
│                          │                   │                           │
│                     ┌────▼────┐         ┌────▼────┐                      │
│                     │ PUBLIC  │         │ PRIVATE │                      │
│                     │   KEY   │         │   KEY   │                      │
│                     │(Download│         │(In KMS) │                      │
│                     │ able)   │         │         │                      │
│                     └─────────┘         └────┬────┘                      │
│                                              │                           │
│    Plaintext ◄───── [ DECRYPT ] ◄───────────┘                           │
│                                                                          │
│    Algorithms: RSA_2048, RSA_3072, RSA_4096, ECC variants               │
│    Max Data Size: Depends on key size (190 bytes for RSA_2048 + OAEP)   │
│    Use Case: Client-side encryption, digital signatures, PKI            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

| Attribute | Asymmetric Key |
|-----------|----------------|
| **Key Specs** | `RSA_2048`, `RSA_3072`, `RSA_4096`, `ECC_NIST_P256/P384/P521`, `ECC_SECG_P256K1` |
| **Key Usage** | `ENCRYPT_DECRYPT` or `SIGN_VERIFY` |
| **Public Key** | Downloadable, usable outside AWS |
| **Private Key** | Never leaves KMS |
| **Performance** | Slower than symmetric |
| **Cost** | $0.15 per 10,000 requests (RSA) |
| **Rotation** | Not supported |
| **Best For** | PKI, digital signatures, client-side encryption |

### Comparison Table

| Feature | Symmetric | Asymmetric |
|---------|-----------|------------|
| Keys | Single shared key | Public + Private key pair |
| Speed | Fast | Slower |
| Key Distribution | Must be shared securely | Public key can be shared openly |
| Direct Encryption Limit | 4 KB | ~190-446 bytes (RSA with OAEP) |
| Automatic Rotation | Yes | No |
| Use Outside AWS | No | Yes (public key) |
| Digital Signatures | No | Yes |
| Cost per 10K requests | $0.03 | $0.10-$0.15 |

---

## AWS Services Used

| Service | Purpose | What It Does |
|---------|---------|--------------|
| **AWS KMS** | Encryption | Creates, manages, and uses cryptographic keys |
| **AWS CloudTrail** | Auditing | Logs every KMS API call for compliance |
| **AWS IAM** | Access Control | Defines who can use which keys for what operations |

---

## Architecture Overview

### How KMS Encryption Works

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     KMS ENCRYPTION ARCHITECTURE                          │
└─────────────────────────────────────────────────────────────────────────┘

  ┌──────────────┐
  │ Application  │
  │   or User    │
  └──────┬───────┘
         │
         │ ① Encrypt/Decrypt Request
         ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │                         AWS KMS                                        │
  │  ┌────────────────────────────────────────────────────────────────┐  │
  │  │                    Key Management                                │  │
  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │  │
  │  │  │ Symmetric   │  │ Asymmetric  │  │ Multi-Region            │ │  │
  │  │  │ Keys        │  │ Keys        │  │ Keys                    │ │  │
  │  │  │ (AES-256)   │  │ (RSA/ECC)   │  │ (Same key in N regions) │ │  │
  │  │  └─────────────┘  └─────────────┘  └─────────────────────────┘ │  │
  │  └────────────────────────────────────────────────────────────────┘  │
  │                                                                        │
  │  ┌────────────────────────────────────────────────────────────────┐  │
  │  │                Hardware Security Modules (HSMs)                  │  │
  │  │                    FIPS 140-2 Level 3 Validated                  │  │
  │  │  ┌────────────┐  ┌────────────┐  ┌────────────┐                 │  │
  │  │  │    HSM     │  │    HSM     │  │    HSM     │                 │  │
  │  │  │  (Key 1)   │  │  (Key 2)   │  │  (Key N)   │                 │  │
  │  │  └────────────┘  └────────────┘  └────────────┘                 │  │
  │  └────────────────────────────────────────────────────────────────┘  │
  └──────────────────────────────────────────────────────────────────────┘
         │                                           │
         │ ② Encrypt/Decrypt                         │ ③ Log API Call
         ▼                                           ▼
  ┌──────────────┐                           ┌──────────────┐
  │  Ciphertext  │                           │  CloudTrail  │
  │   Returned   │                           │   (Audit)    │
  └──────────────┘                           └──────────────┘
```

### Multi-Region Key Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   MULTI-REGION KEY ARCHITECTURE                          │
└─────────────────────────────────────────────────────────────────────────┘

     ┌─────────────────────────┐         ┌─────────────────────────┐
     │       us-east-1          │         │       us-west-2          │
     │  ┌─────────────────────┐ │         │  ┌─────────────────────┐ │
     │  │   PRIMARY KEY       │ │ ◄─────► │  │   REPLICA KEY       │ │
     │  │   mrk-xxx           │ │  Same   │  │   mrk-yyy           │ │
     │  │                     │ │  Key    │  │                     │ │
     │  │   Key Material: A   │ │Material │  │   Key Material: A   │ │
     │  └─────────────────────┘ │         │  └─────────────────────┘ │
     │                          │         │                          │
     │  Encrypt() ─────────────►│         │◄───────────── Decrypt() │
     │  Decrypt() ◄─────────────│         │─────────────► Encrypt() │
     └─────────────────────────┘         └─────────────────────────┘
                                   │
                                   │
                                   ▼
                        ┌─────────────────────┐
                        │   Cross-Region      │
                        │   Encryption/       │
                        │   Decryption        │
                        │                     │
                        │   ✓ No API calls    │
                        │     across regions  │
                        │   ✓ Local latency   │
                        │   ✓ DR ready        │
                        └─────────────────────┘
```

---

## Prerequisites

Before starting, ensure you have:

- [ ] AWS CLI installed and configured (`aws --version`)
- [ ] jq installed for JSON parsing (`jq --version`)
- [ ] OpenSSL installed for asymmetric operations (`openssl version`)
- [ ] AWS account with KMS permissions
- [ ] Basic understanding of encryption concepts

**Verify your setup:**
```bash
# Check AWS CLI
aws --version

# Check jq
jq --version

# Check OpenSSL
openssl version

# Verify AWS credentials
aws sts get-caller-identity
```

---

## Hands-On Labs

### Lab 1: Symmetric Key Encryption (10 mins)

Symmetric encryption uses a single key for both encryption and decryption. This is the most common and cost-effective encryption method for data at rest.

#### Step 1.1: Create a Symmetric KMS Key

```bash
# Set variables
REGION="us-east-1"
KEY_ALIAS="alias/kms-lab-symmetric-key"

# Create the symmetric key (AES-256-GCM)
KEY_RESULT=$(aws kms create-key \
  --description "KMS Lab Symmetric Key for encryption" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --region $REGION)

# Extract Key ID
KEY_ID=$(echo "$KEY_RESULT" | jq -r '.KeyMetadata.KeyId')
echo "Key created: $KEY_ID"

# Create an alias for easier reference
aws kms create-alias \
  --alias-name $KEY_ALIAS \
  --target-key-id $KEY_ID \
  --region $REGION

echo "Alias created: $KEY_ALIAS"
```

**What this does:**
- Creates a customer-managed symmetric key using AES-256-GCM algorithm
- Creates an alias (friendly name) for the key
- Key material is generated and stored in FIPS 140-2 validated HSMs

#### Step 1.2: Encrypt Data

```bash
# Create sample data
echo "This is sensitive data that needs to be encrypted.
It could be customer PII, financial records, or health information." > plaintext-data.txt

# Encrypt the data
aws kms encrypt \
  --key-id $KEY_ALIAS \
  --plaintext fileb://plaintext-data.txt \
  --output text \
  --query CiphertextBlob \
  --region $REGION > encrypted-data.txt

echo "Data encrypted successfully!"
echo "Original size: $(wc -c < plaintext-data.txt) bytes"
echo "Encrypted size: $(wc -c < encrypted-data.txt) bytes"
```

#### Step 1.3: Decrypt Data

```bash
# Decrypt the data
aws kms decrypt \
  --ciphertext-blob fileb://encrypted-data.txt \
  --output text \
  --query Plaintext \
  --region $REGION | base64 --decode > decrypted-data.txt

echo "Data decrypted successfully!"
```

#### Step 1.4: Verify Integrity

```bash
# Verify decrypted data matches original
if diff plaintext-data.txt decrypted-data.txt > /dev/null; then
    echo "SUCCESS: Decrypted data matches original!"
else
    echo "ERROR: Data mismatch!"
fi
```

**Expected Output:**
```
Key created: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Alias created: alias/kms-lab-symmetric-key
Data encrypted successfully!
Original size: 142 bytes
Encrypted size: 248 bytes
Data decrypted successfully!
SUCCESS: Decrypted data matches original!
```

#### Quick Deploy Option

```bash
# Run the automated script
./scripts/symmetric-encryption-demo.sh
```

---

### Lab 2: Asymmetric Key Encryption (10 mins)

Asymmetric encryption uses a public-private key pair. The public key encrypts data, and only the private key (stored securely in KMS) can decrypt it.

#### Step 2.1: Create an Asymmetric KMS Key

```bash
# Set variables
REGION="us-east-1"
KEY_ALIAS="alias/kms-lab-asymmetric-key"

# Create asymmetric key (RSA-2048)
KEY_RESULT=$(aws kms create-key \
  --description "KMS Lab Asymmetric Key for encryption" \
  --key-usage ENCRYPT_DECRYPT \
  --key-spec RSA_2048 \
  --origin AWS_KMS \
  --region $REGION)

KEY_ID=$(echo "$KEY_RESULT" | jq -r '.KeyMetadata.KeyId')
echo "Asymmetric key created: $KEY_ID"

# Create alias
aws kms create-alias \
  --alias-name $KEY_ALIAS \
  --target-key-id $KEY_ID \
  --region $REGION
```

**What this does:**
- Creates an RSA-2048 asymmetric key pair
- Public key can be downloaded and used outside AWS
- Private key never leaves KMS

#### Step 2.2: Download Public Key

```bash
# Get public key in DER format
aws kms get-public-key \
  --key-id $KEY_ALIAS \
  --output text \
  --query PublicKey \
  --region $REGION | base64 --decode > public-key.der

# Convert to PEM format for OpenSSL
openssl rsa -pubin -inform DER -in public-key.der -outform PEM -out public-key.pem

echo "Public key saved to: public-key.pem"
cat public-key.pem
```

#### Step 2.3: Encrypt with Public Key (Client-Side)

```bash
# Create small data (RSA-2048 with OAEP-SHA256 limits to ~190 bytes)
echo "Secret API key: sk_live_abc123xyz" > small-plaintext.txt

# Encrypt using OpenSSL with the public key
openssl pkeyutl -encrypt \
  -pubin -inkey public-key.pem \
  -pkeyopt rsa_padding_mode:oaep \
  -pkeyopt rsa_oaep_md:sha256 \
  -in small-plaintext.txt \
  -out encrypted-asymmetric.bin

echo "Data encrypted with public key (client-side)"
```

**Key Insight:** This encryption happened entirely outside of AWS using only the public key. This is useful for client-side encryption where the client doesn't have AWS credentials.

#### Step 2.4: Decrypt with KMS Private Key

```bash
# Decrypt using KMS (private key never leaves KMS)
aws kms decrypt \
  --key-id $KEY_ALIAS \
  --ciphertext-blob fileb://encrypted-asymmetric.bin \
  --encryption-algorithm RSAES_OAEP_SHA_256 \
  --output text \
  --query Plaintext \
  --region $REGION | base64 --decode > decrypted-asymmetric.txt

echo "Data decrypted with KMS private key"
cat decrypted-asymmetric.txt
```

#### Step 2.5: Verify

```bash
if diff small-plaintext.txt decrypted-asymmetric.txt > /dev/null; then
    echo "SUCCESS: Asymmetric encryption/decryption verified!"
fi
```

#### Quick Deploy Option

```bash
./scripts/asymmetric-encryption-demo.sh
```

---

### Lab 3: Key Rotation (10 mins)

Key rotation is essential for security compliance. AWS KMS supports automatic annual rotation of symmetric keys while maintaining backward compatibility.

#### Step 3.1: Create a Key for Rotation

```bash
REGION="us-east-1"
KEY_ALIAS="alias/kms-lab-rotation-key"

# Create key
KEY_RESULT=$(aws kms create-key \
  --description "KMS Lab Key with Rotation" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --region $REGION)

KEY_ID=$(echo "$KEY_RESULT" | jq -r '.KeyMetadata.KeyId')

aws kms create-alias \
  --alias-name $KEY_ALIAS \
  --target-key-id $KEY_ID \
  --region $REGION

echo "Key created: $KEY_ID"
```

#### Step 3.2: Check Rotation Status

```bash
# Check current rotation status (disabled by default)
aws kms get-key-rotation-status \
  --key-id $KEY_ID \
  --region $REGION

# Output:
# {
#     "KeyRotationEnabled": false
# }
```

#### Step 3.3: Enable Automatic Rotation

```bash
# Enable automatic key rotation
aws kms enable-key-rotation \
  --key-id $KEY_ID \
  --region $REGION

echo "Automatic key rotation enabled"

# Verify rotation is enabled
aws kms get-key-rotation-status \
  --key-id $KEY_ID \
  --region $REGION
```

#### Step 3.4: Encrypt Data Before Rotation

```bash
# Encrypt data with current key material
echo "Data encrypted before rotation" > rotation-test.txt

aws kms encrypt \
  --key-id $KEY_ALIAS \
  --plaintext fileb://rotation-test.txt \
  --output text \
  --query CiphertextBlob \
  --region $REGION > encrypted-before-rotation.txt

echo "Data encrypted with current key material"
```

#### Step 3.5: Understand Rotation Behavior

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    HOW KEY ROTATION WORKS                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  BEFORE ROTATION (Day 0)                                                │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  Key ID: abc-123                                                   │  │
│  │  Key Material Version: v1 (active)                                 │  │
│  │  All encryptions use: v1                                           │  │
│  │  All decryptions use: v1                                           │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  AFTER ROTATION (Day 365)                                               │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  Key ID: abc-123 (SAME!)                                           │  │
│  │  Key Material Versions: v1 (retained), v2 (active)                 │  │
│  │  New encryptions use: v2                                           │  │
│  │  Decryption of old data: Automatically uses v1                     │  │
│  │  Decryption of new data: Uses v2                                   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  KEY BENEFITS:                                                          │
│  ✓ Key ID never changes (no application updates needed)                 │
│  ✓ Old ciphertext always decryptable (backward compatible)              │
│  ✓ Meets compliance requirements (PCI-DSS, HIPAA)                       │
│  ✓ No re-encryption required                                            │
│  ✓ Zero downtime                                                        │
│                                                                          │
│  LIMITATIONS:                                                           │
│  ✗ Only for symmetric keys with AWS-generated material                  │
│  ✗ Fixed 365-day rotation period (cannot customize)                     │
│  ✗ Not available for asymmetric keys                                    │
│  ✗ Not available for imported key material                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Step 3.6: Verify Decryption After Rotation Enabled

```bash
# Even after rotation is enabled, old ciphertext still decrypts
aws kms decrypt \
  --ciphertext-blob fileb://encrypted-before-rotation.txt \
  --output text \
  --query Plaintext \
  --region $REGION | base64 --decode > decrypted-after-rotation.txt

if diff rotation-test.txt decrypted-after-rotation.txt > /dev/null; then
    echo "SUCCESS: Old ciphertext still decrypts after rotation enabled!"
fi
```

#### Quick Deploy Option

```bash
./scripts/key-rotation-demo.sh
```

---

### Lab 4: Multi-Region Keys (15 mins)

Multi-region keys allow you to encrypt data in one AWS region and decrypt it in another, without cross-region API calls. This is essential for disaster recovery and global applications.

#### Step 4.1: Create Multi-Region Primary Key

```bash
PRIMARY_REGION="us-east-1"
REPLICA_REGION="us-west-2"
KEY_ALIAS="alias/kms-lab-mrk"

# Create multi-region PRIMARY key
PRIMARY_KEY_RESULT=$(aws kms create-key \
  --description "KMS Lab Multi-Region Primary Key" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --multi-region \
  --region $PRIMARY_REGION)

PRIMARY_KEY_ID=$(echo "$PRIMARY_KEY_RESULT" | jq -r '.KeyMetadata.KeyId')
echo "Primary key created: $PRIMARY_KEY_ID (in $PRIMARY_REGION)"

# Create alias in primary region
aws kms create-alias \
  --alias-name $KEY_ALIAS \
  --target-key-id $PRIMARY_KEY_ID \
  --region $PRIMARY_REGION
```

**What this does:**
- Creates a multi-region primary key (note the `mrk-` prefix in key ID)
- Primary key can create replicas in other regions

#### Step 4.2: Replicate Key to Another Region

```bash
# Replicate key to us-west-2
REPLICA_KEY_RESULT=$(aws kms replicate-key \
  --key-id $PRIMARY_KEY_ID \
  --replica-region $REPLICA_REGION \
  --description "KMS Lab Multi-Region Replica Key" \
  --region $PRIMARY_REGION)

REPLICA_KEY_ID=$(echo "$REPLICA_KEY_RESULT" | jq -r '.ReplicaKeyMetadata.KeyId')
echo "Replica key created: $REPLICA_KEY_ID (in $REPLICA_REGION)"

# Wait for replica to be ready
sleep 5

# Create alias in replica region
aws kms create-alias \
  --alias-name $KEY_ALIAS \
  --target-key-id $REPLICA_KEY_ID \
  --region $REPLICA_REGION
```

#### Step 4.3: Encrypt in Primary Region

```bash
# Create test data
echo "Multi-region encrypted data for disaster recovery" > mrk-test.txt

# Encrypt in primary region (us-east-1)
aws kms encrypt \
  --key-id $KEY_ALIAS \
  --plaintext fileb://mrk-test.txt \
  --output text \
  --query CiphertextBlob \
  --region $PRIMARY_REGION > encrypted-in-primary.txt

echo "Data encrypted in $PRIMARY_REGION"
```

#### Step 4.4: Decrypt in Replica Region

```bash
# Decrypt in replica region (us-west-2) - NO cross-region API call needed!
aws kms decrypt \
  --ciphertext-blob fileb://encrypted-in-primary.txt \
  --output text \
  --query Plaintext \
  --region $REPLICA_REGION | base64 --decode > decrypted-in-replica.txt

echo "Data decrypted in $REPLICA_REGION"

# Verify
if diff mrk-test.txt decrypted-in-replica.txt > /dev/null; then
    echo "SUCCESS: Cross-region encryption/decryption works!"
fi
```

#### Step 4.5: Test Bidirectional Operation

```bash
# Encrypt in replica region
echo "Reverse direction test" > reverse-test.txt

aws kms encrypt \
  --key-id $KEY_ALIAS \
  --plaintext fileb://reverse-test.txt \
  --output text \
  --query CiphertextBlob \
  --region $REPLICA_REGION > encrypted-in-replica.txt

# Decrypt in primary region
aws kms decrypt \
  --ciphertext-blob fileb://encrypted-in-replica.txt \
  --output text \
  --query Plaintext \
  --region $PRIMARY_REGION | base64 --decode > decrypted-in-primary.txt

if diff reverse-test.txt decrypted-in-primary.txt > /dev/null; then
    echo "SUCCESS: Bidirectional cross-region encryption works!"
fi
```

#### Step 4.6: View Key Relationship

```bash
# View primary key details
echo "Primary Key ($PRIMARY_REGION):"
aws kms describe-key --key-id $PRIMARY_KEY_ID --region $PRIMARY_REGION | jq '{
  KeyId: .KeyMetadata.KeyId,
  MultiRegion: .KeyMetadata.MultiRegion,
  KeyType: .KeyMetadata.MultiRegionConfiguration.MultiRegionKeyType,
  PrimaryRegion: .KeyMetadata.MultiRegionConfiguration.PrimaryKey.Region,
  ReplicaRegions: [.KeyMetadata.MultiRegionConfiguration.ReplicaKeys[].Region]
}'

# View replica key details
echo "Replica Key ($REPLICA_REGION):"
aws kms describe-key --key-id $REPLICA_KEY_ID --region $REPLICA_REGION | jq '{
  KeyId: .KeyMetadata.KeyId,
  MultiRegion: .KeyMetadata.MultiRegion,
  KeyType: .KeyMetadata.MultiRegionConfiguration.MultiRegionKeyType,
  PrimaryRegion: .KeyMetadata.MultiRegionConfiguration.PrimaryKey.Region
}'
```

#### Quick Deploy Option

```bash
./scripts/multi-region-keys-demo.sh
```

---

## Important KMS Actions Reference

### Key Management Actions

| Action | Description | Use Case |
|--------|-------------|----------|
| `CreateKey` | Create a new KMS key | Initial key setup |
| `CreateAlias` | Create friendly name for key | Easier key reference |
| `DescribeKey` | Get key metadata | Audit, troubleshooting |
| `ListKeys` | List all keys in account | Inventory |
| `EnableKey` | Enable a disabled key | Re-activate key |
| `DisableKey` | Disable a key | Temporary deactivation |
| `ScheduleKeyDeletion` | Delete key (7-30 day wait) | Key retirement |
| `CancelKeyDeletion` | Cancel scheduled deletion | Recovery |

### Cryptographic Actions

| Action | Description | Key Type |
|--------|-------------|----------|
| `Encrypt` | Encrypt up to 4 KB data | Symmetric, Asymmetric |
| `Decrypt` | Decrypt ciphertext | Symmetric, Asymmetric |
| `ReEncrypt` | Re-encrypt without exposing plaintext | Symmetric |
| `GenerateDataKey` | Generate data encryption key (DEK) | Symmetric |
| `GenerateDataKeyWithoutPlaintext` | Generate encrypted DEK only | Symmetric |
| `GenerateRandom` | Generate random bytes | N/A |

### Key Rotation Actions

| Action | Description |
|--------|-------------|
| `EnableKeyRotation` | Enable automatic annual rotation |
| `DisableKeyRotation` | Disable automatic rotation |
| `GetKeyRotationStatus` | Check if rotation is enabled |
| `RotateKeyOnDemand` | Trigger immediate rotation (2024 feature) |

### Multi-Region Actions

| Action | Description |
|--------|-------------|
| `ReplicateKey` | Create replica in another region |
| `UpdatePrimaryRegion` | Promote replica to primary |

### Asymmetric Key Actions

| Action | Description |
|--------|-------------|
| `GetPublicKey` | Download public key |
| `Sign` | Create digital signature |
| `Verify` | Verify digital signature |

### Policy and Grant Actions

| Action | Description |
|--------|-------------|
| `GetKeyPolicy` | Get key's resource policy |
| `PutKeyPolicy` | Update key's resource policy |
| `CreateGrant` | Grant temporary permissions |
| `RetireGrant` | Remove a grant |
| `RevokeGrant` | Revoke a grant immediately |

---

## Envelope Encryption

For data larger than 4 KB, use envelope encryption with data keys.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      ENVELOPE ENCRYPTION                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Step 1: Generate Data Key                                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  aws kms generate-data-key --key-id alias/my-key                 │   │
│  │                                                                   │   │
│  │  Returns:                                                         │   │
│  │  ├── Plaintext DEK (use to encrypt, then delete!)                │   │
│  │  └── Encrypted DEK (store with your ciphertext)                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  Step 2: Encrypt Large Data                                             │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Large File ──► [OpenSSL/SDK encrypts with Plaintext DEK]        │   │
│  │                         │                                         │   │
│  │                         ▼                                         │   │
│  │                 Encrypted File                                    │   │
│  │                         +                                         │   │
│  │                 Encrypted DEK (metadata)                          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  Step 3: Decrypt Large Data                                             │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  aws kms decrypt --ciphertext-blob [Encrypted DEK]               │   │
│  │                         │                                         │   │
│  │                         ▼                                         │   │
│  │                 Plaintext DEK (temporary)                         │   │
│  │                         │                                         │   │
│  │  [OpenSSL/SDK decrypts file with Plaintext DEK]                  │   │
│  │                         │                                         │   │
│  │                         ▼                                         │   │
│  │                 Decrypted File                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Example: Envelope Encryption for Large Files

```bash
# Generate data key
aws kms generate-data-key \
  --key-id alias/kms-lab-symmetric-key \
  --key-spec AES_256 \
  --region us-east-1 > data-key.json

# Extract plaintext key (32 bytes = 256 bits)
PLAINTEXT_KEY=$(cat data-key.json | jq -r '.Plaintext')

# Encrypt large file with OpenSSL using the plaintext DEK
echo $PLAINTEXT_KEY | base64 --decode > temp-key.bin
openssl enc -aes-256-cbc -salt -in large-file.txt -out large-file.enc -pass file:temp-key.bin

# Store encrypted DEK alongside the encrypted file
cat data-key.json | jq -r '.CiphertextBlob' > large-file.enc.key

# Delete plaintext key from memory/disk!
rm temp-key.bin
unset PLAINTEXT_KEY
```

---

## KMS Key Policies

### Default Key Policy (Full Admin Access)

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "Enable IAM User Permissions",
    "Effect": "Allow",
    "Principal": {"AWS": "arn:aws:iam::ACCOUNT_ID:root"},
    "Action": "kms:*",
    "Resource": "*"
  }]
}
```

### Least Privilege Policy (Production)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowKeyAdministration",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::ACCOUNT_ID:role/KMSAdminRole"},
      "Action": [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowEncryption",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::ACCOUNT_ID:role/AppRole"},
      "Action": [
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowDecryption",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::ACCOUNT_ID:role/AppRole"},
      "Action": "kms:Decrypt",
      "Resource": "*"
    },
    {
      "Sid": "AllowSecretsManagerIntegration",
      "Effect": "Allow",
      "Principal": {"Service": "secretsmanager.amazonaws.com"},
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:CallerAccount": "ACCOUNT_ID"
        }
      }
    }
  ]
}
```

---

## Cost Breakdown

| Resource | Cost | Notes |
|----------|------|-------|
| **Customer Managed Keys** | $1.00/month per key | Prorated daily |
| **Symmetric API Requests** | $0.03 per 10,000 | First 20,000/month free |
| **RSA API Requests** | $0.15 per 10,000 | No free tier |
| **ECC API Requests** | $0.10 per 10,000 | No free tier |

### Lab Cost Estimate

| What | Cost |
|------|------|
| 4 KMS keys (1 month) | $4.00 |
| API requests (lab usage) | ~$0.10 |
| **Total** | **~$4.10** |

### Cost Optimization Tips

1. **Use AWS managed keys** when customer control isn't required (free)
2. **Delete unused keys** after the 7-day waiting period
3. **Use symmetric keys** for most use cases (cheaper than asymmetric)
4. **Cache data keys** when using envelope encryption
5. **Enable rotation** instead of creating new keys (no additional cost)

---

## What We Learned Today

| Concept | What You Now Know |
|---------|-------------------|
| **Symmetric Encryption** | Single-key AES-256-GCM encryption for data at rest |
| **Asymmetric Encryption** | Public/private key pairs for PKI and client-side encryption |
| **Key Rotation** | Automatic annual rotation without re-encryption |
| **Multi-Region Keys** | Cross-region encryption for disaster recovery |
| **Envelope Encryption** | Encrypt large data using data keys |
| **Key Policies** | Resource-based policies for fine-grained access control |
| **CloudTrail Integration** | Audit logging for compliance |

---

## Best Practices

### Do's

| Practice | Why |
|----------|-----|
| Use symmetric keys by default | Faster, cheaper, sufficient for most cases |
| Enable automatic key rotation | Compliance and security hygiene |
| Use key aliases | Easier to manage and rotate |
| Implement least privilege | Only grant necessary permissions |
| Use envelope encryption for large data | KMS direct encryption limited to 4 KB |
| Enable CloudTrail | Audit all key usage |
| Use multi-region keys for DR | Ensure decryption during regional outages |
| Tag all keys | Cost allocation and organization |

### Don'ts

| Anti-Pattern | Risk |
|--------------|------|
| Share KMS keys across accounts without grants | Security boundary violations |
| Disable keys without testing | Application failures |
| Use asymmetric keys for large data encryption | Performance and cost issues |
| Skip the deletion waiting period | Accidental data loss |
| Embed key IDs in code | Hard to rotate or change |
| Use imported key material without backups | Permanent data loss if material lost |

---

## AWS Well-Architected Alignment

This lab implements practices from the [AWS Well-Architected Framework - Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html):

| Principle | How This Lab Implements It |
|-----------|---------------------------|
| **SEC01** - Operate workloads securely | Customer-managed encryption keys |
| **SEC07** - Protect data at rest | KMS encryption for all data |
| **SEC08** - Classify data | Separate keys for different data classifications |
| **SEC09** - Protect data in transit | TLS for all KMS API calls |
| **SEC10** - Anticipate incidents | CloudTrail logging, key rotation |

---

## Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| `AccessDeniedException` | IAM or key policy denies access | Check IAM permissions and key policy |
| `InvalidCiphertextException` | Wrong key or corrupted data | Verify correct key and ciphertext integrity |
| `DisabledException` | Key is disabled | `aws kms enable-key --key-id <KEY_ID>` |
| `KMSInvalidStateException` | Key pending deletion | `aws kms cancel-key-deletion --key-id <KEY_ID>` |
| `NotFoundException` | Key or alias doesn't exist | Check key ID/alias and region |
| `DependencyTimeoutException` | KMS service issue | Retry with exponential backoff |
| `LimitExceededException` | Too many requests | Implement request throttling |

### Debug Commands

```bash
# Check key state
aws kms describe-key --key-id alias/my-key --query 'KeyMetadata.KeyState'

# List all keys
aws kms list-keys

# List all aliases
aws kms list-aliases

# Check key rotation status
aws kms get-key-rotation-status --key-id alias/my-key

# View key policy
aws kms get-key-policy --key-id alias/my-key --policy-name default
```

---

## Cleanup

**Important:** Delete resources when done to avoid charges.

```bash
./scripts/cleanup.sh
```

Or manually:

```bash
# Schedule key deletions (minimum 7-day wait)
aws kms schedule-key-deletion --key-id alias/kms-lab-symmetric-key --pending-window-in-days 7 --region us-east-1
aws kms schedule-key-deletion --key-id alias/kms-lab-asymmetric-key --pending-window-in-days 7 --region us-east-1
aws kms schedule-key-deletion --key-id alias/kms-lab-rotation-key --pending-window-in-days 7 --region us-east-1

# For multi-region keys, delete replica first, then primary
aws kms schedule-key-deletion --key-id alias/kms-lab-mrk --pending-window-in-days 7 --region us-west-2
aws kms schedule-key-deletion --key-id alias/kms-lab-mrk --pending-window-in-days 7 --region us-east-1

# Delete local files
rm -f *.txt *.bin *.der *.pem *.json
```

---

## Next Steps

After completing this lab, explore:

1. **AWS Secrets Manager Integration**: Use KMS to encrypt secrets
2. **S3 Server-Side Encryption**: Configure S3 buckets with KMS
3. **EBS Volume Encryption**: Encrypt EC2 storage with KMS
4. **CloudHSM Integration**: Use dedicated HSMs for higher compliance
5. **Custom Key Stores**: External key store (XKS) for keys outside AWS
6. **Automated Key Policies**: Infrastructure as Code with CloudFormation/Terraform

---

## Project Structure

```
AWS KMS Masterclass.../
├── README.md                           # This file
├── images/
│   └── aws-kms-architecture.png        # Architecture diagrams
├── scripts/
│   ├── symmetric-encryption-demo.sh    # Lab 1 automation
│   ├── asymmetric-encryption-demo.sh   # Lab 2 automation
│   ├── key-rotation-demo.sh            # Lab 3 automation
│   ├── multi-region-keys-demo.sh       # Lab 4 automation
│   └── cleanup.sh                      # Resource cleanup
├── configs/
│   └── kms-key-policy.json             # Sample key policy
├── data/
│   └── plaintext-data.txt              # Sample data for encryption
└── COMMANDS.md                         # Quick command reference
```

---

## AWS Documentation References

| Topic | Link |
|-------|------|
| AWS KMS Developer Guide | [docs.aws.amazon.com/kms](https://docs.aws.amazon.com/kms/latest/developerguide/) |
| KMS Best Practices | [Best Practices Guide](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html) |
| KMS API Reference | [API Reference](https://docs.aws.amazon.com/kms/latest/APIReference/) |
| Multi-Region Keys | [MRK Guide](https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html) |
| Key Rotation | [Rotation Guide](https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html) |
| Envelope Encryption | [Envelope Guide](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#enveloping) |
| KMS Pricing | [Pricing Page](https://aws.amazon.com/kms/pricing/) |

---

## Contributing

Found an issue or want to improve this lab?

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

**Guidelines:**
- Test all scripts before submitting
- Follow existing documentation style
- No credentials in code

---

**Don't just read—build.** The most effective way to master AWS encryption is through hands-on practice. Deploy these labs, experiment freely, intentionally break things, fix them, and develop a deep, practical understanding of how AWS KMS protects data across your entire infrastructure. This is where theory transforms into intuition—and learning becomes a lasting skill.

**Happy Learning!**

Created by **[Learn Cloud with Shashank](https://www.linkedin.com/in/shashankk/)**, an AWS Solutions Architect and Golden Jacket Holder, as part of the *Security Engineering on AWS Hands-on Labs Series*.

---

## License

MIT License - Free to use for learning and commercial projects.

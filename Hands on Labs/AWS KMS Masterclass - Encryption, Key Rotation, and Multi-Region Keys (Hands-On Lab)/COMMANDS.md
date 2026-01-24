# AWS KMS Quick Command Reference

A quick reference guide for common AWS KMS operations used in this lab.

---

## Test Your Setup (No Resources Created)

```bash
# Verify AWS CLI is configured
aws sts get-caller-identity

# List existing KMS keys
aws kms list-keys --region us-east-1

# List key aliases
aws kms list-aliases --region us-east-1

# Generate random data (test KMS connectivity)
aws kms generate-random --number-of-bytes 32 --output text --query 'Plaintext'
```

---

## Run All Lab Demos

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Lab 1: Symmetric Encryption
./scripts/symmetric-encryption-demo.sh

# Lab 2: Asymmetric Encryption
./scripts/asymmetric-encryption-demo.sh

# Lab 3: Key Rotation
./scripts/key-rotation-demo.sh

# Lab 4: Multi-Region Keys
./scripts/multi-region-keys-demo.sh

# Cleanup all resources
./scripts/cleanup.sh
```

---

## Key Management Commands

### Create Keys

```bash
# Create symmetric key (default, AES-256)
aws kms create-key \
  --description "My Symmetric Key" \
  --region us-east-1

# Create asymmetric key (RSA-2048)
aws kms create-key \
  --description "My Asymmetric Key" \
  --key-spec RSA_2048 \
  --key-usage ENCRYPT_DECRYPT \
  --region us-east-1

# Create multi-region key
aws kms create-key \
  --description "My Multi-Region Key" \
  --multi-region \
  --region us-east-1
```

### Manage Aliases

```bash
# Create alias
aws kms create-alias \
  --alias-name alias/my-key \
  --target-key-id <KEY_ID> \
  --region us-east-1

# Update alias (point to different key)
aws kms update-alias \
  --alias-name alias/my-key \
  --target-key-id <NEW_KEY_ID> \
  --region us-east-1

# Delete alias
aws kms delete-alias \
  --alias-name alias/my-key \
  --region us-east-1
```

### Key Information

```bash
# Describe key
aws kms describe-key --key-id alias/my-key --region us-east-1

# Get key state
aws kms describe-key --key-id alias/my-key \
  --query 'KeyMetadata.KeyState' \
  --output text

# Get key policy
aws kms get-key-policy \
  --key-id alias/my-key \
  --policy-name default \
  --region us-east-1
```

---

## Encryption Operations

### Symmetric Encryption

```bash
# Encrypt data (up to 4KB)
aws kms encrypt \
  --key-id alias/my-key \
  --plaintext fileb://data.txt \
  --output text \
  --query CiphertextBlob \
  --region us-east-1 > encrypted.txt

# Decrypt data
aws kms decrypt \
  --ciphertext-blob fileb://encrypted.txt \
  --output text \
  --query Plaintext \
  --region us-east-1 | base64 --decode > decrypted.txt
```

### Asymmetric Encryption

```bash
# Get public key
aws kms get-public-key \
  --key-id alias/my-asymmetric-key \
  --output text \
  --query PublicKey \
  --region us-east-1 | base64 --decode > public-key.der

# Convert to PEM
openssl rsa -pubin -inform DER -in public-key.der -outform PEM -out public-key.pem

# Encrypt with OpenSSL (client-side)
openssl pkeyutl -encrypt \
  -pubin -inkey public-key.pem \
  -pkeyopt rsa_padding_mode:oaep \
  -pkeyopt rsa_oaep_md:sha256 \
  -in data.txt \
  -out encrypted.bin

# Decrypt with KMS
aws kms decrypt \
  --key-id alias/my-asymmetric-key \
  --ciphertext-blob fileb://encrypted.bin \
  --encryption-algorithm RSAES_OAEP_SHA_256 \
  --output text \
  --query Plaintext \
  --region us-east-1 | base64 --decode > decrypted.txt
```

### Envelope Encryption (Large Files)

```bash
# Generate data key
aws kms generate-data-key \
  --key-id alias/my-key \
  --key-spec AES_256 \
  --region us-east-1 > data-key.json

# Extract plaintext key
PLAINTEXT_KEY=$(cat data-key.json | jq -r '.Plaintext')
echo $PLAINTEXT_KEY | base64 --decode > temp-key.bin

# Encrypt large file with OpenSSL
openssl enc -aes-256-cbc -salt \
  -in large-file.txt \
  -out large-file.enc \
  -pass file:temp-key.bin

# Store encrypted data key
cat data-key.json | jq -r '.CiphertextBlob' > encrypted-data-key.txt

# Clean up plaintext key!
rm temp-key.bin
```

---

## Key Rotation Commands

```bash
# Check rotation status
aws kms get-key-rotation-status \
  --key-id alias/my-key \
  --region us-east-1

# Enable rotation
aws kms enable-key-rotation \
  --key-id alias/my-key \
  --region us-east-1

# Disable rotation
aws kms disable-key-rotation \
  --key-id alias/my-key \
  --region us-east-1

# Rotate on demand (immediate rotation)
aws kms rotate-key-on-demand \
  --key-id alias/my-key \
  --region us-east-1
```

---

## Multi-Region Key Commands

```bash
# Replicate key to another region
aws kms replicate-key \
  --key-id <PRIMARY_KEY_ID> \
  --replica-region us-west-2 \
  --region us-east-1

# Update primary region (promote replica)
aws kms update-primary-region \
  --key-id <REPLICA_KEY_ID> \
  --primary-region us-west-2 \
  --region us-east-1
```

---

## Key Lifecycle Commands

```bash
# Disable key (temporary)
aws kms disable-key \
  --key-id alias/my-key \
  --region us-east-1

# Enable key
aws kms enable-key \
  --key-id alias/my-key \
  --region us-east-1

# Schedule deletion (7-30 days)
aws kms schedule-key-deletion \
  --key-id alias/my-key \
  --pending-window-in-days 7 \
  --region us-east-1

# Cancel scheduled deletion
aws kms cancel-key-deletion \
  --key-id alias/my-key \
  --region us-east-1
```

---

## Troubleshooting Commands

```bash
# Check key state
aws kms describe-key \
  --key-id alias/my-key \
  --query 'KeyMetadata.{State:KeyState,Enabled:Enabled,DeletionDate:DeletionDate}'

# List grants on a key
aws kms list-grants \
  --key-id alias/my-key \
  --region us-east-1

# Check CloudTrail for KMS events (last 10)
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventSource,AttributeValue=kms.amazonaws.com \
  --max-results 10 \
  --region us-east-1

# View key policy
aws kms get-key-policy \
  --key-id alias/my-key \
  --policy-name default \
  --output text \
  --region us-east-1
```

---

## Cost Monitoring

```bash
# List all customer managed keys (chargeable)
aws kms list-keys --region us-east-1 | jq '.Keys | length'

# Check key creation dates
aws kms list-keys --region us-east-1 | jq -r '.Keys[].KeyId' | while read key; do
  echo -n "$key: "
  aws kms describe-key --key-id $key --region us-east-1 \
    --query 'KeyMetadata.CreationDate' --output text
done
```

---

## Quick Test Workflow

```bash
# 1. Create key
KEY_ID=$(aws kms create-key --description "Quick Test" --region us-east-1 \
  --query 'KeyMetadata.KeyId' --output text)
echo "Key: $KEY_ID"

# 2. Create alias
aws kms create-alias --alias-name alias/quick-test --target-key-id $KEY_ID --region us-east-1

# 3. Encrypt
echo "Secret data" > test.txt
aws kms encrypt --key-id alias/quick-test --plaintext fileb://test.txt \
  --output text --query CiphertextBlob --region us-east-1 > encrypted.txt

# 4. Decrypt
aws kms decrypt --ciphertext-blob fileb://encrypted.txt \
  --output text --query Plaintext --region us-east-1 | base64 --decode

# 5. Cleanup
aws kms schedule-key-deletion --key-id $KEY_ID --pending-window-in-days 7 --region us-east-1
rm test.txt encrypted.txt
```

---

## Lab Keys Reference

| Lab | Key Alias | Type |
|-----|-----------|------|
| Lab 1 | `alias/kms-lab-symmetric-key` | Symmetric (AES-256) |
| Lab 2 | `alias/kms-lab-asymmetric-key` | Asymmetric (RSA-2048) |
| Lab 3 | `alias/kms-lab-rotation-key` | Symmetric with rotation |
| Lab 4 | `alias/kms-lab-mrk` | Multi-region (us-east-1 + us-west-2) |

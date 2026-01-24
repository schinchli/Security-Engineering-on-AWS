#!/bin/bash
# AWS KMS Symmetric Key Encryption Demo
# Part of: AWS KMS Masterclass - Hands-On Lab
#
# This script demonstrates symmetric encryption using AWS KMS.
# Symmetric keys use the same key for both encryption and decryption.

set -e

# Change to lab root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"
cd "$LAB_DIR"

REGION="us-east-1"
KEY_ALIAS="alias/kms-lab-symmetric-key"

echo "========================================================"
echo "   AWS KMS SYMMETRIC KEY ENCRYPTION DEMO"
echo "   Lab 1: Single-Key AES-256-GCM Encryption"
echo "========================================================"
echo ""
echo "📋 What you'll learn:"
echo "   - Create a symmetric KMS key (AES-256-GCM)"
echo "   - Encrypt data using the KMS key"
echo "   - Decrypt ciphertext back to plaintext"
echo "   - Verify data integrity"
echo ""

# Step 1: Create symmetric KMS key
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Creating symmetric KMS key..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
KEY_RESULT=$(aws kms create-key \
  --description "KMS Lab Symmetric Key for encryption" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --region $REGION)

KEY_ID=$(echo "$KEY_RESULT" | jq -r '.KeyMetadata.KeyId')
echo "✅ Key created: $KEY_ID"
echo "   Algorithm: AES-256-GCM (SYMMETRIC_DEFAULT)"
echo "   Key Usage: ENCRYPT_DECRYPT"
echo ""

# Create alias
echo "📦 Creating alias for easier reference..."
aws kms create-alias \
  --alias-name $KEY_ALIAS \
  --target-key-id $KEY_ID \
  --region $REGION
echo "✅ Alias created: $KEY_ALIAS"
echo ""

# Step 2: Encrypt data
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Encrypting plaintext data..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📄 Original data (data/plaintext-data.txt):"
head -3 data/plaintext-data.txt
echo "   ..."
echo ""

aws kms encrypt \
  --key-id $KEY_ALIAS \
  --plaintext fileb://data/plaintext-data.txt \
  --region $REGION \
  --query CiphertextBlob \
  --output text | base64 --decode > encrypted-data-symmetric.txt

ORIGINAL_SIZE=$(wc -c < data/plaintext-data.txt | tr -d ' ')
ENCRYPTED_SIZE=$(wc -c < encrypted-data-symmetric.txt | tr -d ' ')

echo "✅ Data encrypted successfully!"
echo "   Original size: $ORIGINAL_SIZE bytes"
echo "   Encrypted size: $ENCRYPTED_SIZE bytes (Base64 encoded)"
echo "   Output file: encrypted-data-symmetric.txt"
echo ""

# Step 3: Decrypt data
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Decrypting data..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
aws kms decrypt \
  --ciphertext-blob fileb://encrypted-data-symmetric.txt \
  --region $REGION \
  --query Plaintext \
  --output text | base64 --decode > decrypted-data-symmetric.txt

echo "✅ Data decrypted successfully!"
echo "   Output file: decrypted-data-symmetric.txt"
echo ""

# Step 4: Verify
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Verifying data integrity..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if diff data/plaintext-data.txt decrypted-data-symmetric.txt > /dev/null; then
    echo "✅ SUCCESS: Decrypted data matches original!"
    echo ""
    echo "📄 Decrypted content (first 3 lines):"
    head -3 decrypted-data-symmetric.txt
else
    echo "❌ ERROR: Decrypted data does not match original"
    exit 1
fi
echo ""

# Display key info
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Key Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
aws kms describe-key --key-id $KEY_ALIAS --region $REGION | jq '.KeyMetadata | {KeyId, KeyState, KeyUsage, KeySpec, Origin, CreationDate}'
echo ""

echo "========================================================"
echo "   LAB 1 COMPLETE: Symmetric Encryption Demo"
echo "========================================================"
echo ""
echo "📋 Summary:"
echo "   Key ID: $KEY_ID"
echo "   Key Alias: $KEY_ALIAS"
echo "   Key Type: Symmetric (AES-256-GCM)"
echo ""
echo "📁 Files Created:"
echo "   encrypted-data-symmetric.txt  (ciphertext)"
echo "   decrypted-data-symmetric.txt  (recovered plaintext)"
echo ""
echo "💡 Key Insight:"
echo "   Symmetric keys are ideal for encrypting data at rest."
echo "   The same key is used for both encryption and decryption."
echo "   KMS never exposes the key material - all operations happen in HSMs."
echo ""
echo "🧹 To cleanup: ./scripts/cleanup.sh"
echo ""

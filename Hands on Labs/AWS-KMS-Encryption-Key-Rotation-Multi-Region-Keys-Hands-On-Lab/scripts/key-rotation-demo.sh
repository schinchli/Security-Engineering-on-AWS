#!/bin/bash
# AWS KMS Key Rotation Demo
# Part of: AWS KMS Masterclass - Hands-On Lab
#
# This script demonstrates automatic key rotation for compliance.
# Key material rotates annually, but old ciphertext remains decryptable.

set -e

# Change to lab root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"
cd "$LAB_DIR"

REGION="us-east-1"
KEY_ALIAS="alias/kms-lab-rotation-key"

echo "========================================================"
echo "   AWS KMS KEY ROTATION DEMO"
echo "   Lab 3: Automatic Annual Key Rotation"
echo "========================================================"
echo ""
echo "What you'll learn:"
echo "   - Enable automatic key rotation on KMS keys"
echo "   - Understand how rotation maintains backward compatibility"
echo "   - Verify old ciphertext decrypts after rotation"
echo ""

# Step 1: Create KMS key
echo "Step 1: Creating KMS key..."
echo "------------------------------------------------------------"
KEY_RESULT=$(aws kms create-key \
  --description "KMS Lab Key with Rotation" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --region $REGION)

KEY_ID=$(echo "$KEY_RESULT" | jq -r '.KeyMetadata.KeyId')
echo "Key created: $KEY_ID"
echo ""

# Create alias
echo "Creating alias..."
aws kms create-alias \
  --alias-name $KEY_ALIAS \
  --target-key-id $KEY_ID \
  --region $REGION
echo "Alias created: $KEY_ALIAS"
echo ""

# Step 2: Check rotation status (disabled by default)
echo "Step 2: Checking initial rotation status..."
echo "------------------------------------------------------------"
ROTATION_STATUS=$(aws kms get-key-rotation-status \
  --key-id $KEY_ID \
  --region $REGION \
  --query 'KeyRotationEnabled' \
  --output text)
echo "Current rotation status: $ROTATION_STATUS"
echo "   (Rotation is disabled by default for new keys)"
echo ""

# Step 3: Enable automatic key rotation
echo "Step 3: Enabling automatic key rotation..."
echo "------------------------------------------------------------"
aws kms enable-key-rotation \
  --key-id $KEY_ID \
  --region $REGION
echo "Automatic key rotation enabled!"
echo "   Key will rotate automatically every 365 days."
echo ""

# Step 4: Verify rotation is enabled
echo "Step 4: Verifying rotation status..."
echo "------------------------------------------------------------"
ROTATION_STATUS=$(aws kms get-key-rotation-status \
  --key-id $KEY_ID \
  --region $REGION \
  --query 'KeyRotationEnabled' \
  --output text)
echo "New rotation status: $ROTATION_STATUS"
echo ""

# Step 5: Encrypt data before rotation
echo "Step 5: Encrypting data with current key material..."
echo "------------------------------------------------------------"
echo "Data encrypted before rotation - $(date)" > rotation-test.txt
aws kms encrypt \
  --key-id $KEY_ALIAS \
  --plaintext fileb://rotation-test.txt \
  --output text \
  --query CiphertextBlob \
  --region $REGION > encrypted-before-rotation.txt
echo "Data encrypted: encrypted-before-rotation.txt"
echo "Content: $(cat rotation-test.txt)"
echo ""

# Step 6: Explain rotation behavior
echo "Step 6: Understanding Key Rotation"
echo "------------------------------------------------------------"
echo ""
echo "HOW AUTOMATIC KEY ROTATION WORKS:"
echo ""
echo "BEFORE ROTATION (Today)"
echo "  Key ID: $KEY_ID"
echo "  Key Material: Version 1 (ACTIVE)"
echo "  All encryptions: Use Version 1"
echo "  All decryptions: Use Version 1"
echo ""
echo "AFTER ROTATION (365 days later)"
echo "  Key ID: $KEY_ID (SAME!)"
echo "  Key Material: Version 1 (retained), Version 2 (ACTIVE)"
echo "  New encryptions: Use Version 2"
echo "  Old decryptions: Automatically use Version 1"
echo ""
echo "KEY BENEFITS:"
echo "  + Key ID never changes (no app updates needed)"
echo "  + Old ciphertext always decryptable"
echo "  + Meets compliance (PCI-DSS, HIPAA, SOC2)"
echo "  + No re-encryption required"
echo "  + Zero application downtime"
echo ""
echo "LIMITATIONS:"
echo "  - Only symmetric keys with AWS-generated material"
echo "  - Fixed 365-day rotation (cannot customize)"
echo "  - Not available for asymmetric keys"
echo "  - Not available for imported key material"
echo ""

# Step 7: Demonstrate decryption still works
echo "Step 7: Verifying decryption still works..."
echo "------------------------------------------------------------"
echo "Decrypting data encrypted before rotation enabled..."
echo ""

aws kms decrypt \
  --ciphertext-blob fileb://encrypted-before-rotation.txt \
  --output text \
  --query Plaintext \
  --region $REGION | base64 --decode > decrypted-after-rotation.txt

if diff rotation-test.txt decrypted-after-rotation.txt > /dev/null; then
    echo "SUCCESS: Data decrypts correctly!"
    echo "   Even after rotation is enabled, old ciphertext remains valid."
    echo ""
    echo "Decrypted content: $(cat decrypted-after-rotation.txt)"
else
    echo "ERROR: Decryption failed"
    exit 1
fi
echo ""

# Display key info
echo "Key Information:"
echo "------------------------------------------------------------"
aws kms describe-key --key-id $KEY_ALIAS --region $REGION | jq '{
  KeyId: .KeyMetadata.KeyId,
  KeyState: .KeyMetadata.KeyState,
  KeyUsage: .KeyMetadata.KeyUsage,
  Origin: .KeyMetadata.Origin,
  CreationDate: .KeyMetadata.CreationDate
}'
echo ""

# Calculate next rotation date
CREATION_DATE=$(aws kms describe-key --key-id $KEY_ALIAS --region $REGION --query 'KeyMetadata.CreationDate' --output text)
echo "Rotation Schedule:"
echo "   Key Created: $CREATION_DATE"
echo "   First Rotation: ~365 days from creation"
echo "   Rotation Interval: Every 365 days"
echo ""

echo "========================================================"
echo "   LAB 3 COMPLETE: Key Rotation Demo"
echo "========================================================"
echo ""
echo "Summary:"
echo "   Key ID: $KEY_ID"
echo "   Key Alias: $KEY_ALIAS"
echo "   Rotation: ENABLED (every 365 days)"
echo "   Backward Compatible: YES"
echo ""
echo "Files Created:"
echo "   rotation-test.txt              (original data)"
echo "   encrypted-before-rotation.txt  (ciphertext)"
echo "   decrypted-after-rotation.txt   (recovered plaintext)"
echo ""
echo "Key Insight:"
echo "   Key rotation is essential for compliance and security hygiene."
echo "   AWS KMS handles rotation transparently - your applications"
echo "   continue working without any changes. Old data remains"
echo "   accessible because KMS retains all previous key material."
echo ""
echo "Best Practice:"
echo "   Always enable rotation for customer-managed keys used in"
echo "   production. It's free and significantly improves your"
echo "   security posture."
echo ""
echo "To cleanup: ./scripts/cleanup.sh"
echo ""

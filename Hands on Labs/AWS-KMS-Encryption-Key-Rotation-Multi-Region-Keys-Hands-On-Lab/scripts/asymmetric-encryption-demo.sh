#!/bin/bash
# AWS KMS Asymmetric Key Encryption Demo
# Part of: AWS KMS Masterclass - Hands-On Lab
#
# This script demonstrates asymmetric encryption using AWS KMS.
# Public key encrypts data, private key (in KMS) decrypts it.

set -e

# Change to lab root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"
cd "$LAB_DIR"

REGION="us-east-1"
KEY_ALIAS="alias/kms-lab-asymmetric-key"

echo "========================================================"
echo "   AWS KMS ASYMMETRIC KEY ENCRYPTION DEMO"
echo "   Lab 2: Public/Private Key Pair (RSA-2048)"
echo "========================================================"
echo ""
echo "What you'll learn:"
echo "   - Create an asymmetric KMS key (RSA-2048)"
echo "   - Download the public key for client-side encryption"
echo "   - Encrypt data outside AWS using only the public key"
echo "   - Decrypt with KMS (private key never leaves AWS)"
echo ""

# Step 1: Create asymmetric KMS key
echo "Step 1: Creating asymmetric KMS key (RSA-2048)..."
echo "------------------------------------------------------------"
KEY_RESULT=$(aws kms create-key \
  --description "KMS Lab Asymmetric Key for encryption" \
  --key-usage ENCRYPT_DECRYPT \
  --key-spec RSA_2048 \
  --origin AWS_KMS \
  --region $REGION)

KEY_ID=$(echo "$KEY_RESULT" | jq -r '.KeyMetadata.KeyId')
echo "Key created: $KEY_ID"
echo "   Algorithm: RSA-2048"
echo "   Key Usage: ENCRYPT_DECRYPT"
echo "   Public Key: Downloadable"
echo "   Private Key: Never leaves KMS"
echo ""

# Create alias
echo "Creating alias for easier reference..."
aws kms create-alias \
  --alias-name $KEY_ALIAS \
  --target-key-id $KEY_ID \
  --region $REGION
echo "Alias created: $KEY_ALIAS"
echo ""

# Step 2: Get public key
echo "Step 2: Downloading public key..."
echo "------------------------------------------------------------"
aws kms get-public-key \
  --key-id $KEY_ALIAS \
  --output text \
  --query PublicKey \
  --region $REGION | base64 --decode > public-key.der

echo "Public key saved in DER format: public-key.der"

# Convert DER to PEM for OpenSSL
openssl rsa -pubin -inform DER -in public-key.der -outform PEM -out public-key.pem 2>/dev/null
echo "Public key converted to PEM: public-key.pem"
echo ""
echo "Public Key (first 5 lines):"
head -5 public-key.pem
echo "   ..."
echo ""

# Step 3: Encrypt with public key (client-side, NO AWS API call)
echo "Step 3: Encrypting data with public key (client-side)..."
echo "------------------------------------------------------------"

# Create small data (RSA-2048 with OAEP-SHA256 limits to ~190 bytes)
echo "Secret API key: sk_live_abc123xyz789" > small-plaintext.txt

echo "Original data: $(cat small-plaintext.txt)"
echo ""
echo "Encrypting with OpenSSL (using downloaded public key)..."
echo "   Note: This encryption happens ENTIRELY outside AWS!"
echo "   No AWS API call is made. No AWS credentials needed."
echo ""

openssl pkeyutl -encrypt \
  -pubin -inkey public-key.pem \
  -pkeyopt rsa_padding_mode:oaep \
  -pkeyopt rsa_oaep_md:sha256 \
  -in small-plaintext.txt \
  -out encrypted-data-asymmetric.bin

echo "Data encrypted with public key"
echo "   Output: encrypted-data-asymmetric.bin"
echo "   Size: $(wc -c < encrypted-data-asymmetric.bin | tr -d ' ') bytes"
echo ""

# Step 4: Decrypt with KMS private key
echo "Step 4: Decrypting with KMS private key..."
echo "------------------------------------------------------------"
echo "Decrypting with KMS (private key never leaves AWS)..."
echo ""

aws kms decrypt \
  --key-id $KEY_ALIAS \
  --ciphertext-blob fileb://encrypted-data-asymmetric.bin \
  --encryption-algorithm RSAES_OAEP_SHA_256 \
  --output text \
  --query Plaintext \
  --region $REGION | base64 --decode > decrypted-data-asymmetric.txt

echo "Data decrypted successfully!"
echo "   Output: decrypted-data-asymmetric.txt"
echo ""

# Step 5: Verify
echo "Step 5: Verifying data integrity..."
echo "------------------------------------------------------------"
if diff small-plaintext.txt decrypted-data-asymmetric.txt > /dev/null; then
    echo "SUCCESS: Decrypted data matches original!"
    echo ""
    echo "Decrypted content: $(cat decrypted-data-asymmetric.txt)"
else
    echo "ERROR: Decrypted data does not match original"
    exit 1
fi
echo ""

# Display key info
echo "Key Information:"
echo "------------------------------------------------------------"
aws kms describe-key --key-id $KEY_ALIAS --region $REGION | jq '.KeyMetadata | {KeyId, KeyState, KeyUsage, KeySpec, Origin, EncryptionAlgorithms}'
echo ""

echo "========================================================"
echo "   LAB 2 COMPLETE: Asymmetric Encryption Demo"
echo "========================================================"
echo ""
echo "Summary:"
echo "   Key ID: $KEY_ID"
echo "   Key Alias: $KEY_ALIAS"
echo "   Key Type: Asymmetric (RSA-2048)"
echo "   Encryption Algorithm: RSAES_OAEP_SHA_256"
echo ""
echo "Files Created:"
echo "   public-key.der            (public key, DER format)"
echo "   public-key.pem            (public key, PEM format)"
echo "   small-plaintext.txt       (original data)"
echo "   encrypted-data-asymmetric.bin  (ciphertext)"
echo "   decrypted-data-asymmetric.txt  (recovered plaintext)"
echo ""
echo "Key Insight:"
echo "   Asymmetric encryption allows client-side encryption without"
echo "   AWS credentials. The public key can be freely distributed,"
echo "   but only KMS can decrypt using the private key."
echo ""
echo "Use Cases:"
echo "   - Client-side encryption before upload"
echo "   - Secure data collection from untrusted sources"
echo "   - Digital signatures (using SIGN_VERIFY keys)"
echo ""
echo "To cleanup: ./scripts/cleanup.sh"
echo ""

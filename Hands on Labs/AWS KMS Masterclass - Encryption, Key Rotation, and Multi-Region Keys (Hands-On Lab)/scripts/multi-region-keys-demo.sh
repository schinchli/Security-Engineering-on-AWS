#!/bin/bash
# AWS KMS Multi-Region Keys Demo
# Part of: AWS KMS Masterclass - Hands-On Lab
#
# This script demonstrates multi-region keys for disaster recovery.
# Encrypt in one region, decrypt in another without cross-region API calls.

set -e

# Change to lab root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"
cd "$LAB_DIR"

PRIMARY_REGION="us-east-1"
REPLICA_REGION="us-west-2"
KEY_ALIAS="alias/kms-lab-mrk"

echo "========================================================"
echo "   AWS KMS MULTI-REGION KEYS DEMO"
echo "   Lab 4: Cross-Region Encryption for Disaster Recovery"
echo "========================================================"
echo ""
echo "What you'll learn:"
echo "   - Create multi-region primary key"
echo "   - Replicate key to another region"
echo "   - Encrypt in one region, decrypt in another"
echo "   - Understand multi-region key benefits"
echo ""
echo "Regions:"
echo "   Primary: $PRIMARY_REGION"
echo "   Replica: $REPLICA_REGION"
echo ""

# Step 1: Create multi-region primary key
echo "Step 1: Creating multi-region PRIMARY key in $PRIMARY_REGION..."
echo "------------------------------------------------------------"
PRIMARY_KEY_RESULT=$(aws kms create-key \
  --description "KMS Lab Multi-Region Primary Key" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --multi-region \
  --region $PRIMARY_REGION)

PRIMARY_KEY_ID=$(echo "$PRIMARY_KEY_RESULT" | jq -r '.KeyMetadata.KeyId')
echo "Primary key created: $PRIMARY_KEY_ID"
echo "   Region: $PRIMARY_REGION"
echo "   Multi-Region: true"
echo "   Note: Key ID starts with 'mrk-' prefix"
echo ""

# Create alias for primary key
echo "Creating alias in primary region..."
aws kms create-alias \
  --alias-name $KEY_ALIAS \
  --target-key-id $PRIMARY_KEY_ID \
  --region $PRIMARY_REGION
echo "Alias created: $KEY_ALIAS (in $PRIMARY_REGION)"
echo ""

# Step 2: Replicate key to another region
echo "Step 2: Replicating key to $REPLICA_REGION..."
echo "------------------------------------------------------------"
REPLICA_KEY_RESULT=$(aws kms replicate-key \
  --key-id $PRIMARY_KEY_ID \
  --replica-region $REPLICA_REGION \
  --description "KMS Lab Multi-Region Replica Key" \
  --region $PRIMARY_REGION)

REPLICA_KEY_ID=$(echo "$REPLICA_KEY_RESULT" | jq -r '.ReplicaKeyMetadata.KeyId')
echo "Replica key created: $REPLICA_KEY_ID"
echo "   Region: $REPLICA_REGION"
echo ""

# Wait for replica to be ready
echo "Waiting for replica key to be ready..."
sleep 5
echo ""

# Create alias for replica key
echo "Creating alias in replica region..."
aws kms create-alias \
  --alias-name $KEY_ALIAS \
  --target-key-id $REPLICA_KEY_ID \
  --region $REPLICA_REGION
echo "Alias created: $KEY_ALIAS (in $REPLICA_REGION)"
echo ""

# Step 3: Encrypt data in primary region
echo "Step 3: Encrypting data in PRIMARY region ($PRIMARY_REGION)..."
echo "------------------------------------------------------------"
echo "Multi-region encrypted data for DR - $(date)" > mrk-test.txt

aws kms encrypt \
  --key-id $KEY_ALIAS \
  --plaintext fileb://mrk-test.txt \
  --region $PRIMARY_REGION \
  --query CiphertextBlob \
  --output text | base64 --decode > encrypted-mrk-primary.txt

echo "Data encrypted in $PRIMARY_REGION"
echo "Content: $(cat mrk-test.txt)"
echo ""

# Step 4: Decrypt data in replica region
echo "Step 4: Decrypting data in REPLICA region ($REPLICA_REGION)..."
echo "------------------------------------------------------------"
echo "Cross-region decryption - NO cross-region API call needed!"
echo ""

aws kms decrypt \
  --ciphertext-blob fileb://encrypted-mrk-primary.txt \
  --region $REPLICA_REGION \
  --query Plaintext \
  --output text | base64 --decode > decrypted-mrk-replica.txt

echo "Data decrypted in $REPLICA_REGION"
echo ""

# Step 5: Verify cross-region decryption
echo "Step 5: Verifying cross-region decryption..."
echo "------------------------------------------------------------"
if diff mrk-test.txt decrypted-mrk-replica.txt > /dev/null; then
    echo "SUCCESS: Data encrypted in $PRIMARY_REGION decrypted in $REPLICA_REGION!"
    echo ""
    echo "Decrypted content: $(cat decrypted-mrk-replica.txt)"
else
    echo "ERROR: Cross-region decryption failed"
    exit 1
fi
echo ""

# Step 6: Test reverse direction
echo "Step 6: Testing REVERSE direction..."
echo "------------------------------------------------------------"
echo "Reverse direction test data - $(date)" > mrk-reverse.txt

# Encrypt in replica region
echo "Encrypting in $REPLICA_REGION..."
aws kms encrypt \
  --key-id $KEY_ALIAS \
  --plaintext fileb://mrk-reverse.txt \
  --region $REPLICA_REGION \
  --query CiphertextBlob \
  --output text | base64 --decode > encrypted-mrk-replica.txt
echo "Data encrypted in $REPLICA_REGION"

# Decrypt in primary region
echo "Decrypting in $PRIMARY_REGION..."
aws kms decrypt \
  --ciphertext-blob fileb://encrypted-mrk-replica.txt \
  --region $PRIMARY_REGION \
  --query Plaintext \
  --output text | base64 --decode > decrypted-mrk-primary.txt
echo "Data decrypted in $PRIMARY_REGION"

if diff mrk-reverse.txt decrypted-mrk-primary.txt > /dev/null; then
    echo ""
    echo "SUCCESS: Bidirectional cross-region encryption works!"
fi
echo ""

# Display key information
echo "Key Information:"
echo "------------------------------------------------------------"
echo ""
echo "PRIMARY Key ($PRIMARY_REGION):"
aws kms describe-key --key-id $PRIMARY_KEY_ID --region $PRIMARY_REGION | jq '{
  KeyId: .KeyMetadata.KeyId,
  MultiRegion: .KeyMetadata.MultiRegion,
  KeyType: .KeyMetadata.MultiRegionConfiguration.MultiRegionKeyType,
  PrimaryRegion: .KeyMetadata.MultiRegionConfiguration.PrimaryKey.Region
}'
echo ""

echo "REPLICA Key ($REPLICA_REGION):"
aws kms describe-key --key-id $REPLICA_KEY_ID --region $REPLICA_REGION | jq '{
  KeyId: .KeyMetadata.KeyId,
  MultiRegion: .KeyMetadata.MultiRegion,
  KeyType: .KeyMetadata.MultiRegionConfiguration.MultiRegionKeyType,
  PrimaryRegion: .KeyMetadata.MultiRegionConfiguration.PrimaryKey.Region
}'
echo ""

# Explain multi-region keys
echo "Multi-Region Keys Explained:"
echo "------------------------------------------------------------"
echo ""
echo "KEY BENEFITS:"
echo "  + Same key material across regions"
echo "  + Local encryption/decryption latency"
echo "  + No cross-region API calls needed"
echo "  + Disaster recovery ready"
echo "  + Data residency compliance"
echo ""
echo "KEY DIFFERENCES:"
echo "  - Different Key IDs in each region"
echo "  - Primary can create replicas"
echo "  - Replica can be promoted to primary"
echo "  - Rotation syncs across all regions"
echo ""
echo "USE CASES:"
echo "  - Global applications"
echo "  - Disaster recovery"
echo "  - Data sovereignty requirements"
echo "  - Low-latency encryption worldwide"
echo ""

echo "========================================================"
echo "   LAB 4 COMPLETE: Multi-Region Keys Demo"
echo "========================================================"
echo ""
echo "Summary:"
echo "   Primary Key: $PRIMARY_KEY_ID ($PRIMARY_REGION)"
echo "   Replica Key: $REPLICA_KEY_ID ($REPLICA_REGION)"
echo "   Cross-region encryption: Working"
echo "   Cross-region decryption: Working"
echo "   Bidirectional: Working"
echo ""
echo "Files Created:"
echo "   mrk-test.txt               (original data)"
echo "   mrk-reverse.txt            (reverse test data)"
echo "   encrypted-mrk-primary.txt  (encrypted in us-east-1)"
echo "   encrypted-mrk-replica.txt  (encrypted in us-west-2)"
echo "   decrypted-mrk-replica.txt  (decrypted in us-west-2)"
echo "   decrypted-mrk-primary.txt  (decrypted in us-east-1)"
echo ""
echo "Key Insight:"
echo "   Multi-region keys enable disaster recovery without"
echo "   cross-region API calls. If one region fails, your"
echo "   application can seamlessly decrypt data using the"
echo "   replica key in another region."
echo ""
echo "Best Practice:"
echo "   Use multi-region keys for any data that needs to be"
echo "   accessible during regional outages. Always test your"
echo "   DR procedures by decrypting in the replica region."
echo ""
echo "To cleanup: ./scripts/cleanup.sh"
echo ""

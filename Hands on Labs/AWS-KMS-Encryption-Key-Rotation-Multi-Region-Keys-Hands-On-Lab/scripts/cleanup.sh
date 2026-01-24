#!/bin/bash
# AWS KMS Lab Cleanup Script
# Part of: AWS KMS Masterclass - Hands-On Lab
#
# This script removes all KMS keys and local files created during the lab.
# KMS keys have a minimum 7-day deletion waiting period.

# Change to lab root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"
cd "$LAB_DIR"

REGION="us-east-1"

echo "========================================================"
echo "   AWS KMS LAB CLEANUP"
echo "========================================================"
echo ""
echo "This will delete all KMS keys and local files created during the lab."
echo "KMS keys will be scheduled for deletion (7-day minimum wait)."
echo ""

# Function to safely delete a key
delete_key() {
    local ALIAS=$1
    local REGION=$2

    KEY_ID=$(aws kms describe-key --key-id $ALIAS --query 'KeyMetadata.KeyId' --output text --region $REGION 2>/dev/null)
    if [ -n "$KEY_ID" ] && [ "$KEY_ID" != "None" ]; then
        # Delete alias first
        aws kms delete-alias --alias-name $ALIAS --region $REGION 2>/dev/null || true
        # Schedule key deletion
        aws kms schedule-key-deletion --key-id $KEY_ID --pending-window-in-days 7 --region $REGION 2>/dev/null
        echo "   $ALIAS scheduled for deletion: $KEY_ID"
        return 0
    else
        echo "   $ALIAS not found in $REGION (may already be deleted)"
        return 1
    fi
}

echo "Step 1: Deleting KMS keys..."
echo "------------------------------------------------------------"

# Delete symmetric key
echo ""
echo "Lab 1: Symmetric Key"
delete_key "alias/kms-lab-symmetric-key" "us-east-1"

# Delete asymmetric key
echo ""
echo "Lab 2: Asymmetric Key"
delete_key "alias/kms-lab-asymmetric-key" "us-east-1"

# Delete rotation key
echo ""
echo "Lab 3: Rotation Key"
delete_key "alias/kms-lab-rotation-key" "us-east-1"

# Delete multi-region keys (replica first, then primary)
echo ""
echo "Lab 4: Multi-Region Keys"
echo "   Deleting replica in us-west-2 first..."
delete_key "alias/kms-lab-mrk" "us-west-2"
echo "   Deleting primary in us-east-1..."
delete_key "alias/kms-lab-mrk" "us-east-1"

echo ""
echo "Step 2: Deleting local files..."
echo "------------------------------------------------------------"

# Delete encrypted/decrypted files
rm -f encrypted-*.txt encrypted-*.bin decrypted-*.txt 2>/dev/null && echo "   Removed encrypted/decrypted files" || echo "   No encrypted/decrypted files found"

# Delete key files
rm -f public-key.* private-key.* temp-key.bin data-key.json 2>/dev/null && echo "   Removed key files" || echo "   No key files found"

# Delete test data files
rm -f small-plaintext.txt rotation-test.txt mrk-test.txt mrk-reverse.txt reverse-test.txt 2>/dev/null && echo "   Removed test data files" || echo "   No test data files found"

# Delete config files
rm -f lab-config.txt 2>/dev/null && echo "   Removed config files" || echo "   No config files found"

echo ""
echo "========================================================"
echo "   CLEANUP COMPLETE"
echo "========================================================"
echo ""
echo "Summary:"
echo "   - KMS keys scheduled for deletion (7-day wait period)"
echo "   - Local encrypted/decrypted files removed"
echo "   - Key material files removed"
echo "   - Test data files removed"
echo ""
echo "IMPORTANT:"
echo "   KMS keys will be fully deleted in 7 days."
echo "   During this period, you can cancel deletion with:"
echo "   aws kms cancel-key-deletion --key-id <KEY_ID>"
echo ""
echo "Cost Note:"
echo "   You will not be charged for keys pending deletion."
echo "   Charges stop immediately when deletion is scheduled."
echo ""

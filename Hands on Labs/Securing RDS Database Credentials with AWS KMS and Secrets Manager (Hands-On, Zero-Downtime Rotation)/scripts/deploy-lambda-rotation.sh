#!/bin/bash
set -e

if [ ! -f lab-config.txt ]; then
  echo "❌ lab-config.txt not found. Run ./deploy.sh first."
  exit 1
fi

source lab-config.txt

echo "🚀 Deploying Lambda rotation function..."

# Create IAM role for Lambda
echo "📦 Creating IAM role..."
ROLE_NAME="rds-rotation-lambda-role"

TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
)

aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document "$TRUST_POLICY" \
  --region $REGION 2>/dev/null || echo "Role already exists"

# Attach policies
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
  --region $REGION 2>/dev/null || true

# Create inline policy for Secrets Manager and RDS
INLINE_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecretVersionStage"
      ],
      "Resource": "$SECRET_ARN"
    },
    {
      "Effect": "Allow",
      "Action": [
        "rds:ModifyDBInstance",
        "rds:DescribeDBInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ],
      "Resource": "arn:aws:kms:$REGION:*:key/$KMS_KEY_ID"
    }
  ]
}
EOF
)

aws iam put-role-policy \
  --role-name $ROLE_NAME \
  --policy-name rds-rotation-policy \
  --policy-document "$INLINE_POLICY" \
  --region $REGION

ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
echo "✅ IAM role created: $ROLE_ARN"

# Wait for role to propagate
echo "⏳ Waiting for IAM role to propagate..."
sleep 10

# Package Lambda function
echo "📦 Packaging Lambda function..."
cd src
zip -q rotation_lambda.zip rotation_lambda.py
cd ..

# Create Lambda function
echo "📦 Creating Lambda function..."
LAMBDA_ARN=$(aws lambda create-function \
  --function-name rds-secret-rotation \
  --runtime python3.11 \
  --role $ROLE_ARN \
  --handler rotation_lambda.lambda_handler \
  --zip-file fileb://src/rotation_lambda.zip \
  --timeout 300 \
  --region $REGION \
  --query 'FunctionArn' \
  --output text 2>/dev/null || aws lambda get-function --function-name rds-secret-rotation --region $REGION --query 'Configuration.FunctionArn' --output text)

echo "✅ Lambda function created: $LAMBDA_ARN"

# Grant Secrets Manager permission to invoke Lambda
echo "📦 Granting Secrets Manager permissions..."
aws lambda add-permission \
  --function-name rds-secret-rotation \
  --statement-id SecretsManagerAccess \
  --action lambda:InvokeFunction \
  --principal secretsmanager.amazonaws.com \
  --region $REGION 2>/dev/null || echo "Permission already exists"

# Enable automatic rotation
echo "🔄 Enabling automatic rotation..."
aws secretsmanager rotate-secret \
  --secret-id $SECRET_NAME \
  --rotation-lambda-arn $LAMBDA_ARN \
  --rotation-rules "{\"AutomaticallyAfterDays\": 30}" \
  --region $REGION

echo ""
echo "✅ Lambda rotation function deployed!"
echo ""
echo "📝 Lambda ARN: $LAMBDA_ARN"
echo "🔄 Automatic rotation: Every 30 days"
echo ""
echo "🧪 Test rotation manually:"
echo "   aws secretsmanager rotate-secret --secret-id $SECRET_NAME --region $REGION"

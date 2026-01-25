import json
import boto3
import os
import random
import string

secretsmanager = boto3.client('secretsmanager')
rds = boto3.client('rds')

def generate_password(length=25):
    """Generate a secure random password"""
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for _ in range(length))

def lambda_handler(event, context):
    """
    Lambda function to rotate RDS credentials in Secrets Manager
    """
    secret_arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    
    print(f"Rotation step: {step} for secret: {secret_arn}")
    
    if step == "createSecret":
        create_secret(secret_arn, token)
    elif step == "setSecret":
        set_secret(secret_arn, token)
    elif step == "testSecret":
        test_secret(secret_arn, token)
    elif step == "finishSecret":
        finish_secret(secret_arn, token)
    else:
        raise ValueError(f"Invalid step: {step}")
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Successfully completed {step}')
    }

def create_secret(secret_arn, token):
    """Create new secret version with new password"""
    # Get current secret
    current = secretsmanager.get_secret_value(SecretId=secret_arn, VersionStage="AWSCURRENT")
    secret_dict = json.loads(current['SecretString'])
    
    # Generate new password
    new_password = generate_password()
    secret_dict['password'] = new_password
    
    # Store new version
    secretsmanager.put_secret_value(
        SecretId=secret_arn,
        ClientRequestToken=token,
        SecretString=json.dumps(secret_dict),
        VersionStages=['AWSPENDING']
    )
    print(f"Created new secret version with token: {token}")

def set_secret(secret_arn, token):
    """Update RDS master password"""
    # Get pending secret
    pending = secretsmanager.get_secret_value(
        SecretId=secret_arn,
        VersionId=token,
        VersionStage="AWSPENDING"
    )
    secret_dict = json.loads(pending['SecretString'])
    
    # Extract DB instance identifier from host
    db_host = secret_dict['host']
    db_instance_id = db_host.split('.')[0]
    
    # Update RDS password
    rds.modify_db_instance(
        DBInstanceIdentifier=db_instance_id,
        MasterUserPassword=secret_dict['password'],
        ApplyImmediately=True
    )
    print(f"Updated RDS password for: {db_instance_id}")
    
    # Wait for modification
    waiter = rds.get_waiter('db_instance_available')
    waiter.wait(DBInstanceIdentifier=db_instance_id)
    print(f"RDS instance available: {db_instance_id}")

def test_secret(secret_arn, token):
    """Test new credentials (simplified - just verify secret exists)"""
    # Get pending secret
    pending = secretsmanager.get_secret_value(
        SecretId=secret_arn,
        VersionId=token,
        VersionStage="AWSPENDING"
    )
    secret_dict = json.loads(pending['SecretString'])
    
    # In production, you would test actual DB connection here
    # For this lab, we just verify the secret is valid
    required_keys = ['username', 'password', 'host', 'port', 'engine']
    for key in required_keys:
        if key not in secret_dict:
            raise ValueError(f"Missing required key: {key}")
    
    print(f"Secret validation passed for token: {token}")

def finish_secret(secret_arn, token):
    """Finalize rotation by updating version stages"""
    # Get current version
    metadata = secretsmanager.describe_secret(SecretId=secret_arn)
    current_version = None
    for version, stages in metadata['VersionIdsToStages'].items():
        if "AWSCURRENT" in stages:
            current_version = version
            break
    
    # Move AWSCURRENT to new version
    secretsmanager.update_secret_version_stage(
        SecretId=secret_arn,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version
    )
    print(f"Rotation complete. New version {token} is now AWSCURRENT")

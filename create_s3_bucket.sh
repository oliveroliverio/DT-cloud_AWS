#!/bin/bash
# create_s3_bucket.sh - Script to create an AWS S3 bucket with at least 80GB capacity

# ====== Configuration Variables ======
REGION="us-west-1"                     # Change if needed
BUCKET_NAME="dt-cloud-storage-$(date +%Y%m%d%H%M%S)"  # Unique bucket name with timestamp
LIFECYCLE_POLICY_NAME="dt-cloud-lifecycle-policy"

echo "====== Creating S3 Bucket ======"
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $REGION"

# ====== Create the S3 Bucket ======
echo "Creating S3 bucket..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create S3 bucket."
    exit 1
fi

echo "S3 bucket created successfully: $BUCKET_NAME"

# ====== Enable Versioning ======
echo "Enabling versioning on the bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

if [ $? -ne 0 ]; then
    echo "Warning: Failed to enable versioning on the bucket."
fi

# ====== Set Default Encryption ======
echo "Setting default encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'

if [ $? -ne 0 ]; then
    echo "Warning: Failed to set default encryption."
fi

# ====== Configure Lifecycle Policy ======
# This policy will transition objects to Standard-IA after 30 days
# and to Glacier after 90 days to optimize storage costs
echo "Configuring lifecycle policy..."
aws s3api put-bucket-lifecycle-configuration \
    --bucket "$BUCKET_NAME" \
    --lifecycle-configuration '{
        "Rules": [
            {
                "ID": "'"$LIFECYCLE_POLICY_NAME"'",
                "Status": "Enabled",
                "Prefix": "",
                "Transitions": [
                    {
                        "Days": 30,
                        "StorageClass": "STANDARD_IA"
                    },
                    {
                        "Days": 90,
                        "StorageClass": "GLACIER"
                    }
                ]
            }
        ]
    }'

if [ $? -ne 0 ]; then
    echo "Warning: Failed to set lifecycle policy."
fi

# ====== Set CORS Configuration ======
echo "Setting CORS configuration..."
aws s3api put-bucket-cors \
    --bucket "$BUCKET_NAME" \
    --cors-configuration '{
        "CORSRules": [
            {
                "AllowedHeaders": ["*"],
                "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
                "AllowedOrigins": ["*"],
                "ExposeHeaders": ["ETag"]
            }
        ]
    }'

if [ $? -ne 0 ]; then
    echo "Warning: Failed to set CORS configuration."
fi

# ====== Output Bucket Information ======
echo ""
echo "====== S3 Bucket Information ======"
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $REGION"
echo "S3 URI: s3://$BUCKET_NAME"
echo "S3 Console URL: https://s3.console.aws.amazon.com/s3/buckets/$BUCKET_NAME"
echo ""
echo "Note: S3 buckets have virtually unlimited storage capacity (up to exabytes)."
echo "      You're only charged for what you use, and the bucket can easily store 80GB or more."
echo ""
echo "To upload files to this bucket, use:"
echo "aws s3 cp /path/to/local/file s3://$BUCKET_NAME/path/in/bucket/"
echo ""
echo "To download files from this bucket, use:"
echo "aws s3 cp s3://$BUCKET_NAME/path/in/bucket/file /local/destination/path/"
echo ""
echo "To list all files in this bucket, use:"
echo "aws s3 ls s3://$BUCKET_NAME/ --recursive"

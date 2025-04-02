#!/bin/bash
# download_hunyuan_models.sh - Script to set up S3 bucket structure for HunyuanVideo-I2V models

# ====== Configuration Variables ======
BUCKET_NAME="dt-cloud-storage-20250401215819"  # The S3 bucket we created earlier
REGION="us-west-1"                            # Change if needed
S3_PREFIX="HunyuanVideo-I2V"                  # Prefix in S3 bucket

# ====== Create S3 Directory Structure ======
echo "Creating S3 bucket directory structure for HunyuanVideo-I2V models..."

# Create empty placeholder files to establish the directory structure
echo "Creating placeholder for README.md..."
echo "# HunyuanVideo-I2V Models Placeholder" > readme_placeholder.md
aws s3 cp readme_placeholder.md "s3://${BUCKET_NAME}/${S3_PREFIX}/ckpts/README.md"
rm readme_placeholder.md

echo "Creating directory structure in S3 bucket..."
# Create empty placeholder files to establish the directory structure
touch placeholder.txt
aws s3 cp placeholder.txt "s3://${BUCKET_NAME}/${S3_PREFIX}/ckpts/hunyuan-video-i2v-720p/transformers/placeholder.txt"
aws s3 cp placeholder.txt "s3://${BUCKET_NAME}/${S3_PREFIX}/ckpts/hunyuan-video-i2v-720p/vae/placeholder.txt"
aws s3 cp placeholder.txt "s3://${BUCKET_NAME}/${S3_PREFIX}/ckpts/hunyuan-video-i2v-720p/lora/placeholder.txt"
aws s3 cp placeholder.txt "s3://${BUCKET_NAME}/${S3_PREFIX}/ckpts/text_encoder_i2v/placeholder.txt"
aws s3 cp placeholder.txt "s3://${BUCKET_NAME}/${S3_PREFIX}/ckpts/text_encoder_2/placeholder.txt"
rm placeholder.txt

echo "====== S3 Directory Structure Created ======"
echo "S3 bucket directory structure has been created in: ${BUCKET_NAME}"
echo "S3 Path: s3://${BUCKET_NAME}/${S3_PREFIX}"
echo "S3 Console URL: https://s3.console.aws.amazon.com/s3/buckets/${BUCKET_NAME}?prefix=${S3_PREFIX}/"

# ====== Create Instructions File ======
cat > hunyuan_model_download_instructions.md << 'EOF'
# Instructions for Downloading HunyuanVideo-I2V Models

These instructions will guide you through downloading the HunyuanVideo-I2V models and uploading them to your S3 bucket.

## Prerequisites
- Python 3.x installed
- AWS CLI configured with appropriate permissions

## Step 1: Install Huggingface CLI
```shell
python -m pip install "huggingface_hub[cli]"
```

## Step 2: Create Local Directory Structure
```shell
mkdir -p HunyuanVideo-I2V/ckpts/hunyuan-video-i2v-720p/transformers
mkdir -p HunyuanVideo-I2V/ckpts/hunyuan-video-i2v-720p/vae
mkdir -p HunyuanVideo-I2V/ckpts/hunyuan-video-i2v-720p/lora
mkdir -p HunyuanVideo-I2V/ckpts/text_encoder_i2v
mkdir -p HunyuanVideo-I2V/ckpts/text_encoder_2
```

## Step 3: Download HunyuanVideo-I2V Model
```shell
cd HunyuanVideo-I2V
huggingface-cli download tencent/HunyuanVideo-I2V --local-dir ./ckpts
```

## Step 4: Download Text Encoder Models
```shell
cd HunyuanVideo-I2V/ckpts
huggingface-cli download xtuner/llava-llama-3-8b-v1_1-transformers --local-dir ./text_encoder_i2v
huggingface-cli download openai/clip-vit-large-patch14 --local-dir ./text_encoder_2
```

## Step 5: Upload to S3 Bucket
```shell
aws s3 cp HunyuanVideo-I2V s3://dt-cloud-storage-20250401215819/HunyuanVideo-I2V --recursive
```

## Troubleshooting
If you encounter slow download speeds, you can try using a mirror:
```shell
HF_ENDPOINT=https://hf-mirror.com huggingface-cli download tencent/HunyuanVideo-I2V --local-dir ./ckpts
```

If the download is interrupted, you can resume by rerunning the download command.
EOF

echo "Created instructions file: hunyuan_model_download_instructions.md"
echo "Please follow these instructions when Python is available to download and upload the models."

# Upload instructions to S3
aws s3 cp hunyuan_model_download_instructions.md "s3://${BUCKET_NAME}/${S3_PREFIX}/download_instructions.md"

echo "Instructions have been uploaded to S3: s3://${BUCKET_NAME}/${S3_PREFIX}/download_instructions.md"

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

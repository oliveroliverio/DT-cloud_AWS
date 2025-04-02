#!/usr/bin/env python3
"""
Script to download HunyuanVideo-I2V models and upload them to S3 bucket.
This script automates the process described in hunyuan_model_download_instructions.md.
"""

import os
import sys
import subprocess
import argparse
import time
from pathlib import Path

# Configuration
DEFAULT_BUCKET_NAME = "dt-cloud-storage-20250401215819"
DEFAULT_REGION = "us-west-1"
DEFAULT_S3_PREFIX = "HunyuanVideo-I2V"
BASE_DIR = Path("HunyuanVideo-I2V")

def run_command(cmd, cwd=None):
    """Run a shell command and print output in real-time."""
    print(f"Running: {' '.join(cmd)}")
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        cwd=cwd
    )
    
    # Print output in real-time
    for line in process.stdout:
        print(line, end='')
    
    process.wait()
    return process.returncode

def install_huggingface_cli():
    """Install Hugging Face CLI."""
    print("\n=== Installing Hugging Face CLI ===")
    return run_command([sys.executable, "-m", "pip", "install", "huggingface_hub[cli]"])

def create_directory_structure():
    """Create the local directory structure for the models."""
    print("\n=== Creating Directory Structure ===")
    directories = [
        BASE_DIR / "ckpts" / "hunyuan-video-i2v-720p" / "transformers",
        BASE_DIR / "ckpts" / "hunyuan-video-i2v-720p" / "vae",
        BASE_DIR / "ckpts" / "hunyuan-video-i2v-720p" / "lora",
        BASE_DIR / "ckpts" / "text_encoder_i2v",
        BASE_DIR / "ckpts" / "text_encoder_2"
    ]
    
    for directory in directories:
        print(f"Creating directory: {directory}")
        directory.mkdir(parents=True, exist_ok=True)

def download_hunyuan_model(use_mirror=False):
    """Download the HunyuanVideo-I2V model."""
    print("\n=== Downloading HunyuanVideo-I2V Model ===")
    print("This may take 10 minutes to 1 hour depending on network conditions.")
    
    cmd = ["huggingface-cli", "download", "tencent/HunyuanVideo-I2V", "--local-dir", "./ckpts"]
    
    env = os.environ.copy()
    if use_mirror:
        print("Using HF mirror for faster downloads")
        env["HF_ENDPOINT"] = "https://hf-mirror.com"
    
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        cwd=BASE_DIR,
        env=env
    )
    
    # Print output in real-time
    for line in process.stdout:
        print(line, end='')
    
    process.wait()
    return process.returncode

def download_text_encoders(use_mirror=False):
    """Download the text encoder models."""
    print("\n=== Downloading Text Encoder Models ===")
    
    env = os.environ.copy()
    if use_mirror:
        env["HF_ENDPOINT"] = "https://hf-mirror.com"
    
    # Download MLLM model
    print("Downloading MLLM model (text_encoder_i2v)...")
    cmd1 = ["huggingface-cli", "download", "xtuner/llava-llama-3-8b-v1_1-transformers", "--local-dir", "./text_encoder_i2v"]
    process1 = subprocess.Popen(
        cmd1,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        cwd=BASE_DIR / "ckpts",
        env=env
    )
    
    for line in process1.stdout:
        print(line, end='')
    
    process1.wait()
    
    # Download CLIP model
    print("Downloading CLIP model (text_encoder_2)...")
    cmd2 = ["huggingface-cli", "download", "openai/clip-vit-large-patch14", "--local-dir", "./text_encoder_2"]
    process2 = subprocess.Popen(
        cmd2,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        cwd=BASE_DIR / "ckpts",
        env=env
    )
    
    for line in process2.stdout:
        print(line, end='')
    
    process2.wait()
    
    return process1.returncode, process2.returncode

def upload_to_s3(bucket_name, s3_prefix):
    """Upload the downloaded models to S3."""
    print(f"\n=== Uploading Models to S3 Bucket: {bucket_name} ===")
    cmd = ["aws", "s3", "cp", str(BASE_DIR), f"s3://{bucket_name}/{s3_prefix}", "--recursive"]
    return run_command(cmd)

def main():
    parser = argparse.ArgumentParser(description="Download HunyuanVideo-I2V models and upload to S3")
    parser.add_argument("--bucket", default=DEFAULT_BUCKET_NAME, help="S3 bucket name")
    parser.add_argument("--region", default=DEFAULT_REGION, help="AWS region")
    parser.add_argument("--prefix", default=DEFAULT_S3_PREFIX, help="S3 prefix/folder")
    parser.add_argument("--use-mirror", action="store_true", help="Use HF mirror for faster downloads")
    parser.add_argument("--skip-upload", action="store_true", help="Skip uploading to S3")
    
    args = parser.parse_args()
    
    start_time = time.time()
    
    # Step 1: Install Hugging Face CLI
    if install_huggingface_cli() != 0:
        print("Failed to install Hugging Face CLI. Exiting.")
        return 1
    
    # Step 2: Create directory structure
    create_directory_structure()
    
    # Step 3: Download HunyuanVideo-I2V model
    if download_hunyuan_model(args.use_mirror) != 0:
        print("Warning: Issues encountered while downloading HunyuanVideo-I2V model.")
        print("Continuing with next steps...")
    
    # Step 4: Download text encoder models
    mllm_result, clip_result = download_text_encoders(args.use_mirror)
    if mllm_result != 0 or clip_result != 0:
        print("Warning: Issues encountered while downloading text encoder models.")
        print("Continuing with next steps...")
    
    # Step 5: Upload to S3 bucket (if not skipped)
    if not args.skip_upload:
        if upload_to_s3(args.bucket, args.prefix) != 0:
            print("Failed to upload models to S3. Please check your AWS configuration.")
            return 1
    else:
        print("\n=== Skipping S3 Upload ===")
        print(f"Models are available locally at: {BASE_DIR}")
    
    end_time = time.time()
    duration = end_time - start_time
    
    print("\n=== Process Complete ===")
    print(f"Total time: {duration/60:.2f} minutes")
    print(f"Models downloaded to: {BASE_DIR}")
    if not args.skip_upload:
        print(f"Models uploaded to: s3://{args.bucket}/{args.prefix}")
        print(f"S3 Console URL: https://s3.console.aws.amazon.com/s3/buckets/{args.bucket}?prefix={args.prefix}/")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

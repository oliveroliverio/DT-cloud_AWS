#!/bin/bash
# run_model_download.sh - Shell script wrapper for download_models.py

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not found."
    echo "Please install Python 3 and try again."
    exit 1
fi

# Make the Python script executable
chmod +x download_models.py

# Run the Python script with any provided arguments
echo "Starting HunyuanVideo-I2V model download process..."
python3 ./download_models.py "$@"

# Check if the script ran successfully
if [ $? -eq 0 ]; then
    echo "Model download process completed successfully."
else
    echo "Model download process encountered errors. Please check the output above."
fi

#!/bin/bash
# launch_ubuntu.sh

# ====== Configuration Variables ======
REGION="us-west-1"                     # Change if needed
AMI_ID="ami-0347e16ae916f31a9"          # Ubuntu Server 20.04 LTS for us-west-1 (March 2025)
INSTANCE_TYPE="g4dn.xlarge"
KEY_NAME="my-ubuntu-key-$REGION"               # Name for your key pair
KEY_FILE="${KEY_NAME}.pem"
SECURITY_GROUP_NAME="ubuntu-sg-$REGION"  # Name for your security group

# ====== Create a Key Pair (if it doesn't exist) ======
if [ ! -f "$KEY_FILE" ]; then
    echo "Key file $KEY_FILE not found. Creating a new key pair..."
    aws ec2 create-key-pair \
      --key-name "$KEY_NAME" \
      --query 'KeyMaterial' \
      --output text \
      --region "$REGION" > "$KEY_FILE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create key pair."
        exit 1
    fi
    chmod 400 "$KEY_FILE"
    echo "Key pair created and saved to $KEY_FILE."
else
    echo "Key file $KEY_FILE exists. Skipping key pair creation."
fi

# ====== Create a Security Group (if it doesn't exist) ======
SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" \
    --query 'SecurityGroups[0].GroupId' \
    --output text \
    --region "$REGION")

if [ "$SG_ID" == "None" ] || [ -z "$SG_ID" ]; then
    echo "Security group $SECURITY_GROUP_NAME not found. Creating a new security group..."
    SG_ID=$(aws ec2 create-security-group \
        --group-name "$SECURITY_GROUP_NAME" \
        --description "Security group for Ubuntu instance" \
        --query 'GroupId' \
        --output text \
        --region "$REGION")
    
    if [ $? -ne 0 ] || [ -z "$SG_ID" ]; then
        echo "Error: Failed to create security group."
        exit 1
    fi
    
    # Add SSH access rule
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 \
        --region "$REGION"
    
    echo "Security group created with ID: $SG_ID and SSH access enabled."
else
    echo "Security group $SECURITY_GROUP_NAME exists with ID: $SG_ID."
fi

# ====== Launch the Instance ======
echo "Launching Ubuntu instance on a $INSTANCE_TYPE..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region "$REGION")

if [ -z "$INSTANCE_ID" ]; then
    echo "Error: Instance launch failed."
    exit 1
fi

echo "Instance launched with ID: $INSTANCE_ID"

# ====== Wait for the Instance to Run ======
echo "Waiting for the instance to enter the 'running' state..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"
echo "Instance is now running."

# ====== Retrieve the Public IP ======
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region "$REGION")

if [ -z "$PUBLIC_IP" ]; then
    echo "Error: Could not retrieve the public IP address."
    exit 1
fi

echo "The instance public IP is: $PUBLIC_IP"

# ====== SSH Connection Instructions ======
echo ""
echo "You can now SSH into your instance using the following command:"
echo "ssh -i \"$KEY_FILE\" ubuntu@$PUBLIC_IP"
echo ""
echo "For VS Code Remote SSH, add the following to your ~/.ssh/config file:"
echo ""
echo "Host ec2-ubuntu"
echo "    HostName $PUBLIC_IP"
echo "    User ubuntu"
echo "    IdentityFile $(pwd)/$KEY_FILE"
echo "    ForwardAgent yes"
echo ""
echo "Note: If the SSH connection fails, ensure that your local firewall permits outbound SSH traffic."

# End of script

#!/bin/bash
# EC2 User Data Script for GitHub Runner

# Update system
yum update -y
yum install -y docker git

# Install Java 21
amazon-linux-extras install java-openjdk21 -y

# Install Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
yum install -y nodejs

# Start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Create runner user
useradd -m runner
usermod -a -G docker runner

# Download and setup GitHub runner
cd /home/runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz
chown -R runner:runner /home/runner

# Configure runner (requires token from secrets)
sudo -u runner ./config.sh --url https://github.com/YOUR_ORG/YOUR_REPO --token $RUNNER_TOKEN --labels temp-runner,linux --unattended

# Start runner
sudo -u runner ./run.sh &
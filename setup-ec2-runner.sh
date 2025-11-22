#!/bin/bash
# Setup GitHub Runner on existing EC2 instance

# Update system
sudo yum update -y
sudo yum install -y git curl wget

# Install Java 21
sudo yum install -y java-21-amazon-corretto-devel
export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto

# Install Maven
cd /opt
sudo wget https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
sudo tar xzf apache-maven-3.9.5-bin.tar.gz
sudo ln -s apache-maven-3.9.5 maven
export PATH=/opt/maven/bin:$PATH

# Install Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# Create runner directory
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download GitHub runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure runner (replace with your repo details)
echo "Run this command to configure the runner:"
echo "./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_RUNNER_TOKEN --labels self-hosted,linux,ec2"
echo ""
echo "Then start the runner with:"
echo "./run.sh"
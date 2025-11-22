#!/bin/bash
# Setup GitHub Runner on the created EC2 instance

INSTANCE_IP="18.141.221.204"
KEY_FILE="aws/concert-key.pem"

echo "Setting up GitHub runner on EC2: $INSTANCE_IP"

# Create setup commands
cat > runner-setup-commands.sh << 'EOF'
#!/bin/bash
# Update system
sudo yum update -y
sudo yum install -y git curl wget docker

# Install Java 21 for ARM64
sudo yum install -y java-21-amazon-corretto-devel
echo 'export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto' >> ~/.bashrc

# Install Maven
cd /opt
sudo wget https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
sudo tar xzf apache-maven-3.9.5-bin.tar.gz
sudo ln -s apache-maven-3.9.5 maven
echo 'export PATH=/opt/maven/bin:$PATH' >> ~/.bashrc

# Install Node.js 20 for ARM64
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Create runner directory
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download GitHub runner for ARM64
curl -o actions-runner-linux-arm64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-arm64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-arm64-2.311.0.tar.gz

echo "✅ Setup complete!"
echo "To configure runner:"
echo "./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_RUNNER_TOKEN --labels self-hosted,linux,ec2,ARM64"
echo "To start runner:"
echo "./run.sh"
EOF

# Copy and execute setup on EC2
echo "Copying setup script to EC2..."
scp -i $KEY_FILE -o StrictHostKeyChecking=no runner-setup-commands.sh ec2-user@$INSTANCE_IP:~/

echo "Executing setup on EC2..."
ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP 'chmod +x runner-setup-commands.sh && ./runner-setup-commands.sh'

echo ""
echo "✅ GitHub runner setup completed on EC2!"
echo "Next steps:"
echo "1. SSH to EC2: ssh -i $KEY_FILE ec2-user@$INSTANCE_IP"
echo "2. Go to GitHub repo → Settings → Actions → Runners → New self-hosted runner"
echo "3. Copy the token and run:"
echo "   cd ~/actions-runner"
echo "   ./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN --labels self-hosted,linux,ec2,ARM64"
echo "   ./run.sh"
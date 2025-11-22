#!/bin/bash
# Setup GitHub Runner using AWS SSM (Session Manager)

INSTANCE_ID="i-00b60427a419804ef"

echo "Setting up GitHub runner via SSM on instance: $INSTANCE_ID"

# Create setup script
cat > runner-setup.sh << 'EOF'
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

# Setup GitHub Runner
mkdir -p /home/ec2-user/actions-runner
cd /home/ec2-user/actions-runner
curl -o actions-runner-linux-arm64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-arm64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-arm64-2.311.0.tar.gz
chown -R ec2-user:ec2-user /home/ec2-user/actions-runner

echo "✅ Setup complete!"
EOF

# Execute via SSM
echo "Executing setup via SSM..."
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[\"$(cat runner-setup.sh | base64 -w 0 | base64 -d)\"]" \
  --query 'Command.CommandId' --output text

echo ""
echo "✅ Setup command sent via SSM!"
echo "Check command status with:"
echo "aws ssm list-command-invocations --instance-id $INSTANCE_ID"
echo ""
echo "To connect and configure runner:"
echo "aws ssm start-session --target $INSTANCE_ID"
echo "Then run:"
echo "cd ~/actions-runner"
echo "./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN --labels self-hosted,linux,ec2,ARM64"
echo "./run.sh"
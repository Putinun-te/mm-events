#!/bin/bash
# Setup SSM Agent on EC2 - Run this in EC2 Instance Connect

echo "📦 Installing SSM Agent..."
sudo yum install -y amazon-ssm-agent

echo "🚀 Starting SSM Agent..."
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

echo "✅ Checking SSM Agent status..."
sudo systemctl status amazon-ssm-agent --no-pager

echo ""
echo "✅ SSM Agent installed and running!"
echo ""
echo "Now you can connect using AWS CLI:"
echo "  aws ssm start-session --target i-0ffd487469a6fa1aa --region ap-southeast-1"
echo ""
echo "Or use AWS Console:"
echo "  https://ap-southeast-1.console.aws.amazon.com/systems-manager/session-manager/sessions"

#!/bin/bash
cd main_frontend/concert1

# Build SSR
npm run build

# Create deployment package
cd .output
tar -czf frontend-ssr.tar.gz server public

# Upload to S3
aws s3 cp frontend-ssr.tar.gz s3://concert-event-pictures-singapore-123456789012/

# Deploy to EC2
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=concert-asg-v2" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text)

aws ssm send-command --instance-ids $INSTANCE_ID --document-name "AWS-RunShellScript" --parameters 'commands=[
  "curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -",
  "yum install -y nodejs",
  "/usr/local/bin/aws s3 cp s3://concert-event-pictures-singapore-123456789012/frontend-ssr.tar.gz /tmp/",
  "mkdir -p /opt/frontend",
  "tar -xzf /tmp/frontend-ssr.tar.gz -C /opt/frontend",
  "cd /opt/frontend && npm install --production",
  "pkill -f \"node.*index.mjs\" || true",
  "nohup node /opt/frontend/server/index.mjs > /var/log/frontend.log 2>&1 &",
  "sleep 5",
  "curl http://localhost:3000 || echo Frontend starting"
]' --query 'Command.CommandId' --output text

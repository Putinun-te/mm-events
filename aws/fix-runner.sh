#!/bin/bash
# Fix GitHub Actions Runner session conflict

INSTANCE_ID="i-07d0a0f2c11c81e5d"
REGION="ap-southeast-1"
RUNNER_NAME="ip-192-168-25-159"

echo "🔧 Fixing runner session conflict..."

# Create script to run on EC2
cat > /tmp/fix-runner-commands.sh << 'EOF'
#!/bin/bash
cd /home/ec2-user/actions-runner

# Stop service
sudo systemctl stop actions.runner.MorningMores-develop.ip-192-168-25-159.service

# Get removal token from GitHub
GITHUB_TOKEN="${GITHUB_PAT}"
REMOVAL_TOKEN=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/MorningMores/develop/actions/runners/remove-token | jq -r .token)

# Remove runner
sudo -u ec2-user ./config.sh remove --token "${REMOVAL_TOKEN}"

# Get registration token
REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/MorningMores/develop/actions/runners/registration-token | jq -r .token)

# Re-register runner
sudo -u ec2-user ./config.sh \
  --url https://github.com/MorningMores/develop \
  --token "${REG_TOKEN}" \
  --name ip-192-168-25-159 \
  --labels self-hosted,Linux,ARM64 \
  --unattended \
  --replace

# Install and start service
sudo ./svc.sh install ec2-user
sudo ./svc.sh start

echo "✅ Runner fixed and restarted"
EOF

# Send to EC2 and execute
aws ssm send-command \
  --instance-ids "${INSTANCE_ID}" \
  --region "${REGION}" \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=$(cat /tmp/fix-runner-commands.sh)" \
  --output text

rm /tmp/fix-runner-commands.sh

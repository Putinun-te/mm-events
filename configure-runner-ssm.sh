#!/bin/bash
# Configure GitHub Runner via SSM

INSTANCE_ID="i-00b60427a419804ef"
REPO_URL="https://github.com/putinan/develop"  # Update with your actual repo
RUNNER_TOKEN="YOUR_GITHUB_TOKEN_HERE"  # You need to get this from GitHub

echo "Configuring GitHub runner via SSM..."

# Configure and start runner
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[
    'cd /home/ec2-user/actions-runner',
    'sudo -u ec2-user ./config.sh --url $REPO_URL --token $RUNNER_TOKEN --labels self-hosted,linux,ec2,ARM64 --unattended',
    'sudo -u ec2-user nohup ./run.sh > runner.log 2>&1 &'
  ]" \
  --query 'Command.CommandId' --output text

echo ""
echo "✅ Runner configuration command sent!"
echo ""
echo "To get GitHub token:"
echo "1. Go to: https://github.com/putinan/develop/settings/actions/runners/new"
echo "2. Copy the token from the config command"
echo "3. Update RUNNER_TOKEN in this script"
echo "4. Run the script again"
echo ""
echo "To check runner status:"
echo "aws ssm start-session --target $INSTANCE_ID"
echo "tail -f ~/actions-runner/runner.log"
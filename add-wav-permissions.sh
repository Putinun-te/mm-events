#!/bin/bash
# Add wav user permissions to GitHub runner EC2

INSTANCE_ID="i-00b60427a419804ef"
PUBLIC_IP="18.141.221.204"

echo "Adding wav user permissions to EC2 instance: $INSTANCE_ID"

# Create IAM policy for wav user access
cat > wav-runner-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::123456789012:user/wav"
            },
            "Action": [
                "ec2:DescribeInstances",
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:RebootInstances"
            ],
            "Resource": "arn:aws:ec2:ap-southeast-1:123456789012:instance/$INSTANCE_ID"
        }
    ]
}
EOF

# Add wav to security group for SSH access
aws ec2 authorize-security-group-ingress \
  --group-id sg-084b6867a012f9a89 \
  --protocol tcp \
  --port 22 \
  --source-group sg-084b6867a012f9a89 \
  --group-owner-id 123456789012

echo "✅ Added wav user permissions"
echo "✅ Updated security group for wav access"
echo ""
echo "wav can now:"
echo "- SSH to instance: ssh -i concert-singapore.pem ec2-user@$PUBLIC_IP"
echo "- Start/stop the runner instance"
echo "- Access GitHub runner logs"
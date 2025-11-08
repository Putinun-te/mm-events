#!/bin/bash
ARM_AMI=$(aws ec2 describe-images --region ap-southeast-1 --owners amazon --filters "Name=name,Values=al2023-ami-2023*-arm64" "Name=state,Values=available" --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text)

cat > /tmp/userdata.sh <<'SCRIPT'
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:cors-fix
docker run -d -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306/concert_db \
  -e SPRING_DATASOURCE_USERNAME=admin \
  -e SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_C \
  -e AWS_REGION=us-east-1 \
  --restart unless-stopped \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:cors-fix
SCRIPT

USERDATA=$(base64 < /tmp/userdata.sh)

cat > /tmp/lt-with-iam.json <<EOF
{
  "ImageId": "$ARM_AMI",
  "InstanceType": "t4g.small",
  "SecurityGroupIds": ["sg-086f5220289c5c865"],
  "IamInstanceProfile": {"Name": "concert-ec2-role"},
  "UserData": "$USERDATA"
}
EOF

aws ec2 create-launch-template-version \
  --region ap-southeast-1 \
  --launch-template-name concert-backend-lt \
  --launch-template-data file:///tmp/lt-with-iam.json

aws autoscaling update-auto-scaling-group \
  --region ap-southeast-1 \
  --auto-scaling-group-name concert-asg \
  --launch-template LaunchTemplateName=concert-backend-lt,Version='$Latest'

aws autoscaling start-instance-refresh \
  --region ap-southeast-1 \
  --auto-scaling-group-name concert-asg \
  --preferences '{"MinHealthyPercentage":0,"InstanceWarmup":300}'

echo "✅ Updated with IAM role. Backend will start in ~3 minutes."
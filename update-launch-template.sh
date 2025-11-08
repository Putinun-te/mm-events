#!/bin/bash
# Update ASG launch template with new backend JAR

cat > /tmp/user-data.sh << 'EOF'
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Download backend JAR from S3
aws s3 cp s3://concert-event-pictures-singapore-123456789012/concert-backend-1.0.0.jar /tmp/concert-backend-1.0.0.jar

# Run backend container
docker run -d \
  --name concert-backend \
  --restart unless-stopped \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306/concert_db \
  -e SPRING_DATASOURCE_USERNAME=concert_user \
  -e SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_A \
  -e AWS_REGION=ap-southeast-1 \
  -e AWS_S3_EVENT_PICTURES_BUCKET=concert-event-pictures-singapore-123456789012 \
  -e AWS_S3_USER_AVATARS_BUCKET=concert-user-avatars-singapore-123456789012 \
  -v /tmp/concert-backend-1.0.0.jar:/app.jar \
  amazoncorretto:21 java -jar /app.jar
EOF

# Create new launch template version
aws ec2 create-launch-template-version \
  --region ap-southeast-1 \
  --launch-template-id lt-0484ed89f50b411f5 \
  --source-version '$Latest' \
  --launch-template-data "{\"UserData\":\"$(base64 -i /tmp/user-data.sh)\"}" \
  --query 'LaunchTemplateVersion.VersionNumber' \
  --output text

# Update ASG to use new version
NEW_VERSION=$(aws ec2 describe-launch-template-versions --region ap-southeast-1 --launch-template-id lt-0484ed89f50b411f5 --query 'LaunchTemplateVersions[0].VersionNumber' --output text)

aws autoscaling update-auto-scaling-group \
  --region ap-southeast-1 \
  --auto-scaling-group-name concert-asg-v2 \
  --launch-template LaunchTemplateId=lt-0484ed89f50b411f5,Version=$NEW_VERSION

echo "Launch template updated to version $NEW_VERSION"

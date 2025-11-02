#!/bin/bash
set -e

INSTANCE_ID="i-02883ae4914a92e3e"
REGION="us-east-1"
JAR_S3="s3://concert-dev-frontend-142fee22/deployments/concert-backend-1.0.0.jar"

echo "Creating user data script..."
cat > /tmp/backend-userdata.sh << 'USERDATA'
#!/bin/bash
set -e

# Install Java 17
yum update -y
yum install -y java-17-amazon-corretto

# Download JAR from S3
mkdir -p /opt/concert
aws s3 cp s3://concert-dev-frontend-142fee22/deployments/concert-backend-1.0.0.jar /opt/concert/concert-backend.jar

# Create systemd service
cat > /etc/systemd/system/concert-backend.service << 'SERVICE'
[Unit]
Description=Concert Platform Backend
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/concert
ExecStart=/usr/bin/java -jar /opt/concert/concert-backend.jar
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="SERVER_PORT=8080"
Environment="SPRING_DATASOURCE_URL=jdbc:mysql://concert-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306/concert"
Environment="SPRING_DATASOURCE_USERNAME=admin"
Environment="SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_B"
Environment="SPRING_DATA_REDIS_HOST=concert-cache.tx4y2n.0001.use1.cache.amazonaws.com"
Environment="SPRING_DATA_REDIS_PORT=6379"
Environment="AWS_S3_BUCKET_EVENT_PICTURES=concert-event-pictures-142fee22"
Environment="AWS_S3_BUCKET_USER_AVATARS=concert-user-avatars-142fee22"
Environment="JWT_SECRET_KEY=your-secret-key-change-in-production-minimum-256-bits-required-for-hs256-algorithm"
Environment="JWT_EXPIRATION=86400000"

[Install]
WantedBy=multi-user.target
SERVICE

# Enable and start service
systemctl daemon-reload
systemctl enable concert-backend
systemctl start concert-backend

echo "Backend deployed successfully!"
USERDATA

# Encode user data to base64
USER_DATA_BASE64=$(base64 /tmp/backend-userdata.sh)

echo "Stopping instance $INSTANCE_ID..."
aws ec2 stop-instances --region $REGION --instance-ids $INSTANCE_ID

echo "Waiting for instance to stop..."
aws ec2 wait instance-stopped --region $REGION --instance-ids $INSTANCE_ID

echo "Updating user data..."
aws ec2 modify-instance-attribute --region $REGION --instance-id $INSTANCE_ID --user-data "$USER_DATA_BASE64"

echo "Starting instance..."
aws ec2 start-instances --region $REGION --instance-ids $INSTANCE_ID

echo "Waiting for instance to start..."
aws ec2 wait instance-running --region $REGION --instance-ids $INSTANCE_ID

echo "Waiting 60 seconds for backend to start..."
sleep 60

echo "Testing backend..."
PUBLIC_IP=$(aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
curl -s http://$PUBLIC_IP:8080/api/auth/test || echo "Backend not ready yet, may need more time"

echo "Deployment complete!"
echo "Backend should be available at: http://$PUBLIC_IP:8080"

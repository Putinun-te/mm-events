#!/bin/bash
# This script can be pasted directly into EC2 Instance Connect terminal

set -e

echo "🚀 Starting Concert Backend Deployment..."

# Download JAR from S3
echo "📦 Downloading JAR from S3..."
sudo mkdir -p /opt/concert
aws s3 cp s3://concert-dev-frontend-142fee22/deployments/concert-backend-1.0.0.jar /tmp/concert-backend.jar --region us-east-1
sudo mv /tmp/concert-backend.jar /opt/concert/concert-backend.jar

# Create systemd service
echo "⚙️  Creating systemd service..."
sudo tee /etc/systemd/system/concert-backend.service > /dev/null << 'SERVICE'
[Unit]
Description=Concert Platform Backend
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/concert
ExecStart=/usr/bin/java -jar /opt/concert/concert-backend.jar
Environment="SPRING_PROFILES_ACTIVE=prod"
Environment="SERVER_PORT=8080"
Environment="SPRING_DATASOURCE_URL=jdbc:mysql://concert-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306/concert"
Environment="SPRING_DATASOURCE_USERNAME=admin"
Environment="SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_B"
Environment="SPRING_DATA_REDIS_HOST=concert-cache.tx4y2n.0001.use1.cache.amazonaws.com"
Environment="SPRING_DATA_REDIS_PORT=6379"
Environment="AWS_S3_EVENT_PICTURES_BUCKET=concert-event-pictures-useast1-123456789012"
Environment="AWS_REGION=us-east-1"
Environment="JWT_SECRET=YourSuperSecretKeyThatIsAtLeast256BitsLong1234567890"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

# Start service
echo "🚀 Starting backend service..."
sudo systemctl daemon-reload
sudo systemctl enable concert-backend
sudo systemctl restart concert-backend

# Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 10

# Check status
echo "✅ Service status:"
sudo systemctl status concert-backend --no-pager

echo ""
echo "✅ Deployment complete!"
echo "   Check logs: sudo journalctl -u concert-backend -f"

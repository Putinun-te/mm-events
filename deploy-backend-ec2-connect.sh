#!/bin/bash
# Deploy backend to EC2 using EC2 Instance Connect

set -e

REGION="us-east-1"
INSTANCE_ID="i-02883ae4914a92e3e"
INSTANCE_IP="44.215.145.187"

echo "🚀 Concert Backend Deployment via EC2 Instance Connect"
echo "======================================================="
echo "Instance: $INSTANCE_ID ($INSTANCE_IP)"
echo ""

# Generate temporary SSH key
echo "🔑 Generating temporary SSH key..."
ssh-keygen -t rsa -f /tmp/concert_deploy_key -N '' -q
SSH_PUBLIC_KEY=$(cat /tmp/concert_deploy_key.pub)

# Send public key to instance
echo "📤 Sending SSH key to instance..."
aws ec2-instance-connect send-ssh-public-key \
  --region $REGION \
  --instance-id $INSTANCE_ID \
  --instance-os-user ec2-user \
  --ssh-public-key "$SSH_PUBLIC_KEY" \
  > /dev/null

echo "✅ SSH key sent successfully"
echo ""

# Create deployment script
cat > /tmp/backend_deploy.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

echo "📦 Downloading JAR from S3..."
sudo mkdir -p /opt/concert
aws s3 cp s3://concert-dev-frontend-142fee22/deployments/concert-backend-1.0.0.jar /tmp/concert-backend.jar --region us-east-1 || exit 1
sudo mv /tmp/concert-backend.jar /opt/concert/concert-backend.jar

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

echo "🚀 Starting service..."
sudo systemctl daemon-reload
sudo systemctl enable concert-backend
sudo systemctl restart concert-backend

echo "⏳ Waiting 10 seconds for startup..."
sleep 10

echo "✅ Service status:"
sudo systemctl status concert-backend --no-pager || true

echo ""
echo "✅ Deployment complete!"
DEPLOY_SCRIPT

# Execute deployment via SSH
echo "🚀 Executing deployment on EC2..."
echo ""
ssh -i /tmp/concert_deploy_key \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o ConnectTimeout=10 \
  ec2-user@$INSTANCE_IP \
  'bash -s' < /tmp/backend_deploy.sh

# Cleanup
rm -f /tmp/concert_deploy_key /tmp/concert_deploy_key.pub /tmp/backend_deploy.sh

echo ""
echo "🧪 Testing backend..."
sleep 5
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$INSTANCE_IP:8080/api/auth/test" || echo "000")

if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Backend is responding!"
else
    echo "⚠️  Backend returned HTTP $HTTP_CODE (might still be starting up)"
fi

echo ""
echo "======================================="
echo "✅ Deployment Complete!"
echo "======================================="
echo "Backend URL: http://$INSTANCE_IP:8080"
echo "Test endpoint: http://$INSTANCE_IP:8080/api/auth/test"
echo ""
echo "Check logs:"
echo "  ssh -i /tmp/concert_deploy_key ec2-user@$INSTANCE_IP"
echo "  sudo journalctl -u concert-backend -f"

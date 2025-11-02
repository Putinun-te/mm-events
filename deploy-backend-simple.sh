#!/bin/bash
set -e

# Configuration
REGION="us-east-1"
BUCKET="concert-dev-frontend-142fee22"
JAR_FILE="main_backend/target/concert-backend-1.0.0.jar"
JAR_NAME="concert-backend-1.0.0.jar"

echo "🚀 Concert Platform Backend Deployment"
echo "======================================="

# Check if JAR exists
if [ ! -f "$JAR_FILE" ]; then
    echo "❌ Error: JAR file not found at $JAR_FILE"
    echo "   Run: cd main_backend && mvn clean package -DskipTests"
    exit 1
fi

echo "✅ JAR file found: $JAR_FILE"
echo ""

# Upload JAR to S3
echo "📦 Step 1: Upload JAR to S3..."
aws s3 cp "$JAR_FILE" "s3://$BUCKET/deployments/$JAR_NAME" --region $REGION
echo "✅ Uploaded to s3://$BUCKET/deployments/$JAR_NAME"
echo ""

# Get database credentials from Terraform
echo "🔍 Step 2: Get infrastructure endpoints..."
cd aws
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
cd ..

# Get Redis endpoint from ElastiCache
REDIS_HOST=$(aws elasticache describe-cache-clusters \
    --region $REGION \
    --cache-cluster-id concert-cache \
    --show-cache-node-info \
    --query "CacheClusters[0].CacheNodes[0].Endpoint.Address" \
    --output text)

echo "   RDS Endpoint: $RDS_ENDPOINT"
echo "   Redis Host: $REDIS_HOST"
echo ""

# Get EC2 instance ID - try ASG instance first as it likely has SSM enabled
echo "🔍 Step 3: Get EC2 instance..."
INSTANCE_ID=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=tag:Name,Values=concert-asg-instance" "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "   ASG instance not found, trying backend instance..."
    INSTANCE_ID=$(aws ec2 describe-instances \
        --region $REGION \
        --filters "Name=tag:Name,Values=concert-backend-ec2" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].InstanceId" \
        --output text)
fi

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "❌ Error: No running EC2 instance found"
    exit 1
fi

echo "   Instance ID: $INSTANCE_ID"
echo ""

# Create deployment script
echo "🚢 Step 4: Create deployment script..."
cat > /tmp/deploy-script.sh << 'SCRIPT_END'
#!/bin/bash
set -e

# Download JAR from S3
echo "Downloading JAR from S3..."
sudo mkdir -p /opt/concert
aws s3 cp s3://BUCKET_PLACEHOLDER/deployments/JAR_NAME_PLACEHOLDER /tmp/concert-backend.jar --region us-east-1
sudo mv /tmp/concert-backend.jar /opt/concert/concert-backend.jar

# Create systemd service
echo "Creating systemd service..."
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
Environment="SPRING_DATASOURCE_URL=jdbc:mysql://RDS_ENDPOINT_PLACEHOLDER/concert"
Environment="SPRING_DATASOURCE_USERNAME=admin"
Environment="SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_B"
Environment="SPRING_DATA_REDIS_HOST=REDIS_HOST_PLACEHOLDER"
Environment="SPRING_DATA_REDIS_PORT=6379"
Environment="AWS_S3_EVENT_PICTURES_BUCKET=concert-event-pictures-useast1-123456789012"
Environment="AWS_REGION=us-east-1"
Environment="JWT_SECRET=YourSuperSecretKeyThatIsAtLeast256BitsLong1234567890"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

# Replace placeholders
sudo sed -i "s|RDS_ENDPOINT_PLACEHOLDER|RDS_ENDPOINT_VALUE|g" /etc/systemd/system/concert-backend.service
sudo sed -i "s|REDIS_HOST_PLACEHOLDER|REDIS_HOST_VALUE|g" /etc/systemd/system/concert-backend.service

# Start service
echo "Starting backend service..."
sudo systemctl daemon-reload
sudo systemctl enable concert-backend
sudo systemctl restart concert-backend

# Wait for service to start
sleep 5

# Check status
sudo systemctl status concert-backend --no-pager || true

echo "✅ Backend deployed and started!"
SCRIPT_END

# Replace placeholders in script
sed -i.bak "s|BUCKET_PLACEHOLDER|$BUCKET|g" /tmp/deploy-script.sh
sed -i.bak "s|JAR_NAME_PLACEHOLDER|$JAR_NAME|g" /tmp/deploy-script.sh
sed -i.bak "s|RDS_ENDPOINT_VALUE|$RDS_ENDPOINT|g" /tmp/deploy-script.sh
sed -i.bak "s|REDIS_HOST_VALUE|$REDIS_HOST|g" /tmp/deploy-script.sh

echo "✅ Script created"
echo ""

# Upload script to S3
echo "📤 Step 5: Upload script to S3..."
aws s3 cp /tmp/deploy-script.sh "s3://$BUCKET/deployments/deploy-script.sh" --region $REGION
echo ""

# Execute via SSM
echo "🚀 Step 6: Execute deployment on EC2..."
COMMAND_ID=$(aws ssm send-command \
    --region $REGION \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters '{"commands":["cd /tmp","aws s3 cp s3://'$BUCKET'/deployments/deploy-script.sh deploy-script.sh --region us-east-1","chmod +x deploy-script.sh","./deploy-script.sh"]}' \
    --output text \
    --query "Command.CommandId")

echo "   Command ID: $COMMAND_ID"
echo "   Waiting for deployment to complete..."
echo ""

# Wait for command to complete
for i in {1..30}; do
    STATUS=$(aws ssm get-command-invocation \
        --region $REGION \
        --command-id "$COMMAND_ID" \
        --instance-id "$INSTANCE_ID" \
        --query "Status" \
        --output text 2>/dev/null || echo "Pending")
    
    if [ "$STATUS" == "Success" ]; then
        echo "✅ Deployment successful!"
        echo ""
        
        # Get output
        echo "📋 Deployment output:"
        aws ssm get-command-invocation \
            --region $REGION \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" \
            --query "StandardOutputContent" \
            --output text
        
        break
    elif [ "$STATUS" == "Failed" ]; then
        echo "❌ Deployment failed!"
        echo ""
        
        # Get error output
        echo "📋 Error output:"
        aws ssm get-command-invocation \
            --region $REGION \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" \
            --query "StandardErrorContent" \
            --output text
        
        exit 1
    fi
    
    echo "   Status: $STATUS (attempt $i/30)"
    sleep 2
done

if [ "$STATUS" != "Success" ]; then
    echo "❌ Deployment timed out"
    exit 1
fi

echo ""
echo "🧪 Step 7: Test backend..."
INSTANCE_IP=$(aws ec2 describe-instances \
    --region $REGION \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

echo "   Testing http://$INSTANCE_IP:8080/api/auth/test"

sleep 5  # Give backend time to fully start

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$INSTANCE_IP:8080/api/auth/test" || echo "000")

if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Backend is responding!"
else
    echo "⚠️  Backend returned HTTP $HTTP_CODE"
    echo "   Check logs: aws ssm start-session --target $INSTANCE_ID"
    echo "   Then run: sudo journalctl -u concert-backend -f"
fi

echo ""
echo "=======================================
✅ Deployment Complete!
=======================================
Backend URL: http://$INSTANCE_IP:8080
Test endpoint: http://$INSTANCE_IP:8080/api/auth/test

View logs:
  aws ssm start-session --target $INSTANCE_ID
  sudo journalctl -u concert-backend -f

Check service status:
  sudo systemctl status concert-backend
"

# Cleanup
rm -f /tmp/deploy-script.sh /tmp/deploy-script.sh.bak

#!/bin/bash

# Concert Platform - Deploy Backend to EC2 via Systems Manager
# This script uploads JAR to S3 and deploys to EC2 without SSH keys

set -e

REGION="us-east-1"
INSTANCE_ID="i-0516e976bbcbda128"
S3_DEPLOYMENT_BUCKET="concert-dev-frontend-142fee22"  # Reuse existing bucket
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

# Upload JAR to S3
echo ""
echo "📦 Step 1: Upload JAR to S3..."
aws s3 cp "$JAR_FILE" "s3://$S3_DEPLOYMENT_BUCKET/deployments/$JAR_NAME" --region $REGION
echo "✅ Uploaded to s3://$S3_DEPLOYMENT_BUCKET/deployments/$JAR_NAME"

# Get RDS endpoint and credentials
echo ""
echo "🔍 Step 2: Get database credentials..."
cd aws/
RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "localhost:3306")
cd ..
echo "   RDS Endpoint: $RDS_ENDPOINT"

# Deploy via SSM
echo ""
echo "🚢 Step 3: Deploy to EC2 via Systems Manager..."
echo "   Instance ID: $INSTANCE_ID"

COMMAND=$(cat <<'EOF'
#!/bin/bash
set -e

# Download JAR from S3
echo "Downloading JAR from S3..."
sudo mkdir -p /opt/concert
aws s3 cp s3://concert-dev-frontend-142fee22/deployments/concert-backend-1.0.0.jar /tmp/concert-backend-1.0.0.jar --region us-east-1
sudo mv /tmp/concert-backend-1.0.0.jar /opt/concert/

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/concert-backend.service > /dev/null <<'SERVICE'
[Unit]
Description=Concert Platform Backend
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/concert
ExecStart=/usr/bin/java -jar /opt/concert/concert-backend-1.0.0.jar
Environment="SPRING_PROFILES_ACTIVE=prod"
Environment="SERVER_PORT=8080"
Environment="SPRING_DATASOURCE_URL=jdbc:mysql://RDS_ENDPOINT_PLACEHOLDER/concert"
Environment="SPRING_DATASOURCE_USERNAME=admin"
Environment="SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_B"
Environment="SPRING_DATA_REDIS_HOST=concert-cache.ykmwjt.0001.use1.cache.amazonaws.com"
Environment="SPRING_DATA_REDIS_PORT=6379"
Environment="AWS_S3_EVENT_PICTURES_BUCKET=concert-event-pictures-useast1-123456789012"
Environment="AWS_REGION=us-east-1"
Environment="JWT_SECRET=YourSuperSecretKeyThatIsAtLeast256BitsLong1234567890"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

# Replace RDS endpoint placeholder
sudo sed -i "s|RDS_ENDPOINT_PLACEHOLDER|RDS_ENDPOINT_VALUE|g" /etc/systemd/system/concert-backend.service

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
echo "   Check logs: sudo journalctl -u concert-backend -f"
EOF
)

# Replace RDS endpoint in command
COMMAND="${COMMAND//RDS_ENDPOINT_VALUE/$RDS_ENDPOINT}"

# Execute via SSM
COMMAND_ID=$(aws ssm send-command \
    --region $REGION \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=[\"$COMMAND\"]" \
    --output text \
    --query "Command.CommandId")

echo "   Command ID: $COMMAND_ID"
echo "   Waiting for deployment to complete..."

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
        break
    elif [ "$STATUS" == "Failed" ]; then
        echo "❌ Deployment failed!"
        aws ssm get-command-invocation \
            --region $REGION \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" \
            --query "StandardErrorContent" \
            --output text
        exit 1
    else
        echo "   Status: $STATUS (waiting...)"
        sleep 2
    fi
done

# Get output
echo ""
echo "📋 Deployment Output:"
aws ssm get-command-invocation \
    --region $REGION \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --query "StandardOutputContent" \
    --output text

echo ""
echo "🧪 Step 4: Testing backend..."
sleep 3

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://52.203.64.85:8080/api/auth/test 2>/dev/null || echo "000")

if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Backend is responding!"
    curl -s http://52.203.64.85:8080/api/auth/test
    echo ""
else
    echo "⚠️  Backend not responding yet (HTTP $HTTP_CODE)"
    echo "   It may take a few more seconds to start up"
    echo "   Check logs with: aws ssm start-session --target $INSTANCE_ID"
fi

echo ""
echo "✅ Deployment Complete!"
echo "======================================="
echo "Backend URL: http://52.203.64.85:8080"
echo "Frontend URL: http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/concert/"
echo ""
echo "Next steps:"
echo "1. Deploy frontend: cd main_frontend/concert1 && npm run generate && aws s3 sync .output/public/ s3://concert-dev-frontend-142fee22/concert/"
echo "2. Test application in browser"
echo "3. Monitor logs: aws ssm start-session --target $INSTANCE_ID"

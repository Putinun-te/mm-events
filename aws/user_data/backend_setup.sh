#!/bin/bash
# ============================================================================
# EC2 User Data Script - Concert Backend Setup
# Installs Java 21, Spring Boot application, and configures environment
# ============================================================================

set -e  # Exit on error

# Logging
LOG_FILE="/var/log/backend-setup.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "========================================="
echo "Concert Backend Setup Started"
echo "Time: $(date)"
echo "Region: ${region}"
echo "========================================="

# Update system
echo "Updating system packages..."
dnf update -y

# Install Java 21 (Amazon Corretto)
echo "Installing Java 21..."
dnf install -y java-21-amazon-corretto-devel

# Verify Java installation
java -version

# Install AWS CLI (already installed in AL2023, but update it)
echo "Updating AWS CLI..."
dnf install -y aws-cli

# Install other utilities
echo "Installing utilities..."
dnf install -y git curl wget htop jq unzip

# Create application user
echo "Creating application user..."
useradd -m -s /bin/bash concert || true

# Create application directories
echo "Creating application directories..."
mkdir -p /opt/concert/backend
mkdir -p /opt/concert/logs
mkdir -p /opt/concert/config

chown -R concert:concert /opt/concert

# Fetch RDS credentials from Secrets Manager
echo "Fetching RDS credentials..."
aws secretsmanager get-secret-value \
  --secret-id "${rds_secret_arn}" \
  --region ${region} \
  --query SecretString \
  --output text > /opt/concert/config/rds-secret.json

# Fetch ElastiCache credentials
echo "Fetching ElastiCache credentials..."
aws secretsmanager get-secret-value \
  --secret-id "${elasticache_secret_arn}" \
  --region ${region} \
  --query SecretString \
  --output text > /opt/concert/config/redis-secret.json

# Extract credentials
RDS_USERNAME=$(jq -r '.username' /opt/concert/config/rds-secret.json)
RDS_PASSWORD=$(jq -r '.password' /opt/concert/config/rds-secret.json)
RDS_HOST=$(jq -r '.host' /opt/concert/config/rds-secret.json)
REDIS_AUTH=$(jq -r '.auth_token' /opt/concert/config/redis-secret.json)

# Create Spring Boot application.properties
echo "Creating Spring Boot configuration..."
cat > /opt/concert/config/application.properties << EOF
# Server Configuration
server.port=8080
spring.application.name=concert-backend

# Database Configuration
spring.datasource.url=jdbc:mysql://${rds_endpoint}/concert_db?useSSL=true&requireSSL=false
spring.datasource.username=$RDS_USERNAME
spring.datasource.password=$RDS_PASSWORD
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA/Hibernate
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect

# Redis Configuration
spring.data.redis.host=${elasticache_endpoint}
spring.data.redis.port=6379
spring.data.redis.password=$REDIS_AUTH
spring.data.redis.ssl.enabled=true

# S3 Configuration
aws.region=${region}
aws.s3.event-pictures-bucket=${event_pictures_bucket}
aws.s3.user-avatars-bucket=${user_avatars_bucket}

# API Gateway
aws.api-gateway.endpoint=${api_gateway_endpoint}

# Logging
logging.level.root=INFO
logging.level.com.concert=DEBUG
logging.file.name=/opt/concert/logs/application.log
logging.file.max-size=10MB
logging.file.max-history=30

# Actuator
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=always
EOF

chmod 600 /opt/concert/config/application.properties
chown concert:concert /opt/concert/config/application.properties

# Create systemd service for Spring Boot
echo "Creating systemd service..."
cat > /etc/systemd/system/concert-backend.service << 'EOF'
[Unit]
Description=Concert Backend Spring Boot Application
After=network.target

[Service]
Type=simple
User=concert
WorkingDirectory=/opt/concert/backend
ExecStart=/usr/bin/java -jar /opt/concert/backend/concert-backend.jar \
  --spring.config.location=/opt/concert/config/application.properties
Restart=always
RestartSec=10
StandardOutput=append:/opt/concert/logs/service.log
StandardError=append:/opt/concert/logs/service-error.log

# Java Options
Environment="JAVA_OPTS=-Xms512m -Xmx1024m -XX:+UseG1GC"

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service (will fail until JAR is deployed, but that's OK)
systemctl daemon-reload
systemctl enable concert-backend

# Install CloudWatch Agent for monitoring
echo "Installing CloudWatch Agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "metrics": {
    "namespace": "ConcertBackend",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/concert/logs/application.log",
            "log_group_name": "/concert/backend/application",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/opt/concert/logs/service.log",
            "log_group_name": "/concert/backend/service",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Create deployment script for easy updates
cat > /opt/concert/deploy.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
# Deployment script for Concert Backend

set -e

echo "Deploying Concert Backend..."

# Stop service
sudo systemctl stop concert-backend

# Backup old JAR
if [ -f /opt/concert/backend/concert-backend.jar ]; then
  sudo cp /opt/concert/backend/concert-backend.jar \
    /opt/concert/backend/concert-backend.jar.backup-$(date +%Y%m%d-%H%M%S)
fi

# Copy new JAR (assumes JAR is uploaded to /tmp/concert-backend.jar)
if [ -f /tmp/concert-backend.jar ]; then
  sudo cp /tmp/concert-backend.jar /opt/concert/backend/concert-backend.jar
  sudo chown concert:concert /opt/concert/backend/concert-backend.jar
  sudo chmod 755 /opt/concert/backend/concert-backend.jar
fi

# Start service
sudo systemctl start concert-backend

# Check status
sleep 5
sudo systemctl status concert-backend

echo "Deployment complete!"
DEPLOY_SCRIPT

chmod +x /opt/concert/deploy.sh

# Create test S3 upload script
cat > /opt/concert/test-s3-upload.sh << 'TEST_SCRIPT'
#!/bin/bash
# Test S3 upload via presigned URL

set -e

API_ENDPOINT="${api_gateway_endpoint}"

echo "Testing S3 upload..."
echo "API Endpoint: $API_ENDPOINT"

# Create test file
echo "Test content $(date)" > /tmp/test-upload.txt

# Get presigned URL
echo "Requesting presigned URL..."
RESPONSE=$(curl -s -X POST "$API_ENDPOINT/dev/upload/event-picture" \
  -H "Content-Type: application/json" \
  -d '{"filename": "test.txt", "contentType": "text/plain"}')

echo "Response: $RESPONSE"

UPLOAD_URL=$(echo $RESPONSE | jq -r '.uploadUrl')
KEY=$(echo $RESPONSE | jq -r '.key')

echo "Upload URL: $UPLOAD_URL"
echo "Key: $KEY"

# Upload file
echo "Uploading file..."
curl -X PUT "$UPLOAD_URL" \
  -H "Content-Type: text/plain" \
  --upload-file /tmp/test-upload.txt

echo "Upload complete!"
echo "File key: $KEY"
TEST_SCRIPT

chmod +x /opt/concert/test-s3-upload.sh

# Write instance metadata
echo "Collecting instance metadata..."
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
INSTANCE_TYPE=$(ec2-metadata --instance-type | cut -d " " -f 2)
AZ=$(ec2-metadata --availability-zone | cut -d " " -f 2)

cat > /opt/concert/instance-info.json << EOF
{
  "instance_id": "$INSTANCE_ID",
  "instance_type": "$INSTANCE_TYPE",
  "availability_zone": "$AZ",
  "region": "${region}",
  "setup_time": "$(date -Iseconds)",
  "backend_version": "1.0.0"
}
EOF

echo "========================================="
echo "Concert Backend Setup Completed!"
echo "Instance ID: $INSTANCE_ID"
echo "Instance Type: $INSTANCE_TYPE"
echo "Availability Zone: $AZ"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Upload Spring Boot JAR to /tmp/concert-backend.jar"
echo "2. Run: /opt/concert/deploy.sh"
echo "3. Test S3 upload: /opt/concert/test-s3-upload.sh"
echo "4. Check logs: tail -f /opt/concert/logs/application.log"
echo "5. Check service: systemctl status concert-backend"
echo ""
echo "Application will be available at: http://$(ec2-metadata --public-ipv4 | cut -d " " -f 2):8080"
echo "========================================="

# Backend Deployment for Ubuntu EC2

## Deploy Command for Ubuntu/Debian

Use this command in the AWS Console EC2 Instance Connect terminal:

```bash
sudo apt-get update && \
sudo apt-get install -y openjdk-17-jdk awscli && \
sudo mkdir -p /opt/concert && \
aws s3 cp s3://concert-dev-frontend-142fee22/deployments/concert-backend-1.0.0.jar /opt/concert/concert-backend.jar --region us-east-1 && \
sudo bash -c 'cat > /etc/systemd/system/concert-backend.service << "SERVICE"
[Unit]
Description=Concert Platform Backend
After=network.target

[Service]
Type=simple
User=ubuntu
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
' && \
sudo systemctl daemon-reload && \
sudo systemctl enable concert-backend && \
sudo systemctl start concert-backend && \
echo "Waiting for backend to start..." && \
sleep 30 && \
curl -s http://localhost:8080/api/auth/test && \
echo -e "\n✅ Backend is running!"
```

## What this does:

1. **Updates package list** (`apt-get update`)
2. **Installs Java 17** (`openjdk-17-jdk`)
3. **Installs AWS CLI** (if not already present)
4. **Downloads the JAR** from S3
5. **Creates systemd service** with all environment variables
6. **Starts the backend** and auto-enables on boot
7. **Tests the API** to confirm it's working

## Expected Output:

After about 30 seconds, you should see:
```json
{"message":"API is working","timestamp":"2025-11-01T..."}
✅ Backend is running!
```

## Troubleshooting:

If it fails, check the logs:
```bash
sudo journalctl -u concert-backend -f
```

To restart:
```bash
sudo systemctl restart concert-backend
```

To check status:
```bash
sudo systemctl status concert-backend
```

## After Deployment:

Test from your local machine:
```bash
curl http://44.215.145.187:8080/api/auth/test
```

Then try registering on the frontend:
- **Frontend URL**: http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/
- **Backend URL**: http://44.215.145.187:8080

The 405 error should be gone! 🎉

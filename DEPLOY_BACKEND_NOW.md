# Quick Backend Deployment Guide

## Option 1: AWS Console (Easiest - No SSH Key Needed!)

1. Go to EC2 Console: https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:instanceState=running

2. Select instance `i-02883ae4914a92e3e` (concert-backend-ec2)

3. Click **"Connect"** button → **"Session Manager"** or **"EC2 Instance Connect"** tab

4. Click **"Connect"** - this opens a browser-based terminal (no SSH key needed!)

5. Paste this command and press Enter:

```bash
# One-liner deployment
sudo mkdir -p /opt/concert && \
aws s3 cp s3://concert-dev-frontend-142fee22/deployments/concert-backend-1.0.0.jar /tmp/concert-backend.jar --region us-east-1 && \
sudo mv /tmp/concert-backend.jar /opt/concert/ && \
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

sudo systemctl daemon-reload && \
sudo systemctl enable concert-backend && \
sudo systemctl restart concert-backend && \
sleep 10 && \
sudo systemctl status concert-backend
```

6. Wait ~30 seconds for the backend to start

7. Test it works:
```bash
curl http://localhost:8080/api/auth/test
```

You should see: `{"message":"API is working","timestamp":"..."}`

## Option 2: If You Have the SSH Key

If you have the `concert-deployer-key.pem` file:

```bash
# SSH into the instance
ssh -i /path/to/concert-deployer-key.pem ec2-user@44.215.145.187

# Then run the same command from Option 1
```

## After Deployment

Test the backend from your computer:
```bash
curl http://44.215.145.187:8080/api/auth/test
```

Now refresh your frontend at:
http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/

The registration should work!

## Troubleshooting

If backend doesn't start:
```bash
# Check logs
sudo journalctl -u concert-backend -f

# Check if Java is installed
java -version

# Check if JAR downloaded
ls -lh /opt/concert/
```

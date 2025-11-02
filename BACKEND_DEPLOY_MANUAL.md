# Backend Deployment - Manual Steps (Temporary)

Since SSM agent isn't configured, here's how to deploy the backend manually:

## Quick Deploy (Current Session)

The JAR has already been uploaded to S3. You can deploy it manually to the EC2 instance at `52.203.64.85`.

### Option 1: Copy and run this one-liner on EC2

```bash
# SSH into EC2 instance first (you'll need the SSH key)
ssh -i /path/to/your/key.pem ec2-user@52.203.64.85

# Then run this:
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

sudo systemctl daemon-reload
sudo systemctl enable concert-backend
sudo systemctl restart concert-backend
sleep 5
sudo systemctl status concert-backend --no-pager
```

### Option 2: Use EC2 User Data (via AWS Console)

1. Go to EC2 Console: https://console.aws.amazon.com/ec2/
2. Select instance `i-02883ae4914a92e3e` (concert-backend-ec2)
3. Actions → Instance settings → Edit user data
4. Paste the script above
5. Reboot the instance

### Check Deployment

```bash
# Test the backend
curl http://52.203.64.85:8080/api/auth/test

# Expected: 200 OK response
```

### View Logs

```bash
# SSH into EC2
ssh -i /path/to/your/key.pem ec2-user@52.203.64.85

# View logs
sudo journalctl -u concert-backend -f
```

## Infrastructure Details

- **Backend Instance**: `i-02883ae4914a92e3e` (44.215.145.187)
- **ASG Instance**: `i-0516e976bbcbda128` (52.203.64.85) - **USE THIS ONE**
- **RDS**: `concert-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306`
- **Redis**: `concert-cache.tx4y2n.0001.use1.cache.amazonaws.com:6379`
- **JAR Location**: `s3://concert-dev-frontend-142fee22/deployments/concert-backend-1.0.0.jar`

## Why SSM Failed

The EC2 instances don't have SSM agent installed/configured. To fix this permanently:

1. Add IAM role with `AmazonSSMManagedInstanceCore` policy
2. Install SSM agent on EC2 instances  
3. Then `deploy-backend-simple.sh` will work

For now, manual deployment works fine!

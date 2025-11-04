# Backend Deployment Fix - Concert Platform

## Current Status
- ✅ Frontend deployed to S3 and accessible
- ✅ API Gateway configured and routing
- ✅ MySQL 8.4.6 upgraded on RDS
- ✅ Docker MySQL 8.4.6 container running on EC2
- ✅ EC2 instance healthy and running
- ✅ Backend code updated to use environment variables for database connection
- ⚠️ Backend service not responding on port 8080 (connection refused)

## Root Cause
- Backend systemd service is configured to connect to RDS (in different VPC - unreachable)
- Backend service crashed during startup due to `SocketTimeoutException: Connect timed out`
- SSH to EC2 is timing out during banner exchange (SSH daemon might be overloaded)

## Solution Applied
1. Updated `application.properties` to use environment variable overrides:
   - `SPRING_DATASOURCE_URL` defaults to `jdbc:mysql://localhost:3306/devop_db`
   - Can be overridden via environment variable

2. Rebuilt backend JAR with updated configuration
   - New JAR: `/Users/putinan/development/DevOps/develop/main_backend/target/concert-backend-1.0.0.jar` (81MB)
   - Uploaded to S3: `s3://concert-dev-frontend-142fee22/backend-deploy/concert-backend-1.0.0.jar`

## Deployment Steps

### Option 1: Using AWS Systems Manager (Recommended)
```bash
# Start SSM session to EC2
aws ssm start-session --target i-02883ae4914a92e3e --region us-east-1

# Inside the session, run:
sudo systemctl stop concert-backend
sudo curl -f -o /opt/concert/backend/concert-backend.jar https://concert-dev-frontend-142fee22.s3.us-east-1.amazonaws.com/backend-deploy/concert-backend-1.0.0.jar
sudo chown concert:concert /opt/concert/backend/concert-backend.jar
sudo chmod 755 /opt/concert/backend/concert-backend.jar
sudo sed -i 's|jdbc:mysql://concert-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306|jdbc:mysql://localhost:3306|g' /etc/systemd/system/concert-backend.service
sudo systemctl daemon-reload
sudo systemctl start concert-backend
sudo sleep 5 && sudo systemctl status concert-backend
```

### Option 2: Using EC2 Instance Connect
```bash
# If the instance supports it:
aws ec2-instance-connect send-ssh-public-key \
  --instance-id i-02883ae4914a92e3e \
  --instance-os-user ubuntu \
  --ssh-public-key file://~/.ssh/id_rsa.pub \
  --region us-east-1

# Then SSH normally:
ssh ubuntu@44.215.145.187
```

### Option 3: Run deployment script via SSM Send-Command
```bash
aws ssm send-command \
  --region us-east-1 \
  --instance-ids i-02883ae4914a92e3e \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "cd /opt/concert/backend",
    "sudo systemctl stop concert-backend",
    "sudo curl -f -o concert-backend.jar https://concert-dev-frontend-142fee22.s3.us-east-1.amazonaws.com/backend-deploy/concert-backend-1.0.0.jar",
    "sudo chown concert:concert concert-backend.jar",
    "sudo chmod 755 concert-backend.jar",
    "sudo systemctl start concert-backend"
  ]'
```

## Configuration Details

### Backend Database Connection
- **Default (from application.properties)**: `jdbc:mysql://localhost:3306/devop_db`
- **Environment Variable**: `SPRING_DATASOURCE_URL`
- **Docker MySQL Location**: `localhost:3306` (from EC2's perspective)

### Docker MySQL Container
- **Container Name**: `concert-mysql`
- **Image**: `mysql:8.4.6`
- **Host Port**: 3306 (mapped to container port 3306)
- **Database**: `concert`
- **Username**: `admin`
- **Password**: `REDACTED_PASSWORD_B`
- **Started with**: `--restart unless-stopped`

### EC2 Details
- **Instance ID**: `i-02883ae4914a92e3e`
- **Instance IP**: `44.215.145.187` (public)
- **Region**: `us-east-1`
- **Type**: `t3.micro`
- **SSH Key**: `/Users/putinan/development/DevOps/develop/aws/concert-key.pem`

## Verification Steps

After deployment:

1. **Check service status:**
   ```bash
   # Via SSM
   aws ssm start-session --target i-02883ae4914a92e3e --region us-east-1
   systemctl status concert-backend
   ```

2. **Test API endpoint:**
   ```bash
   curl http://44.215.145.187:8080/api/auth/test
   ```

3. **Check Docker MySQL:**
   ```bash
   docker ps | grep concert-mysql
   docker logs concert-mysql | tail -20
   ```

4. **Verify database connection:**
   ```bash
   mysql -h localhost -u admin -pREDACTED_PASSWORD_C\!SecurePass -e "SELECT version();"
   ```

## Fallback Actions

If backend still doesn't start:

1. **Check Java process:**
   ```bash
   ps aux | grep java
   ```

2. **View error logs:**
   ```bash
   sudo tail -100 /opt/concert/logs/service-error.log
   sudo tail -100 /opt/concert/logs/application.log
   ```

3. **Check CloudWatch logs:**
   ```bash
   aws logs tail "/concert/ec2/system" --region us-east-1
   ```

4. **Verify Docker MySQL is running:**
   ```bash
   docker ps
   docker logs concert-mysql
   ```

5. **Manual database check:**
   ```bash
   mysql -h localhost -u admin -pREDACTED_PASSWORD_C\!SecurePass concert < /dev/null
   ```

## Next Steps (Infrastructure)

1. **VPC Peering Fix**: The VPC isolation issue between EC2 and RDS should be permanently fixed by:
   - Moving RDS to EC2's VPC, OR
   - Implementing RDS Proxy, OR
   - Using separate database instances per VPC

2. **DNS/Route53**: Consider adding Route53 records for backend API

3. **Load Balancing**: Consider adding ALB/NLB for better reliability

## Files Modified

- `main_backend/src/main/resources/application.properties` - Updated to use environment variables
- `main_backend/target/concert-backend-1.0.0.jar` - Rebuilt with updated configuration

## Summary

The backend is now configured to connect to the Docker MySQL container running locally on the EC2 instance. This bypasses the VPC isolation issue with RDS. Once the new JAR is deployed and the service is restarted, the backend should:

1. Successfully connect to Docker MySQL on `localhost:3306`
2. Respond to API requests on port 8080
3. Be accessible through API Gateway at `https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod`

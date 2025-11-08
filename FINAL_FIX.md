# Final Fix Required

## Issue
Backend fails to start with: `Access denied for user 'concert_user'@'172.31.30.48' (using password: YES)`

## Root Cause
The RDS database user `concert_user` either:
1. Doesn't exist
2. Has wrong password
3. Doesn't have proper permissions

## Solution

### Option 1: Use admin user (Quick Fix)
Deploy with admin credentials that we know work:

```bash
aws ssm send-command \
  --instance-ids "i-0ffd487469a6fa1aa" \
  --document-name "AWS-RunShellScript" \
  --region ap-southeast-1 \
  --parameters 'commands=[
    "docker stop $(docker ps -q) 2>/dev/null || true",
    "docker rm $(docker ps -aq) 2>/dev/null || true", 
    "docker run -d -p 8080:8080 \
      -e SPRING_DATASOURCE_URL=jdbc:mysql://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306/concert_db \
      -e SPRING_DATASOURCE_USERNAME=admin \
      -e SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_C \
      -e AWS_REGION=us-east-1 \
      --restart unless-stopped \
      123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:cors-fix"
  ]'
```

### Option 2: Create concert_user in RDS
Connect to RDS and create the user:

```sql
CREATE USER 'concert_user'@'%' IDENTIFIED BY 'REDACTED_PASSWORD_A';
GRANT ALL PRIVILEGES ON concert_db.* TO 'concert_user'@'%';
FLUSH PRIVILEGES;
```

## HTTPS Solution Already Implemented

✅ API Gateway HTTPS proxy created: `https://t4elolxqp8.execute-api.ap-southeast-1.amazonaws.com`
✅ Frontend .env updated to use HTTPS endpoint
✅ CORS configuration added to backend

Once backend starts, everything will work!
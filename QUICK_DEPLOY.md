# Quick Deployment Commands

## Deploy Backend
```bash
./deploy-backend.sh
```

## Deploy Frontend
```bash
./deploy-frontend.sh
```

## Test Backend
```bash
curl http://52.203.64.85:8080/api/auth/test
# Should return: "Hello from secured API!"
```

## Test Frontend
Open in browser:
```
http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/concert/
```

## View Logs
```bash
# Start SSH session via Systems Manager
aws ssm start-session --target i-0516e976bbcbda128 --region us-east-1

# On EC2, view logs:
sudo journalctl -u concert-backend -f
```

## Rebuild & Redeploy

### Backend changes:
```bash
cd main_backend
JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn clean package -DskipTests
cd ..
./deploy-backend.sh
```

### Frontend changes:
```bash
./deploy-frontend.sh
```

## AWS Support Request

Submit ticket for CloudFront + ALB:
1. Go to: AWS Console → Support → Create Case
2. Use template from: `aws/API_GATEWAY_ALB_RESTRICTION.md`
3. Wait 1-2 business days

## Architecture

```
Current (Working Now):
User → S3 (HTTP) → EC2:8080 → RDS/Redis

Future (After Approval):
User → CloudFront (HTTPS) → S3
                              ↓
                        API Gateway → VPC Link → ALB → EC2 → RDS/Redis
```

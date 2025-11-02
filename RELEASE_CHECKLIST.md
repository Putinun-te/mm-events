# Release Checklist - Concert Platform v1.0

## 📋 Pre-Release Checklist

### 1. Code Quality ✅
- [x] All backend tests passing
- [x] All frontend tests passing
- [x] No compiler errors
- [ ] Code reviewed
- [ ] Security scan completed
- [ ] Performance testing done

### 2. Infrastructure Ready ✅
- [x] AWS Account configured
- [x] All services deployed:
  - [x] S3 buckets (frontend, event-pictures, user-avatars)
  - [x] Cognito (User Pool + Identity Pool)
  - [x] RDS MySQL database
  - [x] ElastiCache Redis
  - [x] EC2 Auto Scaling Group
  - [x] VPC and networking
  - [x] CloudWatch monitoring
  - [x] IAM roles and policies
- [ ] API Gateway deployed
- [ ] Load testing completed
- [x] Backup strategy configured

### 3. Database ✅
- [x] Schema created
- [x] Migrations ready:
  - [x] Initial schema (users, events, bookings)
  - [x] Event photo columns
- [ ] Database migrations tested
- [ ] Production data seeded (if needed)
- [x] Backup configured (7-day retention)

### 4. Backend Application
- [ ] Configuration reviewed:
  - [ ] Database connection strings
  - [ ] Redis connection
  - [ ] S3 bucket names
  - [ ] JWT secret configured
  - [ ] CORS origins set
  - [ ] AWS region set
- [ ] Environment variables set on EC2
- [ ] Logging configured
- [ ] Error handling tested
- [ ] API documentation complete

### 5. Frontend Application
- [ ] Environment variables configured:
  - [ ] API_BASE_URL (API Gateway URL)
  - [ ] Cognito User Pool ID
  - [ ] Cognito Client ID
  - [ ] Cognito Region
  - [ ] S3 bucket URLs
- [ ] Production build tested
- [ ] SEO metadata added
- [ ] Analytics configured (if needed)
- [ ] Error tracking (Sentry, etc.) configured

### 6. Security 🔐
- [x] HTTPS configured (when CloudFront enabled)
- [x] Cognito authentication implemented
- [x] JWT token validation working
- [x] IAM roles follow least privilege
- [x] Security groups properly configured
- [x] Secrets in AWS Secrets Manager
- [ ] Penetration testing done
- [ ] OWASP top 10 addressed
- [ ] Rate limiting tested
- [ ] Input validation implemented

### 7. Monitoring & Logging 📊
- [x] CloudWatch dashboards created
- [x] CloudWatch alarms configured:
  - [x] EC2 High CPU (>80%)
  - [x] RDS High CPU (>75%)
  - [x] RDS Low Storage (<2GB)
  - [x] Redis High Memory (>80%)
  - [x] Redis Low Hit Rate (<50%)
- [ ] API Gateway logging enabled
- [ ] Application logs shipping to CloudWatch
- [ ] Error alerting configured
- [ ] On-call rotation setup

### 8. Documentation 📚
- [x] README.md updated
- [x] API documentation complete
- [x] Infrastructure documentation
- [x] Deployment guides:
  - [x] Backend deployment
  - [x] Frontend deployment
  - [x] Database migration
  - [x] CloudFront activation
  - [x] API Gateway setup
- [x] Architecture diagrams
- [x] Troubleshooting guide
- [ ] User documentation
- [ ] Release notes

### 9. CI/CD Pipeline 🚀
- [x] GitHub Actions workflow created
- [ ] GitHub secrets configured:
  - [ ] AWS_ACCESS_KEY_ID
  - [ ] AWS_SECRET_ACCESS_KEY
  - [ ] EC2_SSH_PRIVATE_KEY
  - [ ] API_BASE_URL
- [ ] CI/CD pipeline tested
- [ ] Automated tests in pipeline
- [ ] Deployment notifications configured
- [ ] Rollback procedure tested

### 10. Third-Party Services
- [ ] Email service configured (AWS SES)
- [ ] SMS service configured (AWS SNS) - if needed
- [ ] Payment gateway configured - if needed
- [ ] Analytics service configured - if needed
- [ ] CDN configured (CloudFront - waiting for AWS approval)

---

## 🚀 Release Deployment Steps

### Phase 1: Pre-Deployment (2-3 hours)

#### 1.1. Code Freeze
```bash
# Create release branch
git checkout main
git pull origin main
git checkout -b release/v1.0.0
git push origin release/v1.0.0
```

#### 1.2. Final Testing
```bash
# Backend tests
cd main_backend
JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn clean test

# Frontend tests
cd ../main_frontend/concert1
npm run test

# Build verification
npm run build
```

#### 1.3. Update Version Numbers
```bash
# Backend - pom.xml
<version>1.0.0</version>

# Frontend - package.json
"version": "1.0.0"
```

#### 1.4. Database Backup
```bash
# Create RDS snapshot
aws rds create-db-snapshot \
  --db-instance-identifier concert-db-dev \
  --db-snapshot-identifier concert-db-pre-release-v1.0.0

# Verify snapshot
aws rds describe-db-snapshots \
  --db-snapshot-identifier concert-db-pre-release-v1.0.0
```

### Phase 2: Database Migration (30 minutes)

#### 2.1. Run Migrations
```bash
# Connect to RDS
mysql -h <RDS_ENDPOINT> -u admin -p

# Run migrations in order
source database-setup.sql/01_initial_schema.sql
source database-setup.sql/02_bookings_table.sql
source database-setup.sql/03_indexes.sql
source database-setup.sql/04_add_event_photo_columns.sql

# Verify
SHOW TABLES;
DESCRIBE events;
```

#### 2.2. Verify Migration
```sql
-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'concert_db';

-- Check photo columns
SELECT column_name, column_type 
FROM information_schema.columns 
WHERE table_name = 'events' 
  AND column_name IN ('photo_id', 'photo_url');
```

### Phase 3: Backend Deployment (1 hour)

#### 3.1. Build Backend
```bash
cd main_backend

# Update application.properties for production
cat > src/main/resources/application-prod.properties << EOF
spring.datasource.url=jdbc:mysql://<RDS_ENDPOINT>:3306/concert_db
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}

spring.redis.host=<REDIS_ENDPOINT>
spring.redis.port=6379

aws.region=us-east-1
aws.s3.event-pictures-bucket=concert-event-pictures-useast1-123456789012
aws.s3.user-avatars-bucket=concert-user-avatars-useast1-123456789012

jwt.secret=${JWT_SECRET}
jwt.expiration=86400000

spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
EOF

# Build
mvn clean package -DskipTests -Pprod

# Verify JAR
ls -lh target/*.jar
```

#### 3.2. Deploy to EC2
```bash
# Option 1: Via CI/CD (Recommended)
git add .
git commit -m "chore: prepare for v1.0.0 release"
git push origin release/v1.0.0

# Option 2: Manual deployment
EC2_IP=<EC2_PUBLIC_IP>
scp target/concert-backend-1.0.0.jar ec2-user@$EC2_IP:~/

ssh ec2-user@$EC2_IP << 'EOF'
  sudo systemctl stop concert-backend
  mv ~/concert-backend-1.0.0.jar /opt/concert/concert-backend.jar
  sudo systemctl start concert-backend
  sudo systemctl status concert-backend
  
  # Check logs
  sudo journalctl -u concert-backend -f
EOF
```

#### 3.3. Verify Backend
```bash
# Health check
curl http://<EC2_IP>:8080/api/auth/test

# Test endpoints
curl http://<EC2_IP>:8080/api/events

# Check logs
ssh ec2-user@<EC2_IP> 'sudo tail -f /var/log/concert-backend/application.log'
```

### Phase 4: API Gateway Deployment (30 minutes)

#### 4.1. Deploy API Gateway
```bash
cd aws/

# Review plan
terraform plan -out=api-gateway.tfplan

# Apply
terraform apply api-gateway.tfplan

# Get API Gateway URL
terraform output api_gateway_url
# Save this URL: https://abc123.execute-api.us-east-1.amazonaws.com/prod
```

#### 4.2. Test API Gateway
```bash
API_URL=$(terraform output -raw api_gateway_url)

# Test public endpoint
curl $API_URL/api/events

# Test auth endpoint
curl -X POST $API_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"Test123!","email":"test@example.com","name":"Test User"}'

# Test login
curl -X POST $API_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"Test123!"}'
```

### Phase 5: Frontend Deployment (30 minutes)

#### 5.1. Configure Environment
```bash
cd main_frontend/concert1

# Create production environment file
cat > .env.production << EOF
# API Gateway URL (from terraform output)
NUXT_PUBLIC_API_BASE_URL=https://abc123.execute-api.us-east-1.amazonaws.com/prod

# Cognito Configuration
NUXT_PUBLIC_COGNITO_REGION=us-east-1
NUXT_PUBLIC_COGNITO_USER_POOL_ID=us-east-1_TpsZkFbqO
NUXT_PUBLIC_COGNITO_CLIENT_ID=1eomnjf6812g8npdr8ta8naem7
NUXT_PUBLIC_COGNITO_DOMAIN=concert-auth-123456789012.auth.us-east-1.amazoncognito.com

# S3 Buckets
NUXT_PUBLIC_S3_EVENT_PICTURES_BUCKET=concert-event-pictures-useast1-123456789012
NUXT_PUBLIC_S3_USER_AVATARS_BUCKET=concert-user-avatars-useast1-123456789012

# Application
NUXT_PUBLIC_APP_NAME=Concert Platform
NUXT_PUBLIC_APP_VERSION=1.0.0
EOF
```

#### 5.2. Build Frontend
```bash
# Build for production
npm run generate

# Verify build
ls -lh .output/public/
```

#### 5.3. Deploy to S3
```bash
# Get S3 bucket name
cd ../../aws
S3_BUCKET=$(terraform output -raw frontend_s3_bucket_name)

# Sync to S3
aws s3 sync ../main_frontend/concert1/.output/public s3://$S3_BUCKET \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "*.html" \
  --exclude "*.json"

# HTML files with no-cache
aws s3 sync ../main_frontend/concert1/.output/public s3://$S3_BUCKET \
  --delete \
  --cache-control "no-cache, no-store, must-revalidate" \
  --exclude "*" \
  --include "*.html" \
  --include "*.json"

# Set public read permissions
aws s3 cp s3://$S3_BUCKET s3://$S3_BUCKET \
  --recursive \
  --acl public-read
```

#### 5.4. Verify Frontend
```bash
# Get S3 website URL
S3_URL=$(terraform output -raw frontend_s3_website_url)

# Open in browser
open $S3_URL

# Test pages
curl $S3_URL
curl $S3_URL/events
curl $S3_URL/login
```

### Phase 6: Post-Deployment Verification (30 minutes)

#### 6.1. Smoke Tests
```bash
# Test user registration
curl -X POST $API_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username":"smoketest",
    "password":"Test123!",
    "email":"smoke@test.com",
    "name":"Smoke Test"
  }'

# Test login
TOKEN=$(curl -X POST $API_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"smoketest","password":"Test123!"}' \
  | jq -r '.token')

echo "Token: $TOKEN"

# Test create event
curl -X POST $API_URL/api/events \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title":"Release Test Event",
    "description":"Testing v1.0.0 release",
    "startDate":"2025-12-01T19:00:00",
    "endDate":"2025-12-01T23:00:00",
    "personLimit":100,
    "address":"Test Venue"
  }'

# Test list events
curl $API_URL/api/events

# Test my events
curl $API_URL/api/events/me \
  -H "Authorization: Bearer $TOKEN"
```

#### 6.2. Monitor CloudWatch
```bash
# Check application logs
aws logs tail /aws/concert/application --follow

# Check API Gateway logs
aws logs tail /aws/apigateway/concert-dev --follow

# Check metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=concert-backend-asg-dev \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

#### 6.3. Security Verification
```bash
# Test rate limiting
for i in {1..100}; do
  curl -s -o /dev/null -w "%{http_code}\n" $API_URL/api/events
done
# Should see some 429 (Too Many Requests) responses

# Test unauthorized access
curl -X POST $API_URL/api/events \
  -H "Content-Type: application/json" \
  -d '{"title":"Unauthorized Test"}'
# Should return 401 Unauthorized

# Test invalid token
curl $API_URL/api/events/me \
  -H "Authorization: Bearer invalid-token"
# Should return 401 Unauthorized
```

### Phase 7: Configure CI/CD (15 minutes)

#### 7.1. Add GitHub Secrets
```bash
# Go to: https://github.com/MorningMores/Test/settings/secrets/actions
# Add the following secrets:

AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-key>
EC2_SSH_PRIVATE_KEY=<your-ec2-private-key-content>
API_BASE_URL=https://abc123.execute-api.us-east-1.amazonaws.com/prod
```

#### 7.2. Test CI/CD Pipeline
```bash
# Merge release branch to main
git checkout main
git merge release/v1.0.0
git push origin main

# Monitor GitHub Actions
# https://github.com/MorningMores/Test/actions

# Check deployment logs
```

### Phase 8: Create Release Tag

```bash
# Create and push tag
git tag -a v1.0.0 -m "Release v1.0.0 - Initial production release

Features:
- User authentication with Cognito
- Event management (create, list, view)
- Booking system
- Event photo uploads to S3
- API Gateway with rate limiting
- Auto-scaling backend
- CloudWatch monitoring
- CI/CD pipeline with GitHub Actions

Infrastructure:
- AWS Multi-tier architecture
- RDS MySQL database
- ElastiCache Redis
- S3 static website hosting
- Cognito authentication
- IAM security
- VPC networking
"

git push origin v1.0.0

# Create GitHub release
gh release create v1.0.0 \
  --title "Concert Platform v1.0.0" \
  --notes-file RELEASE_NOTES.md
```

---

## 📊 Post-Release Monitoring (First 24 Hours)

### Monitor These Metrics:

1. **Application Health**
   - Backend uptime: Target >99.9%
   - API response time: Target <200ms
   - Error rate: Target <1%

2. **Infrastructure**
   - EC2 CPU: Should be <50% average
   - RDS connections: Monitor for leaks
   - Redis memory: Should be <70%
   - S3 request count

3. **User Metrics**
   - Registrations
   - Login success rate
   - Events created
   - Bookings made
   - Photo uploads

4. **Errors**
   - 4XX errors (client errors)
   - 5XX errors (server errors)
   - Database errors
   - S3 upload failures

### CloudWatch Dashboard
```bash
# Open dashboard
open "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=concert-dashboard"
```

### Set Up Alerts
```bash
# Create SNS topic for alerts
aws sns create-topic --name concert-alerts

# Subscribe your email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:concert-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com
```

---

## 🔄 Rollback Plan

### If Critical Issues Occur:

#### Option 1: Rollback Backend Only
```bash
# SSH to EC2
ssh ec2-user@<EC2_IP>

# Restore previous version
sudo systemctl stop concert-backend
sudo cp /opt/concert/concert-backend.jar.backup /opt/concert/concert-backend.jar
sudo systemctl start concert-backend
sudo systemctl status concert-backend
```

#### Option 2: Rollback Frontend Only
```bash
cd aws/

# Get previous deployment from git
git checkout <previous-commit>
cd ../main_frontend/concert1
npm run generate

# Redeploy to S3
S3_BUCKET=$(cd ../../aws && terraform output -raw frontend_s3_bucket_name)
aws s3 sync .output/public s3://$S3_BUCKET --delete
```

#### Option 3: Rollback Database
```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier concert-db-dev-restored \
  --db-snapshot-identifier concert-db-pre-release-v1.0.0

# Update backend to use restored instance
# Update terraform and reapply
```

#### Option 4: Complete Rollback
```bash
# 1. Rollback git
git revert <release-commit>
git push origin main

# 2. CI/CD will automatically deploy previous version

# 3. Monitor deployment
```

---

## ✅ Release Completion Checklist

- [ ] All deployment phases completed
- [ ] Smoke tests passed
- [ ] No critical errors in logs
- [ ] CloudWatch metrics look healthy
- [ ] Users can register/login
- [ ] Events can be created
- [ ] Photos can be uploaded
- [ ] CI/CD pipeline working
- [ ] Team notified of release
- [ ] Release notes published
- [ ] Documentation updated
- [ ] Monitoring dashboard reviewed
- [ ] On-call engineer briefed

---

## 📞 Emergency Contacts

- **DevOps Lead**: [Contact]
- **Backend Lead**: [Contact]
- **Frontend Lead**: [Contact]
- **AWS Support**: 1-866-762-2974
- **On-Call Engineer**: [Contact]

---

## 📚 Reference Documents

- [Architecture Documentation](DEVOPS_INFRASTRUCTURE.md)
- [API Gateway Setup](aws/API_GATEWAY_SETUP_GUIDE.md)
- [CloudFront Activation](aws/CLOUDFRONT_ENABLE_WHEN_READY.md)
- [CI/CD Setup](CICD_SETUP_COMPLETE.md)
- [Testing Guide](TESTING_QUICK_REFERENCE.md)
- [Production Readiness](aws/PRODUCTION_READINESS_CHECKLIST.md)

---

**Release Manager**: _____________  
**Date**: November 1, 2025  
**Version**: 1.0.0  
**Status**: Ready for Deployment ✅

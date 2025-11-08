#!/bin/bash

# Setup RDS database from EC2 instance

INSTANCE_IP="54.169.228.75"
RDS_HOST="concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com"

# Create SQL commands
cat > /tmp/setup-db.sql << 'EOF'
-- Create concert_user if not exists
CREATE USER IF NOT EXISTS 'concert_user'@'%' IDENTIFIED BY 'REDACTED_PASSWORD_A';
GRANT ALL PRIVILEGES ON concert_db.* TO 'concert_user'@'%';
FLUSH PRIVILEGES;

-- Show current tables
SHOW TABLES;
EOF

# Copy SQL file to EC2
aws ssm send-command \
  --region ap-southeast-1 \
  --document-name "AWS-RunShellScript" \
  --targets "Key=instanceids,Values=i-067f65d88f1ba751a" \
  --parameters 'commands=[
    "docker run --rm mysql:8.0 mysql -h '"$RDS_HOST"' -u admin -pREDACTED_PASSWORD_A concert_db -e \"CREATE USER IF NOT EXISTS '\'concert_user\''@'\''%'\'' IDENTIFIED BY '\'REDACTED_PASSWORD_A\''; GRANT ALL PRIVILEGES ON concert_db.* TO '\'concert_user\''@'\''%\''; FLUSH PRIVILEGES;\" 2>&1 | grep -v Warning",
    "docker run --rm mysql:8.0 mysql -h '"$RDS_HOST"' -u concert_user -pREDACTED_PASSWORD_A concert_db -e \"SHOW TABLES;\" 2>&1 | grep -v Warning"
  ]' \
  --output text

echo "Database setup command sent. Check AWS Systems Manager console for results."

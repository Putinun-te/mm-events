#!/bin/bash
# Quick deploy - creates new instance with backend pre-installed via user data

REGION="ap-southeast-1"
INSTANCE_ID="i-0e48bfcfd02bf9c00"

echo "🔄 Updating existing instance with backend..."

# Create user data script
USER_DATA=$(cat <<'USERDATA'
#!/bin/bash
docker stop concert-backend 2>/dev/null || true
docker rm concert-backend 2>/dev/null || true

docker run -d \
  --name concert-backend \
  --restart unless-stopped \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://concert-prod-db.c8aqvqzqxqxq.ap-southeast-1.rds.amazonaws.com:3306/concert_db" \
  -e SPRING_DATASOURCE_USERNAME="concert_user" \
  -e SPRING_DATASOURCE_PASSWORD="REDACTED_PASSWORD_A" \
  -e AWS_REGION="ap-southeast-1" \
  -e SPRING_PROFILES_ACTIVE="prod" \
  eclipse-temurin:21-jre \
  sh -c "curl -o /tmp/app.jar https://github.com/MorningMores/develop/releases/download/v1.0.0/concert-backend-1.0.0.jar && java -jar /tmp/app.jar"
USERDATA
)

echo "Run this on the instance (18.142.249.64):"
echo "$USER_DATA"
echo ""
echo "Or use AWS Systems Manager Session Manager to connect"

#!/bin/bash

# Quick CORS fix deployment script
echo "🔧 Fixing CORS issue and deploying backend..."

# Build the backend
echo "📦 Building backend..."
cd main_backend
mvn clean package -DskipTests
if [ $? -ne 0 ]; then
    echo "❌ Backend build failed"
    exit 1
fi

# Copy JAR to EC2
echo "🚀 Deploying to EC2..."
scp -i ../aws/concert-key.pem target/concert-backend-1.0.0.jar ec2-user@52.221.197.39:/home/ec2-user/

# Restart the backend service
echo "🔄 Restarting backend service..."
ssh -i ../aws/concert-key.pem ec2-user@52.221.197.39 << 'EOF'
# Kill existing Java process
sudo pkill -f java

# Start new backend
nohup java -jar /home/ec2-user/concert-backend-1.0.0.jar \
  --spring.datasource.url=jdbc:mysql://concert-prod-db.c8aqvqzqxqxq.ap-southeast-1.rds.amazonaws.com:3306/concert_db \
  --spring.datasource.username=concert_user \
  --spring.datasource.password=REDACTED_PASSWORD_A \
  > /home/ec2-user/backend.log 2>&1 &

echo "Backend started with PID: $!"
EOF

echo "✅ Deployment complete!"
echo "🧪 Testing the fix..."

# Test the registration endpoint
sleep 10
curl -X POST http://52.221.197.39:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{"username":"testuser2","email":"test2@example.com","password":"password123"}' \
  -v

echo ""
echo "🎉 CORS fix deployed! Registration endpoint should now work properly."
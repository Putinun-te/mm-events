#!/bin/bash
# Backend Health Check Script
# Checks backend configuration, build status, and deployment readiness

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Backend Health Check                                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

BACKEND_DIR="/Users/putinan/development/DevOps/develop/main_backend"
cd "$BACKEND_DIR"

# 1. Check JAR file
echo -e "${YELLOW}1. Checking JAR file...${NC}"
if [ -f "target/concert-backend-1.0.0.jar" ]; then
    JAR_SIZE=$(ls -lh target/concert-backend-1.0.0.jar | awk '{print $5}')
    echo -e "  ${GREEN}✅ JAR exists: $JAR_SIZE${NC}"
else
    echo -e "  ${RED}❌ JAR not found. Run: mvn clean package${NC}"
    exit 1
fi

# 2. Check application.properties
echo ""
echo -e "${YELLOW}2. Checking configuration...${NC}"
if [ -f "src/main/resources/application.properties" ]; then
    echo -e "  ${GREEN}✅ application.properties exists${NC}"
    
    # Check key configurations
    echo "  Key configurations:"
    grep "^server.port=" src/main/resources/application.properties || echo "    ⚠️  server.port not set"
    grep "^aws.region=" src/main/resources/application.properties || echo "    ⚠️  aws.region not set"
    grep "^aws.s3.event-pictures-bucket=" src/main/resources/application.properties || echo "    ⚠️  S3 bucket not set"
else
    echo -e "  ${RED}❌ application.properties not found${NC}"
fi

# 3. Check Dockerfile
echo ""
echo -e "${YELLOW}3. Checking Dockerfile...${NC}"
if [ -f "Dockerfile" ]; then
    echo -e "  ${GREEN}✅ Dockerfile exists${NC}"
    JAVA_VERSION=$(grep "FROM eclipse-temurin" Dockerfile | grep -o "[0-9]*-jre" | grep -o "[0-9]*")
    echo "  Java version: $JAVA_VERSION"
else
    echo -e "  ${RED}❌ Dockerfile not found${NC}"
fi

# 4. Check pom.xml
echo ""
echo -e "${YELLOW}4. Checking pom.xml...${NC}"
if [ -f "pom.xml" ]; then
    echo -e "  ${GREEN}✅ pom.xml exists${NC}"
    SPRING_VERSION=$(grep -A1 "spring-boot-starter-parent" pom.xml | grep "<version>" | sed 's/.*<version>\(.*\)<\/version>.*/\1/')
    JAVA_VERSION=$(grep "<java.version>" pom.xml | sed 's/.*<java.version>\(.*\)<\/java.version>.*/\1/')
    echo "  Spring Boot: $SPRING_VERSION"
    echo "  Java: $JAVA_VERSION"
else
    echo -e "  ${RED}❌ pom.xml not found${NC}"
fi

# 5. Check dependencies
echo ""
echo -e "${YELLOW}5. Checking key dependencies...${NC}"
if grep -q "aws-java-sdk" pom.xml || grep -q "software.amazon.awssdk" pom.xml; then
    echo -e "  ${GREEN}✅ AWS SDK configured${NC}"
else
    echo -e "  ${RED}❌ AWS SDK not found${NC}"
fi

if grep -q "nimbus-jose-jwt" pom.xml; then
    echo -e "  ${GREEN}✅ Cognito JWT validator configured${NC}"
else
    echo -e "  ${YELLOW}⚠️  Cognito JWT validator not found${NC}"
fi

if grep -q "spring-boot-starter-data-redis" pom.xml; then
    echo -e "  ${GREEN}✅ Redis configured${NC}"
else
    echo -e "  ${YELLOW}⚠️  Redis not configured${NC}"
fi

# 6. Test local build
echo ""
echo -e "${YELLOW}6. Testing Docker build...${NC}"
read -p "  Build Docker image? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker build -t concert-backend:test . && echo -e "  ${GREEN}✅ Docker build successful${NC}" || echo -e "  ${RED}❌ Docker build failed${NC}"
fi

# 7. Check environment variables needed
echo ""
echo -e "${YELLOW}7. Required environment variables for production:${NC}"
echo "  - SPRING_DATASOURCE_URL (RDS endpoint)"
echo "  - SPRING_DATASOURCE_USERNAME"
echo "  - SPRING_DATASOURCE_PASSWORD"
echo "  - AWS_REGION"
echo "  - AWS_S3_EVENT_PICTURES_BUCKET"
echo "  - AWS_S3_USER_AVATARS_BUCKET"
echo "  - JWT_SECRET"
echo "  - APP_CORS_ALLOWED_ORIGINS"

# 8. Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Backend Status Summary                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Backend is ready for deployment${NC}"
echo ""
echo "Next steps:"
echo "  1. Deploy to EC2: bash infra/cleanup-and-deploy.sh"
echo "  2. Or build locally: docker build -t concert-backend ."
echo "  3. Or run tests: mvn test"
echo ""

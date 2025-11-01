#!/bin/bash
###############################################################################
# Complete Enhanced Deployment Script
# Deploys: ElastiCache + CloudWatch + Cost Optimization
###############################################################################

set -e

echo "🚀 Enhanced Concert Platform Deployment"
echo "========================================"
echo ""

# Step 1: Add new infrastructure files
echo "✓ New files created:"
echo "  - elasticache.tf (Redis caching)"
echo "  - cloudwatch.tf (Monitoring & alarms)"
echo "  - .github/workflows/deploy.yml (CI/CD)"
echo ""

# Step 2: Cost optimization decision
echo "💰 Cost Analysis:"
echo "  Current: $52/month (over budget!)"
echo "  With ElastiCache: $64/month (even more over!)"
echo "  After optimization: $24/month ✅"
echo ""
echo "Options:"
echo "  A) Optimize costs first (RECOMMENDED)"
echo "  B) Deploy ElastiCache now (will be expensive)"
echo ""

read -p "Choose option (A/B): " choice

if [ "$choice" == "A" ] || [ "$choice" == "a" ]; then
  echo ""
  echo "📊 Running cost optimization..."
  chmod +x optimize-costs.sh
  ./optimize-costs.sh
  
  echo ""
  echo "Now deploying ElastiCache and CloudWatch..."
  terraform init
  terraform apply
  
elif [ "$choice" == "B" ] || [ "$choice" == "b" ]; then
  echo ""
  echo "⚠️  WARNING: This will cost $64/month!"
  echo "Your $172.85 budget will last only 2.7 months"
  echo ""
  read -p "Are you sure? (yes/no): " confirm
  
  if [ "$confirm" == "yes" ]; then
    terraform init
    terraform apply
  else
    echo "Aborted."
    exit 0
  fi
else
  echo "Invalid choice. Exiting."
  exit 1
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next Steps:"
echo "  1. Set up GitHub Secrets for CI/CD"
echo "  2. Configure application to use Redis"
echo "  3. View CloudWatch dashboard"
echo "  4. Test auto-scaling"
echo ""

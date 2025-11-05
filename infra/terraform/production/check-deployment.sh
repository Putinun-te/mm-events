#!/usr/bin/env bash
# Check deployment status

set -e

echo "=== Checking Terraform Deployment Status ==="
echo ""

# Check if process is running
if ps aux | grep terraform | grep -v grep | grep -v check-deployment > /dev/null; then
  echo "⏳ Status: DEPLOYING"
  echo ""
  echo "Last 10 log lines:"
  tail -10 apply-retry.log 2>/dev/null || tail -10 apply-final.log 2>/dev/null || echo "No log file found"
else
  echo "✅ Status: COMPLETED (or stopped)"
  echo ""
  
  # Check for errors in log
  if grep -q "Error:" apply-retry.log 2>/dev/null || grep -q "Error:" apply-final.log 2>/dev/null; then
    echo "❌ Errors found in deployment log:"
    grep "Error:" apply-retry.log apply-final.log 2>/dev/null | tail -5
  else
    echo "✅ No errors detected"
    echo ""
    echo "=== Infrastructure Outputs ==="
    terraform output 2>/dev/null || echo "Run 'terraform output' to see endpoints"
  fi
fi

echo ""
echo "Full log: cat apply-retry.log"

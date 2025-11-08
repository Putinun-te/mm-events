#!/bin/bash
echo "🔍 Auto Scaling Status"
echo "====================="
aws autoscaling describe-auto-scaling-groups \
  --region ap-southeast-1 \
  --auto-scaling-group-names concert-asg \
  --query 'AutoScalingGroups[0].{Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Current:Instances|length(@),Instances:Instances[*].{ID:InstanceId,Health:HealthStatus,State:LifecycleState}}' \
  --output table

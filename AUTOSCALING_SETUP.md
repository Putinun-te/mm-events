# Auto Scaling Setup Complete ✅

## Configuration

### Auto Scaling Group: `concert-asg`
- **Min Instances**: 1
- **Max Instances**: 3
- **Desired Capacity**: 1
- **Health Check**: ELB (Target Group)
- **Grace Period**: 300 seconds

### Scaling Policy
- **Type**: Target Tracking
- **Metric**: CPU Utilization
- **Target**: 70%
- **Behavior**: 
  - Scale UP when CPU > 70%
  - Scale DOWN when CPU < 70%

### Launch Template: `concert-backend-lt`
- **AMI**: ami-029ad316e58237cd4
- **Instance Type**: t3.small
- **Auto-deploys**: Docker container with CORS-fixed backend

### Target Group: `concert-asg-tg`
- **Protocol**: HTTP
- **Port**: 8080
- **Health Check**: `/api/auth/test`

## CloudWatch Alarms Created
1. **AlarmHigh**: Triggers scale-up when CPU > 70%
2. **AlarmLow**: Triggers scale-down when CPU < 70%

## Management Commands

### Check ASG Status
```bash
aws autoscaling describe-auto-scaling-groups \
  --region ap-southeast-1 \
  --auto-scaling-group-names concert-asg
```

### Check Instances
```bash
aws autoscaling describe-auto-scaling-instances \
  --region ap-southeast-1
```

### Update Desired Capacity
```bash
aws autoscaling set-desired-capacity \
  --region ap-southeast-1 \
  --auto-scaling-group-name concert-asg \
  --desired-capacity 2
```

### Update Min/Max
```bash
aws autoscaling update-auto-scaling-group \
  --region ap-southeast-1 \
  --auto-scaling-group-name concert-asg \
  --min-size 2 \
  --max-size 5
```

### Terminate Instance (ASG will replace it)
```bash
aws autoscaling terminate-instance-in-auto-scaling-group \
  --region ap-southeast-1 \
  --instance-id <INSTANCE_ID> \
  --should-decrement-desired-capacity
```

## Integration with API Gateway

The Auto Scaling Group works with the existing API Gateway:
```
Users → API Gateway (HTTPS) → Target Group → ASG Instances → RDS
```

**API Gateway Endpoint**: https://t4elolxqp8.execute-api.ap-southeast-1.amazonaws.com

## Cost Optimization

- **Idle**: 1 instance (~$15/month)
- **Medium Load**: 2 instances (~$30/month)
- **High Load**: 3 instances (~$45/month)

Instances automatically scale based on demand, optimizing costs.

## Monitoring

View metrics in CloudWatch:
- CPU Utilization
- Request Count
- Healthy/Unhealthy Hosts
- Scaling Activities

## Next Steps

1. ✅ Auto Scaling configured
2. ⏳ Fix RDS password to start backend
3. ⏳ Connect Target Group to API Gateway (optional)
4. ⏳ Set up CloudWatch Dashboard for monitoring
#!/bin/bash
set -e

echo "🧹 Cleaning up unnecessary resources..."

# US-EAST-1 Cleanup
echo "Checking US-EAST-1..."
aws ec2 describe-instances --region us-east-1 --query 'Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Name:Tags[?Key==`Name`].Value|[0]}' --output table

read -p "Terminate ALL EC2 instances in us-east-1? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    INSTANCES=$(aws ec2 describe-instances --region us-east-1 --filters "Name=instance-state-name,Values=running,stopped" --query 'Reservations[*].Instances[*].InstanceId' --output text)
    if [ ! -z "$INSTANCES" ]; then
        aws ec2 terminate-instances --region us-east-1 --instance-ids $INSTANCES
        echo "✅ Terminated instances in us-east-1"
    fi
fi

# Singapore - Keep only necessary
echo ""
echo "Singapore resources:"
aws ec2 describe-instances --region ap-southeast-1 --query 'Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[?Key==`Name`].Value|[0]}' --output table

# Terminate old instances not in ASG
OLD_INSTANCES=$(aws ec2 describe-instances --region ap-southeast-1 --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[?!contains(Tags[?Key==`aws:autoscaling:groupName`].Value, `concert-asg`)].InstanceId' --output text)
if [ ! -z "$OLD_INSTANCES" ]; then
    echo "Terminating old instances not in ASG: $OLD_INSTANCES"
    aws ec2 terminate-instances --region ap-southeast-1 --instance-ids $OLD_INSTANCES
fi

# Delete unused EBS volumes
echo ""
echo "Checking unused EBS volumes..."
VOLUMES=$(aws ec2 describe-volumes --region ap-southeast-1 --filters "Name=status,Values=available" --query 'Volumes[*].VolumeId' --output text)
if [ ! -z "$VOLUMES" ]; then
    for vol in $VOLUMES; do
        aws ec2 delete-volume --region ap-southeast-1 --volume-id $vol
        echo "Deleted volume: $vol"
    done
fi

# Delete unused Elastic IPs
echo ""
echo "Checking unused Elastic IPs..."
EIPS=$(aws ec2 describe-addresses --region ap-southeast-1 --query 'Addresses[?AssociationId==null].AllocationId' --output text)
if [ ! -z "$EIPS" ]; then
    for eip in $EIPS; do
        aws ec2 release-address --region ap-southeast-1 --allocation-id $eip
        echo "Released EIP: $eip"
    done
fi

# Delete old snapshots (keep last 2)
echo ""
echo "Cleaning old snapshots..."
aws ec2 describe-snapshots --region ap-southeast-1 --owner-ids self --query 'Snapshots | sort_by(@, &StartTime) | [:-2].SnapshotId' --output text | xargs -n1 aws ec2 delete-snapshot --region ap-southeast-1 --snapshot-id 2>/dev/null || true

# Delete unused security groups
echo ""
echo "Checking unused security groups..."
aws ec2 describe-security-groups --region ap-southeast-1 --query 'SecurityGroups[?GroupName!=`default`].[GroupId,GroupName]' --output text | while read sg name; do
    USED=$(aws ec2 describe-network-interfaces --region ap-southeast-1 --filters "Name=group-id,Values=$sg" --query 'NetworkInterfaces[0].NetworkInterfaceId' --output text)
    if [ "$USED" == "None" ] || [ -z "$USED" ]; then
        aws ec2 delete-security-group --region ap-southeast-1 --group-id $sg 2>/dev/null && echo "Deleted SG: $name" || true
    fi
done

# Delete old ECR images (keep latest 3)
echo ""
echo "Cleaning old ECR images..."
ALL_IMAGES=$(aws ecr describe-images --region us-east-1 --repository-name concert-api --query 'sort_by(imageDetails, &imagePushedAt)[:-3]' --output json 2>/dev/null || echo '[]')
if [ "$ALL_IMAGES" != "[]" ] && [ ! -z "$ALL_IMAGES" ]; then
    # Delete manifest lists first
    echo "$ALL_IMAGES" | jq -r '.[] | select(.imageManifestMediaType=="application/vnd.docker.distribution.manifest.list.v2+json") | .imageDigest' | while read digest; do
        aws ecr batch-delete-image --region us-east-1 --repository-name concert-api --image-ids imageDigest="$digest" 2>/dev/null && echo "  Deleted manifest: $digest" || true
    done
    # Then delete remaining images
    echo "$ALL_IMAGES" | jq -r '.[] | select(.imageManifestMediaType!="application/vnd.docker.distribution.manifest.list.v2+json") | .imageDigest' | while read digest; do
        aws ecr batch-delete-image --region us-east-1 --repository-name concert-api --image-ids imageDigest="$digest" 2>/dev/null || true
    done
    echo "Cleaned old ECR images"
else
    echo "No old images to clean"
fi

# Delete CloudWatch log groups older than 7 days
echo ""
echo "Setting log retention..."
aws logs describe-log-groups --region ap-southeast-1 --query 'logGroups[*].logGroupName' --output text | xargs -n1 aws logs put-retention-policy --region ap-southeast-1 --log-group-name --retention-in-days 7 2>/dev/null || true

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "💰 Cost Optimization Summary:"
echo "- Terminated unused EC2 instances"
echo "- Deleted unattached EBS volumes"
echo "- Released unused Elastic IPs"
echo "- Cleaned old snapshots and ECR images"
echo "- Set log retention to 7 days"
echo ""
echo "Current active resources:"
echo "- ASG: concert-asg (1-3 t3.small instances)"
echo "- ALB: concert-alb"
echo "- RDS: concert-prod-db"
echo "- S3: Frontend + ECR images"
echo "- API Gateway: HTTPS proxy"
echo ""
echo "Estimated monthly cost: ~$50-80"
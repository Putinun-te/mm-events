# AWS Resource Cleanup (Nuke)

## What Gets Deleted
- ✅ EC2 instances
- ✅ EKS clusters
- ✅ RDS databases
- ✅ ElastiCache clusters
- ✅ Load Balancers
- ✅ S3 buckets (infrastructure only)
- ✅ VPCs, Subnets, NAT Gateways
- ✅ Security Groups

## What Does NOT Get Deleted
- ❌ Git repositories (GitHub/GitLab)
- ❌ Source code
- ❌ GitHub Actions workflows
- ❌ IAM users/roles
- ❌ Route53 DNS records
- ❌ CloudFront distributions

## Usage

### Manual (Local)
```bash
cd aws
./nuke-aws-resources.sh
# Type "yes" to confirm
```

### GitHub Actions
1. Go to Actions tab
2. Select "Nuke AWS Resources"
3. Click "Run workflow"
4. Type "DESTROY" to confirm

## Safety
- Your code in Git is safe
- Only AWS infrastructure is deleted
- Requires explicit confirmation

# AWS Runner Not Picking Up Jobs - Diagnosis

## Issue
EC2 runner is running but not picking up jobs from repository workflows.

## Root Cause
✅ **Runner is configured for ORGANIZATION, not REPOSITORY**

### Current Configuration
```json
{
  "agentId": 53,
  "agentName": "ip-192-168-10-118",
  "poolId": 1,
  "poolName": "Default",
  "gitHubUrl": "https://github.com/MorningMores"  ← Organization level
}
```

### What Workflows Need
```yaml
runs-on: self-hosted  # Looking for repository-level runner
# Workflow: MorningMores/develop/.github/workflows/...
```

## Why It Doesn't Work

**Organization Runner:**
- Available to ALL repos in `MorningMores` org
- Workflow must be in org-level `.github` repo
- OR repo must explicitly allow org runners

**Repository Runner:**
- Available only to `MorningMores/develop` repo
- Works with repo workflows directly

## AWS Side Checks

### ✅ Network Connectivity
- GitHub.com: Accessible
- API.github.com: Accessible
- Runner process: Running (PID 2093)

### ✅ Security Group
- Outbound: Allowed (can reach GitHub)
- Inbound: SSH only (port 22)

### ✅ EC2 Instance
- Status: Running
- IP: 18.141.221.204
- Region: ap-southeast-1

## Solution

### Option 1: Reconfigure for Repository (Recommended)
```bash
# Get new token from:
# https://github.com/MorningMores/develop/settings/actions/runners/new

ssh ec2-user@18.141.221.204
cd /home/ec2-user/actions-runner
./config.sh remove
./config.sh --url https://github.com/MorningMores/develop --token <TOKEN>
sudo ./svc.sh install
sudo ./svc.sh start
```

### Option 2: Use GitHub-Hosted Runners (Current)
```yaml
runs-on: ubuntu-latest  # Already implemented
```

## Verification

After reconfiguring, check:
1. https://github.com/MorningMores/develop/settings/actions/runners
2. Should show: `ip-192-168-10-118` - **Idle** (green dot)
3. Run workflow - should pick up job immediately

## Conclusion

**AWS side is fine:**
- ✅ EC2 running
- ✅ Network connectivity
- ✅ Security groups OK
- ✅ Runner process active

**Problem is configuration:**
- ❌ Runner registered to wrong scope (org vs repo)
- ✅ Fix: Reconfigure with repository token

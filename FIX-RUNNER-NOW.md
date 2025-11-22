# Fix EC2 Runner - Step by Step

## Step 1: Get New Token

Go to this URL:
```
https://github.com/MorningMores/develop/settings/actions/runners/new
```

You'll see a token like:
```
AAAA...BBBB (long string starting with A)
```

**Copy this token immediately** (expires in 1 hour)

---

## Step 2: SSH to EC2

```bash
ssh -i your-key.pem ec2-user@18.141.221.204
```

Or use AWS Systems Manager Session Manager:
```bash
aws ssm start-session --target i-00b60427a419804ef
```

---

## Step 3: Reconfigure Runner

```bash
cd /home/ec2-user/actions-runner

# Remove old configuration
./config.sh remove

# Add new configuration (replace YOUR_TOKEN with actual token)
./config.sh --url https://github.com/MorningMores/develop --token YOUR_TOKEN

# Install as service
sudo ./svc.sh install

# Start service
sudo ./svc.sh start

# Check status
sudo ./svc.sh status
```

---

## Step 4: Verify

Go to:
```
https://github.com/MorningMores/develop/settings/actions/runners
```

You should see:
```
✅ ip-192-168-10-118 - Idle (green dot)
```

---

## Quick Fix Script

```bash
#!/bin/bash
# Run this on EC2 after getting token

TOKEN="YOUR_TOKEN_HERE"  # Replace with actual token

cd /home/ec2-user/actions-runner
./config.sh remove
./config.sh --url https://github.com/MorningMores/develop --token $TOKEN --unattended
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

---

## Alternative: Use GitHub-Hosted Runners

All workflows already switched to `ubuntu-latest` so they work now without fixing EC2 runner.

---

## Why Previous Token Failed

The token provided was:
- ❌ Wrong type (PAT token, not runner token)
- ❌ Or expired
- ❌ Or invalid

Runner tokens:
- Start with `AAAA...`
- Expire in 1 hour
- Must be generated from runners page

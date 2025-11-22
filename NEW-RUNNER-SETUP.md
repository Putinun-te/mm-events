# New Runner EC2 Setup

## ✅ New Instance Created

**Instance Details:**
- Instance ID: `i-07d0a0f2c11c81e5d`
- IP: `18.138.225.142`
- OS: Amazon Linux 2023 ARM64
- Type: t4g.micro
- GLIBC: 2.34+ (compatible with runner)

## Setup Runner

### 1. Get New Token
https://github.com/MorningMores/develop/settings/actions/runners/new

### 2. SSH to Instance
```bash
ssh -i concert-singapore.pem ec2-user@18.138.225.142
```

### 3. Install Runner
```bash
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-arm64-2.329.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.329.0/actions-runner-linux-arm64-2.329.0.tar.gz
tar xzf ./actions-runner-linux-arm64-2.329.0.tar.gz
./config.sh --url https://github.com/MorningMores/develop --token YOUR_TOKEN
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

### 4. Verify
https://github.com/MorningMores/develop/settings/actions/runners

Should show runner online ✅

### 5. Cleanup Old Instance
```bash
aws ec2 terminate-instances --instance-ids i-00b60427a419804ef
```

## Old vs New

| Feature | Old (AL2) | New (AL2023) |
|---------|-----------|--------------|
| Instance | i-00b60427a419804ef | i-07d0a0f2c11c81e5d |
| IP | 18.141.221.204 | 18.138.225.142 |
| GLIBC | 2.26 ❌ | 2.34+ ✅ |
| Runner Service | Failed | Works ✅ |

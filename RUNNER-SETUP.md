# GitHub Runner Setup

## Get New Token
1. Go to: https://github.com/MorningMores/develop/settings/actions/runners/new
2. Copy the token (starts with `AAAA...`)
3. Use within 1 hour (tokens expire)

## Configure Runner on EC2

### SSH Method
```bash
ssh -i your-key.pem ec2-user@18.141.221.204

cd /home/ec2-user/actions-runner

# Remove old config
./config.sh remove

# Add new config
./config.sh --url https://github.com/MorningMores/develop --token YOUR_TOKEN_HERE

# Run as service
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

### SSM Method
```bash
aws ssm start-session --target i-00b60427a419804ef

cd /home/ec2-user/actions-runner
./config.sh remove
./config.sh --url https://github.com/MorningMores/develop --token YOUR_TOKEN
nohup ./run.sh &
```

## Verify
Check: https://github.com/MorningMores/develop/settings/actions/runners

Should show: `ip-192-168-10-118` - **Idle** (green)

# Runner Status Check

## EC2 Instance
- ID: `i-07d0a0f2c11c81e5d`
- IP: `18.138.225.142`
- Status: ✅ Running

## Check Runner Status

### Via GitHub
https://github.com/MorningMores/develop/settings/actions/runners

Should show: `ip-192-168-25-159` - **Idle** (green)

### Via SSH
```bash
ssh -i concert-singapore.pem ec2-user@18.138.225.142

# Check service
sudo systemctl status actions.runner.MorningMores-develop.ip-192-168-25-159.service

# Check process
ps aux | grep Runner.Listener

# View logs
sudo journalctl -u actions.runner.MorningMores-develop.ip-192-168-25-159.service -f
```

### Restart Runner
```bash
sudo systemctl restart actions.runner.MorningMores-develop.ip-192-168-25-159.service
```

## If Runner Not Showing

Get new token:
```bash
curl -X POST -H "Authorization: token YOUR_PAT" \
  https://api.github.com/repos/MorningMores/develop/actions/runners/registration-token
```

Reconfigure:
```bash
cd /home/ec2-user/actions-runner
sudo -u ec2-user ./config.sh remove --token TOKEN
sudo -u ec2-user ./config.sh --url https://github.com/MorningMores/develop --token TOKEN --unattended
sudo systemctl restart actions.runner.MorningMores-develop.ip-192-168-25-159.service
```

## Current Issue

Runner may have stopped. Check GitHub settings page to confirm status.

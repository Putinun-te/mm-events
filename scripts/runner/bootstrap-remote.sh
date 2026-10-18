#!/bin/bash
# Run install-runner-host.sh on an existing EC2 instance, over SSH or AWS SSM.
#
# Replaces setup-runner-on-ec2.sh (SSH), setup-runner-ssm.sh and
# configure-runner-ssm.sh (SSM).
#
# Usage:
#   scripts/runner/bootstrap-remote.sh ssh <public-ip> <key.pem>
#   scripts/runner/bootstrap-remote.sh ssm <instance-id>
#
# REPO_URL, RUNNER_TOKEN and RUNNER_LABELS are forwarded so the runner can be
# registered in the same step.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL="$SCRIPT_DIR/install-runner-host.sh"
ENV_PREFIX="REPO_URL='${REPO_URL:-}' RUNNER_TOKEN='${RUNNER_TOKEN:-}' RUNNER_LABELS='${RUNNER_LABELS:-}'"

mode="${1:-}"
case "$mode" in
  ssh)
    host="${2:?usage: $0 ssh <public-ip> <key.pem>}"
    key="${3:?usage: $0 ssh <public-ip> <key.pem>}"
    scp -i "$key" "$INSTALL" "ec2-user@$host:~/install-runner-host.sh"
    ssh -i "$key" "ec2-user@$host" "chmod +x ~/install-runner-host.sh && $ENV_PREFIX ~/install-runner-host.sh"
    ;;
  ssm)
    instance="${2:?usage: $0 ssm <instance-id>}"
    script_b64="$(base64 < "$INSTALL" | tr -d '\n')"
    command_id=$(aws ssm send-command \
      --instance-ids "$instance" \
      --document-name "AWS-RunShellScript" \
      --parameters "commands=[\"echo $script_b64 | base64 -d > /tmp/install-runner-host.sh\",\"$ENV_PREFIX bash /tmp/install-runner-host.sh\"]" \
      --query 'Command.CommandId' --output text)
    echo "Sent SSM command $command_id. Check it with:"
    echo "  aws ssm get-command-invocation --command-id $command_id --instance-id $instance"
    ;;
  *)
    echo "usage: $0 ssh <public-ip> <key.pem> | ssm <instance-id>" >&2
    exit 1
    ;;
esac

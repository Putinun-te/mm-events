#!/bin/bash
# Launch a dedicated EC2 instance for a self-hosted GitHub Actions runner
# (kept separate from the EKS worker nodes) and install the runner via user data.
#
# Required environment variables:
#   SUBNET_ID          subnet to launch into
#   SECURITY_GROUP_ID  security group for the runner (SSH/SSM only, no inbound app ports)
#   KEY_NAME           EC2 key pair name
# Optional:
#   AWS_REGION         default: ap-southeast-1
#   INSTANCE_TYPE      default: t4g.medium (ARM64)
#   AMI_ID             default: latest Amazon Linux 2023 for the instance architecture
#   REPO_URL, RUNNER_TOKEN, RUNNER_LABELS  passed through to install-runner-host.sh
set -euo pipefail

: "${SUBNET_ID:?set SUBNET_ID}"
: "${SECURITY_GROUP_ID:?set SECURITY_GROUP_ID}"
: "${KEY_NAME:?set KEY_NAME}"
export AWS_REGION="${AWS_REGION:-ap-southeast-1}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t4g.medium}"

if [ -z "${AMI_ID:-}" ]; then
  case "$INSTANCE_TYPE" in
    *g.*|*gd.*|*gn.*) AMI_ARCH="arm64" ;;
    *) AMI_ARCH="x86_64" ;;
  esac
  AMI_ID=$(aws ssm get-parameter \
    --name "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-${AMI_ARCH}" \
    --query 'Parameter.Value' --output text)
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_DATA="$(mktemp)"
trap 'rm -f "$USER_DATA"' EXIT
{
  echo "#!/bin/bash"
  echo "export REPO_URL='${REPO_URL:-}' RUNNER_TOKEN='${RUNNER_TOKEN:-}' RUNNER_LABELS='${RUNNER_LABELS:-}'"
  tail -n +2 "$SCRIPT_DIR/install-runner-host.sh"
} > "$USER_DATA"

echo "Launching $INSTANCE_TYPE ($AMI_ID) in $SUBNET_ID..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --subnet-id "$SUBNET_ID" \
  --user-data "file://$USER_DATA" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=github-runner},{Key=Purpose,Value=CI-Runner}]' \
  --query 'Instances[0].InstanceId' --output text)

echo "Created $INSTANCE_ID, waiting for it to run..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "Instance $INSTANCE_ID is running (public IP: $PUBLIC_IP)."
echo "User data installs the runner; follow progress with:"
echo "  ssh -i <key>.pem ec2-user@$PUBLIC_IP 'sudo tail -f /var/log/cloud-init-output.log'"

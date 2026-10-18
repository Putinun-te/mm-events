#!/bin/bash
# Install a self-hosted GitHub Actions runner on an Amazon Linux EC2 host.
#
# Replaces the old runner-setup.sh, runner-setup-commands.sh, setup-ec2-runner.sh,
# setup-runner.sh (user data) and the copies embedded in setup-runner-on-ec2.sh /
# setup-runner-ssm.sh. Works as EC2 user data (runs as root) or interactively.
#
# Optional environment variables:
#   REPO_URL       e.g. https://github.com/<owner>/<repo>   (configure runner if set)
#   RUNNER_TOKEN   registration token from Settings > Actions > Runners > New runner
#   RUNNER_LABELS  default: self-hosted,linux,ec2,<arch>
#   RUNNER_USER    default: ec2-user
#   RUNNER_VERSION default: 2.311.0
set -euo pipefail

RUNNER_USER="${RUNNER_USER:-ec2-user}"
RUNNER_VERSION="${RUNNER_VERSION:-2.311.0}"
MAVEN_VERSION="3.9.5"

case "$(uname -m)" in
  aarch64|arm64) ARCH="arm64"; LABEL_ARCH="ARM64" ;;
  x86_64)        ARCH="x64";   LABEL_ARCH="X64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,ec2,${LABEL_ARCH}}"

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

# System packages, Java 21, Node.js 20, Docker
$SUDO yum update -y
$SUDO yum install -y git curl wget tar docker java-21-amazon-corretto-devel
curl -fsSL https://rpm.nodesource.com/setup_20.x | $SUDO bash -
$SUDO yum install -y nodejs

# Maven
if [ ! -d /opt/maven ]; then
  cd /opt
  $SUDO wget -q "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
  $SUDO tar xzf "apache-maven-${MAVEN_VERSION}-bin.tar.gz"
  $SUDO ln -sfn "apache-maven-${MAVEN_VERSION}" maven
fi
RUNNER_HOME="$(getent passwd "$RUNNER_USER" | cut -d: -f6)"
grep -q 'JAVA_HOME=' "$RUNNER_HOME/.bashrc" 2>/dev/null || $SUDO tee -a "$RUNNER_HOME/.bashrc" >/dev/null <<'EOF'
export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
export PATH=/opt/maven/bin:$PATH
EOF

$SUDO systemctl enable --now docker
$SUDO usermod -a -G docker "$RUNNER_USER"

# GitHub Actions runner
RUNNER_DIR="$RUNNER_HOME/actions-runner"
$SUDO mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"
TARBALL="actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz"
[ -f "$TARBALL" ] || $SUDO curl -fsSL -o "$TARBALL" \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${TARBALL}"
$SUDO tar xzf "$TARBALL"
$SUDO chown -R "$RUNNER_USER:$RUNNER_USER" "$RUNNER_DIR"

if [ -n "${REPO_URL:-}" ] && [ -n "${RUNNER_TOKEN:-}" ]; then
  sudo -u "$RUNNER_USER" ./config.sh --url "$REPO_URL" --token "$RUNNER_TOKEN" \
    --labels "$RUNNER_LABELS" --unattended
  $SUDO ./svc.sh install "$RUNNER_USER"
  $SUDO ./svc.sh start
  echo "Runner configured and started as a service."
else
  echo "Runner installed in $RUNNER_DIR. To register it:"
  echo "  cd $RUNNER_DIR && ./config.sh --url https://github.com/<owner>/<repo> --token <token> --labels $RUNNER_LABELS"
  echo "  sudo ./svc.sh install $RUNNER_USER && sudo ./svc.sh start"
fi

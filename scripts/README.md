# Scripts

Helper scripts for the optional self-hosted runner setup used during the course.
The CI workflows in `.github/workflows/` run on GitHub-hosted runners and do not
need any of these.

| Script | What it does |
|---|---|
| `runner/install-runner-host.sh` | Installs Docker, Java 21, Maven, Node.js 20 and the GitHub Actions runner on an Amazon Linux host. Registers the runner when `REPO_URL` and `RUNNER_TOKEN` are set. Also usable as EC2 user data. |
| `runner/create-runner-ec2.sh` | Launches a dedicated EC2 instance (default `t4g.medium`, Amazon Linux 2023) and installs the runner through user data. Needs `SUBNET_ID`, `SECURITY_GROUP_ID`, `KEY_NAME`. |
| `runner/bootstrap-remote.sh` | Runs the install script on an existing instance over `ssh` or `ssm`. |
| `runner/check-arc-runners.sh` | Shows the status of Actions Runner Controller runners in the EKS cluster (`k8s/github-runner.yaml`). |
| `aws/audit-ec2-security.sh` | Read-only listing of EC2 instances, EKS node groups, security groups and runner-related IAM roles. |

All scripts read settings from environment variables; none of them contain
credentials. Runner registration tokens come from
**Settings → Actions → Runners → New self-hosted runner** in your repository.

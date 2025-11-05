#!/usr/bin/env bash

set -euo pipefail

ACTION=${1:-}
STATE_FILE=${STATE_FILE:-iam-group-memberships.txt}
PROJECT_NAME=${PROJECT_NAME:-concert}
ENVIRONMENT=${ENVIRONMENT:-}
GROUP_PREFIX=${GROUP_PREFIX:-${PROJECT_NAME}${ENVIRONMENT:+-$ENVIRONMENT}}
GROUP_PATH=${GROUP_PATH:-/teams/}
AWS_REGION=${AWS_REGION:-us-east-1}

GROUP_SUFFIXES=(developers testers deployment admins)

usage() {
  cat <<EOF
Usage: $0 <detach|provision|restore> [extra args]

  detach     Remove all users from the managed IAM groups (records membership in ${STATE_FILE}).
  provision  Ensure groups exist, attach baseline policies, and optionally restore memberships.
  restore    Re-add users to groups using ${STATE_FILE} (created by detach).

Environment overrides:
  PROJECT_NAME (default: concert)
  ENVIRONMENT  (default: empty)
  GROUP_PREFIX (defaults to PROJECT_NAME[-ENVIRONMENT])
  STATE_FILE   (default: iam-group-memberships.txt)
  AWS_REGION   (default: us-east-1)
EOF
}

require_aws_cli() {
  if ! command -v aws >/dev/null 2>&1; then
    echo "aws CLI is required" >&2
    exit 1
  fi
}

full_group_name() {
  local suffix=$1
  echo "${GROUP_PREFIX}-${suffix}"
}

list_group_users() {
  local group=$1
  aws iam get-group --group-name "$group" --query 'Users[].UserName' --output text 2>/dev/null || true
}

detach_group_members() {
  local group=$1
  local users=$2
  for user in $users; do
    echo "Detaching $user from $group"
    aws iam remove-user-from-group --group-name "$group" --user-name "$user" >/dev/null
  done
}

detach_groups() {
  : >"$STATE_FILE"
  for suffix in "${GROUP_SUFFIXES[@]}"; do
    local group
    group=$(full_group_name "$suffix")
    if ! aws iam get-group --group-name "$group" --query 'Group.GroupName' --output text >/dev/null 2>&1; then
      echo "Group $group does not exist, skipping"
      continue
    fi
    local users
    users=$(list_group_users "$group")
    if [[ -z "$users" ]]; then
      echo "Group $group already empty"
      continue
    fi
    printf '%s %s\n' "$group" "$users" >>"$STATE_FILE"
    detach_group_members "$group" "$users"
  done
  echo "Saved previous memberships to $STATE_FILE"
}

ensure_group() {
  local group=$1
  if aws iam get-group --group-name "$group" --query 'Group.GroupName' --output text >/dev/null 2>&1; then
    return
  fi
  echo "Creating group $group"
  aws iam create-group --group-name "$group" --path "$GROUP_PATH" >/dev/null
}

attach_managed_policy() {
  local group=$1
  local policy_arn=$2
  local attached
  attached=$(aws iam list-attached-group-policies --group-name "$group" --query "AttachedPolicies[?PolicyArn=='$policy_arn'].PolicyArn" --output text)
  if [[ "$attached" == "$policy_arn" ]]; then
    return
  fi
  echo "Attaching $policy_arn to $group"
  aws iam attach-group-policy --group-name "$group" --policy-arn "$policy_arn" >/dev/null
}

configure_deployment_inline_policies() {
  local group=$1
  local passrole_policy
  passrole_policy=$(cat <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PassRoleToCoreServices",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole",
        "iam:GetRole",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": [
            "ec2.amazonaws.com",
            "ecs-tasks.amazonaws.com",
            "lambda.amazonaws.com",
            "rds.amazonaws.com"
          ]
        }
      }
    },
    {
      "Sid": "ManageServiceLinkedRoles",
      "Effect": "Allow",
      "Action": [
        "iam:CreateServiceLinkedRole",
        "iam:DeleteServiceLinkedRole",
        "iam:GetServiceLinkedRoleDeletionStatus"
      ],
      "Resource": "arn:aws:iam::*:role/aws-service-role/*"
    }
  ]
}
EOF
)
  aws iam put-group-policy --group-name "$group" --policy-name "${GROUP_PREFIX}-deployment-passrole" --policy-document "$passrole_policy" >/dev/null

  local self_service_policy
  self_service_policy=$(cat <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ViewAccountInfo",
      "Effect": "Allow",
      "Action": [
        "iam:GetAccountPasswordPolicy",
        "iam:GetAccountSummary",
        "iam:ListVirtualMFADevices"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ManageOwnPassword",
      "Effect": "Allow",
      "Action": [
        "iam:ChangePassword",
        "iam:GetUser"
      ],
      "Resource": "arn:aws:iam::*:user/${aws:username}"
    },
    {
      "Sid": "ManageOwnKeys",
      "Effect": "Allow",
      "Action": [
        "iam:CreateAccessKey",
        "iam:DeleteAccessKey",
        "iam:ListAccessKeys",
        "iam:UpdateAccessKey"
      ],
      "Resource": "arn:aws:iam::*:user/${aws:username}"
    },
    {
      "Sid": "ManageOwnMFA",
      "Effect": "Allow",
      "Action": [
        "iam:CreateVirtualMFADevice",
        "iam:DeleteVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:ResyncMFADevice",
        "iam:DeactivateMFADevice"
      ],
      "Resource": [
        "arn:aws:iam::*:mfa/${aws:username}",
        "arn:aws:iam::*:user/${aws:username}"
      ]
    }
  ]
}
EOF
)
  aws iam put-group-policy --group-name "$group" --policy-name "${GROUP_PREFIX}-deployment-self-service" --policy-document "$self_service_policy" >/dev/null
}

provision_groups() {
  for suffix in "${GROUP_SUFFIXES[@]}"; do
    local group
    group=$(full_group_name "$suffix")
    ensure_group "$group"
    case "$suffix" in
      developers)
        attach_managed_policy "$group" "arn:aws:iam::aws:policy/PowerUserAccess"
        ;;
      testers)
        attach_managed_policy "$group" "arn:aws:iam::aws:policy/ReadOnlyAccess"
        ;;
      deployment)
        attach_managed_policy "$group" "arn:aws:iam::aws:policy/PowerUserAccess"
        configure_deployment_inline_policies "$group"
        ;;
      admins)
        attach_managed_policy "$group" "arn:aws:iam::aws:policy/AdministratorAccess"
        ;;
    esac
  done
}

restore_memberships() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "State file $STATE_FILE not found" >&2
    exit 1
  fi
  while read -r line; do
    [[ -z "$line" ]] && continue
    local group users
    group=$(echo "$line" | awk '{print $1}')
    users=$(echo "$line" | cut -d' ' -f2-)
    if [[ -z "$users" ]]; then
      continue
    fi
    if ! aws iam get-group --group-name "$group" --query 'Group.GroupName' --output text >/dev/null 2>&1; then
      echo "Group $group missing, skipping memberships"
      continue
    fi
    for user in $users; do
      echo "Adding $user to $group"
      aws iam add-user-to-group --group-name "$group" --user-name "$user" >/dev/null
    done
  done <"$STATE_FILE"
}

main() {
  require_aws_cli
  export AWS_REGION
  export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-$AWS_REGION}
  case "$ACTION" in
    detach)
      detach_groups
      ;;
    provision)
      provision_groups
      if [[ -f "$STATE_FILE" ]]; then
        echo "Restoring memberships from $STATE_FILE"
        restore_memberships
      fi
      ;;
    restore)
      restore_memberships
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main

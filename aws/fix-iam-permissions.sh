#!/bin/bash
###############################################################################
# Fix IAM Group Permissions
# Updates permissions for concert IAM groups
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

###############################################################################
# 1. concert-deployment Group
###############################################################################
fix_deployment_group() {
    print_header "Fixing concert-deployment Group Permissions"
    
    GROUP_NAME="concert-deployment"
    
    # Check if group exists
    if ! aws iam get-group --group-name $GROUP_NAME &>/dev/null; then
        print_info "Group $GROUP_NAME doesn't exist, creating..."
        aws iam create-group --group-name $GROUP_NAME
    fi
    
    # Remove old inline policies
    print_info "Removing old inline policies..."
    OLD_POLICIES=$(aws iam list-group-policies --group-name $GROUP_NAME --query 'PolicyNames[]' --output text 2>/dev/null || echo "")
    for policy in $OLD_POLICIES; do
        aws iam delete-group-policy --group-name $GROUP_NAME --policy-name $policy
        echo "  Deleted: $policy"
    done
    
    # Attach AWS managed policies
    print_info "Attaching managed policies..."
    
    # EC2 Full Access
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess 2>/dev/null && \
        echo "  ✓ AmazonEC2FullAccess" || echo "  Already attached: AmazonEC2FullAccess"
    
    # S3 Full Access
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null && \
        echo "  ✓ AmazonS3FullAccess" || echo "  Already attached: AmazonS3FullAccess"
    
    # RDS Full Access
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonRDSFullAccess 2>/dev/null && \
        echo "  ✓ AmazonRDSFullAccess" || echo "  Already attached: AmazonRDSFullAccess"
    
    # Lambda Full Access
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess 2>/dev/null && \
        echo "  ✓ AWSLambda_FullAccess" || echo "  Already attached: AWSLambda_FullAccess"
    
    # CloudWatch Full Access
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess 2>/dev/null && \
        echo "  ✓ CloudWatchFullAccess" || echo "  Already attached: CloudWatchFullAccess"
    
    # IAM Limited Access (for PassRole)
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/IAMReadOnlyAccess 2>/dev/null && \
        echo "  ✓ IAMReadOnlyAccess" || echo "  Already attached: IAMReadOnlyAccess"
    
    print_success "concert-deployment group updated!"
    echo ""
}

###############################################################################
# 2. concert-testers Group
###############################################################################
fix_testers_group() {
    print_header "Fixing concert-testers Group Permissions"
    
    GROUP_NAME="concert-testers"
    
    # Check if group exists
    if ! aws iam get-group --group-name $GROUP_NAME &>/dev/null; then
        print_info "Group $GROUP_NAME doesn't exist, creating..."
        aws iam create-group --group-name $GROUP_NAME
    fi
    
    # Remove old inline policies
    print_info "Removing old inline policies..."
    OLD_POLICIES=$(aws iam list-group-policies --group-name $GROUP_NAME --query 'PolicyNames[]' --output text 2>/dev/null || echo "")
    for policy in $OLD_POLICIES; do
        aws iam delete-group-policy --group-name $GROUP_NAME --policy-name $policy
        echo "  Deleted: $policy"
    done
    
    # Attach managed policies
    print_info "Attaching managed policies..."
    
    # S3 Read Only
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess 2>/dev/null && \
        echo "  ✓ AmazonS3ReadOnlyAccess" || echo "  Already attached: AmazonS3ReadOnlyAccess"
    
    # EC2 Read Only
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess 2>/dev/null && \
        echo "  ✓ AmazonEC2ReadOnlyAccess" || echo "  Already attached: AmazonEC2ReadOnlyAccess"
    
    # CloudWatch Read Only
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess 2>/dev/null && \
        echo "  ✓ CloudWatchReadOnlyAccess" || echo "  Already attached: CloudWatchReadOnlyAccess"
    
    print_success "concert-testers group updated!"
    echo ""
}

###############################################################################
# 3. concert-developers Group
###############################################################################
fix_developers_group() {
    print_header "Fixing concert-developers Group Permissions"
    
    GROUP_NAME="concert-developers"
    
    # Check if group exists
    if ! aws iam get-group --group-name $GROUP_NAME &>/dev/null; then
        print_info "Group $GROUP_NAME doesn't exist, creating..."
        aws iam create-group --group-name $GROUP_NAME
    fi
    
    # Remove old inline policies
    print_info "Removing old inline policies..."
    OLD_POLICIES=$(aws iam list-group-policies --group-name $GROUP_NAME --query 'PolicyNames[]' --output text 2>/dev/null || echo "")
    for policy in $OLD_POLICIES; do
        aws iam delete-group-policy --group-name $GROUP_NAME --policy-name $policy
        echo "  Deleted: $policy"
    done
    
    # Attach managed policies
    print_info "Attaching managed policies..."
    
    # S3 Full Access
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null && \
        echo "  ✓ AmazonS3FullAccess" || echo "  Already attached: AmazonS3FullAccess"
    
    # Lambda Full Access
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess 2>/dev/null && \
        echo "  ✓ AWSLambda_FullAccess" || echo "  Already attached: AWSLambda_FullAccess"
    
    # API Gateway Full Access
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator 2>/dev/null && \
        echo "  ✓ AmazonAPIGatewayAdministrator" || echo "  Already attached: AmazonAPIGatewayAdministrator"
    
    # CloudWatch Full Access
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess 2>/dev/null && \
        echo "  ✓ CloudWatchFullAccess" || echo "  Already attached: CloudWatchFullAccess"
    
    # EC2 Read Only (for viewing instances)
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess 2>/dev/null && \
        echo "  ✓ AmazonEC2ReadOnlyAccess" || echo "  Already attached: AmazonEC2ReadOnlyAccess"
    
    print_success "concert-developers group updated!"
    echo ""
}

###############################################################################
# 4. concert-admins Group
###############################################################################
fix_admins_group() {
    print_header "Fixing concert-admins Group Permissions"
    
    GROUP_NAME="concert-admins"
    
    # Check if group exists
    if ! aws iam get-group --group-name $GROUP_NAME &>/dev/null; then
        print_info "Group $GROUP_NAME doesn't exist, creating..."
        aws iam create-group --group-name $GROUP_NAME
    fi
    
    # Attach AdministratorAccess (full access)
    print_info "Attaching AdministratorAccess..."
    aws iam attach-group-policy \
        --group-name $GROUP_NAME \
        --policy-arn arn:aws:iam::aws:policy/AdministratorAccess 2>/dev/null && \
        echo "  ✓ AdministratorAccess" || echo "  Already attached: AdministratorAccess"
    
    print_success "concert-admins group updated!"
    echo ""
}

###############################################################################
# 5. Show Group Summary
###############################################################################
show_group_summary() {
    print_header "IAM Groups Summary"
    
    for group in concert-deployment concert-testers concert-developers concert-admins; do
        echo -e "${BLUE}Group: $group${NC}"
        
        # Count users
        USER_COUNT=$(aws iam get-group --group-name $group --query 'Users | length(@)' --output text 2>/dev/null || echo "0")
        echo "  Users: $USER_COUNT"
        
        # List attached managed policies
        echo "  Managed Policies:"
        aws iam list-attached-group-policies --group-name $group --query 'AttachedPolicies[].PolicyName' --output text 2>/dev/null | tr '\t' '\n' | sed 's/^/    - /' || echo "    None"
        
        # List inline policies
        INLINE_COUNT=$(aws iam list-group-policies --group-name $group --query 'PolicyNames | length(@)' --output text 2>/dev/null || echo "0")
        echo "  Inline Policies: $INLINE_COUNT"
        
        echo ""
    done
}

###############################################################################
# Main
###############################################################################
main() {
    clear
    
    print_header "Concert Platform - IAM Group Permission Fix"
    echo ""
    
    echo -e "${YELLOW}This script will:${NC}"
    echo "  1. Remove problematic inline policies from all groups"
    echo "  2. Attach AWS managed policies instead"
    echo "  3. Fix 'Not defined' permission warnings"
    echo ""
    
    read -p "Continue? [y/N]: " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cancelled"
        exit 0
    fi
    
    fix_deployment_group
    fix_testers_group
    fix_developers_group
    fix_admins_group
    show_group_summary
    
    print_header "✓ All IAM Groups Updated Successfully!"
    echo ""
    echo -e "${GREEN}All groups now have defined permissions using AWS managed policies.${NC}"
    echo -e "${GREEN}This is more secure and easier to maintain than inline policies.${NC}"
    echo ""
}

main

#!/bin/bash

################################################################################
# IAM User Management Script - AWS CLI
# Purpose: Add users to groups, manage memberships, and verify access
# Date: October 31, 2025
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Show menu
show_menu() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  IAM USER MANAGEMENT - AWS CLI                                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "1. Add user to group"
    echo "2. Remove user from group"
    echo "3. List all groups"
    echo "4. List users in a group"
    echo "5. List groups for a user"
    echo "6. List all IAM users"
    echo "7. Test user AWS access"
    echo "8. Verify group policies"
    echo "9. Exit"
    echo ""
}

# Add user to group
add_user_to_group() {
    echo ""
    read -p "Enter username: " username
    
    echo ""
    echo "Available groups:"
    echo "1. concert-developers"
    echo "2. concert-testers"
    echo "3. concert-deployment"
    echo "4. concert-admins"
    echo ""
    read -p "Select group (1-4): " group_choice
    
    case $group_choice in
        1) group="concert-developers" ;;
        2) group="concert-testers" ;;
        3) group="concert-deployment" ;;
        4) group="concert-admins" ;;
        *) log_error "Invalid choice"; return ;;
    esac
    
    log_info "Adding $username to $group..."
    
    if aws iam add-user-to-group --group-name "$group" --user-name "$username" 2>/dev/null; then
        log_success "$username added to $group"
    else
        log_error "Failed to add user (user may not exist or already in group)"
    fi
}

# Remove user from group
remove_user_from_group() {
    echo ""
    read -p "Enter username: " username
    read -p "Enter group name: " group
    
    log_info "Removing $username from $group..."
    
    if aws iam remove-user-from-group --group-name "$group" --user-name "$username" 2>/dev/null; then
        log_success "$username removed from $group"
    else
        log_error "Failed to remove user"
    fi
}

# List all groups
list_all_groups() {
    log_info "All IAM groups:"
    aws iam list-groups --query 'Groups[].[GroupName,CreateDate]' --output table
}

# List users in a group
list_users_in_group() {
    echo ""
    read -p "Enter group name (e.g., concert-developers): " group
    
    log_info "Users in $group:"
    aws iam get-group --group-name "$group" --query 'Users[].[UserName,UserId,CreateDate]' --output table
}

# List groups for a user
list_groups_for_user() {
    echo ""
    read -p "Enter username: " username
    
    log_info "Groups for $username:"
    aws iam list-groups-for-user --user-name "$username" --query 'Groups[].[GroupName,CreateDate]' --output table
}

# List all IAM users
list_all_users() {
    log_info "All IAM users:"
    aws iam list-users --query 'Users[].[UserName,UserId,CreateDate]' --output table
}

# Test user access
test_user_access() {
    echo ""
    read -p "Enter AWS profile name (or press Enter to use default): " profile
    
    if [ -z "$profile" ]; then
        profile_arg=""
    else
        profile_arg="--profile $profile"
    fi
    
    echo ""
    log_info "Testing S3 access..."
    if aws s3 ls $profile_arg 2>/dev/null; then
        log_success "S3 access: ✓"
    else
        log_error "S3 access: ✗"
    fi
    
    echo ""
    log_info "Testing IAM access..."
    if aws iam list-groups $profile_arg 2>/dev/null; then
        log_success "IAM list groups: ✓"
    else
        log_error "IAM list groups: ✗ (expected for non-admin users)"
    fi
}

# Verify group policies
verify_group_policies() {
    echo ""
    echo "Available groups:"
    echo "1. concert-developers"
    echo "2. concert-testers"
    echo "3. concert-deployment"
    echo "4. concert-admins"
    echo ""
    read -p "Select group (1-4): " group_choice
    
    case $group_choice in
        1) group="concert-developers" ;;
        2) group="concert-testers" ;;
        3) group="concert-deployment" ;;
        4) group="concert-admins" ;;
        *) log_error "Invalid choice"; return ;;
    esac
    
    echo ""
    log_info "Policies attached to $group:"
    echo ""
    
    policies=$(aws iam list-group-policies --group-name "$group" --query 'PolicyNames[]' --output text)
    
    for policy in $policies; do
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Policy: $policy"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        aws iam get-group-policy --group-name "$group" --policy-name "$policy" --query 'PolicyDocument' --output json | python3 -m json.tool 2>/dev/null || echo "Unable to format policy"
        echo ""
    done
}

# Main loop
main() {
    while true; do
        show_menu
        read -p "Enter your choice (1-9): " choice
        
        case $choice in
            1) add_user_to_group ;;
            2) remove_user_from_group ;;
            3) list_all_groups ;;
            4) list_users_in_group ;;
            5) list_groups_for_user ;;
            6) list_all_users ;;
            7) test_user_access ;;
            8) verify_group_policies ;;
            9) log_success "Exiting..."; exit 0 ;;
            *) log_error "Invalid choice. Please try again." ;;
        esac
    done
}

main

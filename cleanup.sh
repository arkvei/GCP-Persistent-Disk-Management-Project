#!/bin/bash
################################################################################
# GCP Persistent Disk Cleanup Script
# 
# Description: Safely removes all resources created by the setup script
# Author: Cloud Infrastructure Project
# Date: February 2026
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration Variables
ZONE="${ZONE:-europe-west4-c}"
REGION="${REGION:-europe-west4}"
INSTANCE_NAME="${INSTANCE_NAME:-gcelab}"
DISK_NAME="${DISK_NAME:-mydisk}"

################################################################################
# Helper Functions
################################################################################

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm_deletion() {
    echo ""
    print_warning "⚠️  WARNING: This will DELETE the following resources:"
    echo "  - Instance: $INSTANCE_NAME"
    echo "  - Disk: $DISK_NAME"
    echo "  - Zone: $ZONE"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        print_info "Cleanup cancelled."
        exit 0
    fi
}

detach_disk() {
    print_info "Detaching disk from instance..."
    
    # Check if instance exists
    if ! gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" &> /dev/null; then
        print_warning "Instance '$INSTANCE_NAME' does not exist. Skipping detachment."
        return 0
    fi
    
    # Check if disk is attached
    if ! gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" \
        --format="value(disks[].source)" | grep -q "$DISK_NAME"; then
        print_warning "Disk not attached to instance. Skipping detachment."
        return 0
    fi
    
    # Detach disk
    if gcloud compute instances detach-disk "$INSTANCE_NAME" \
        --disk="$DISK_NAME" \
        --zone="$ZONE" \
        --quiet; then
        print_info "Disk detached successfully ✓"
    else
        print_error "Failed to detach disk"
        exit 1
    fi
}

delete_instance() {
    print_info "Deleting instance: $INSTANCE_NAME..."
    
    # Check if instance exists
    if ! gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" &> /dev/null; then
        print_warning "Instance '$INSTANCE_NAME' does not exist. Skipping deletion."
        return 0
    fi
    
    # Delete instance
    if gcloud compute instances delete "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --quiet; then
        print_info "Instance deleted successfully ✓"
    else
        print_error "Failed to delete instance"
        exit 1
    fi
}

delete_disk() {
    print_info "Deleting persistent disk: $DISK_NAME..."
    
    # Check if disk exists
    if ! gcloud compute disks describe "$DISK_NAME" --zone="$ZONE" &> /dev/null; then
        print_warning "Disk '$DISK_NAME' does not exist. Skipping deletion."
        return 0
    fi
    
    # Delete disk
    if gcloud compute disks delete "$DISK_NAME" \
        --zone="$ZONE" \
        --quiet; then
        print_info "Disk deleted successfully ✓"
    else
        print_error "Failed to delete disk"
        exit 1
    fi
}

print_summary() {
    print_info "===================================================================="
    print_info "Cleanup Complete!"
    print_info "===================================================================="
    print_info "All resources have been successfully removed."
    print_info ""
    print_info "Deleted:"
    print_info "  ✓ Instance: $INSTANCE_NAME"
    print_info "  ✓ Disk: $DISK_NAME"
    print_info "===================================================================="
}

################################################################################
# Main Execution
################################################################################

main() {
    echo "===================================================================="
    echo "GCP Persistent Disk Cleanup Script"
    echo "===================================================================="
    echo ""
    
    confirm_deletion
    detach_disk
    delete_instance
    delete_disk
    print_summary
}

# Run main function
main "$@"

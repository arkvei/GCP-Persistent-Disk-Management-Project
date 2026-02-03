#!/bin/bash
################################################################################
# GCP Persistent Disk Setup Script
# 
# Description: Automated setup for creating a VM instance with persistent disk
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
DISK_SIZE="${DISK_SIZE:-200GB}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-standard-2}"
DISK_TYPE="${DISK_TYPE:-pd-standard}"

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

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI not found. Please install Google Cloud SDK."
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        print_error "Not authenticated. Run 'gcloud auth login' first."
        exit 1
    fi
    
    print_info "Prerequisites check passed ✓"
}

configure_environment() {
    print_info "Configuring GCP environment..."
    
    # Set compute zone and region
    gcloud config set compute/zone "$ZONE" --quiet
    gcloud config set compute/region "$REGION" --quiet
    
    # Export environment variables
    export ZONE
    export REGION
    
    print_info "Environment configured ✓"
    print_info "Zone: $ZONE"
    print_info "Region: $REGION"
}

create_instance() {
    print_info "Creating VM instance: $INSTANCE_NAME..."
    
    # Check if instance already exists
    if gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" &> /dev/null; then
        print_warning "Instance '$INSTANCE_NAME' already exists. Skipping creation."
        return 0
    fi
    
    # Create instance
    if gcloud compute instances create "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --machine-type="$MACHINE_TYPE" \
        --quiet; then
        print_info "Instance created successfully ✓"
    else
        print_error "Failed to create instance"
        exit 1
    fi
}

create_disk() {
    print_info "Creating persistent disk: $DISK_NAME..."
    
    # Check if disk already exists
    if gcloud compute disks describe "$DISK_NAME" --zone="$ZONE" &> /dev/null; then
        print_warning "Disk '$DISK_NAME' already exists. Skipping creation."
        return 0
    fi
    
    # Create disk
    if gcloud compute disks create "$DISK_NAME" \
        --size="$DISK_SIZE" \
        --type="$DISK_TYPE" \
        --zone="$ZONE" \
        --quiet; then
        print_info "Disk created successfully ✓"
    else
        print_error "Failed to create disk"
        exit 1
    fi
}

attach_disk() {
    print_info "Attaching disk to instance..."
    
    # Check if disk is already attached
    if gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" \
        --format="value(disks[].source)" | grep -q "$DISK_NAME"; then
        print_warning "Disk already attached. Skipping."
        return 0
    fi
    
    # Attach disk
    if gcloud compute instances attach-disk "$INSTANCE_NAME" \
        --disk="$DISK_NAME" \
        --zone="$ZONE" \
        --quiet; then
        print_info "Disk attached successfully ✓"
    else
        print_error "Failed to attach disk"
        exit 1
    fi
}

configure_disk() {
    print_info "Configuring disk on the instance..."
    print_info "You will need to SSH into the instance manually to complete disk configuration."
    print_info ""
    print_info "Run the following commands inside the VM:"
    echo ""
    echo "  sudo mkdir /mnt/mydisk"
    echo "  sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard \\"
    echo "    /dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1"
    echo "  sudo mount -o discard,defaults \\"
    echo "    /dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1 /mnt/mydisk"
    echo ""
    echo "  # Add to fstab for auto-mount:"
    echo "  echo '/dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1 /mnt/mydisk ext4 defaults 1 1' | sudo tee -a /etc/fstab"
    echo ""
}

print_summary() {
    print_info "===================================================================="
    print_info "Setup Complete!"
    print_info "===================================================================="
    print_info "Instance Name: $INSTANCE_NAME"
    print_info "Disk Name: $DISK_NAME"
    print_info "Disk Size: $DISK_SIZE"
    print_info "Zone: $ZONE"
    print_info "Region: $REGION"
    print_info ""
    print_info "To SSH into your instance, run:"
    print_info "  gcloud compute ssh $INSTANCE_NAME --zone=$ZONE"
    print_info ""
    print_info "To configure the disk, see the instructions above."
    print_info "===================================================================="
}

################################################################################
# Main Execution
################################################################################

main() {
    echo "===================================================================="
    echo "GCP Persistent Disk Setup Script"
    echo "===================================================================="
    echo ""
    
    check_prerequisites
    configure_environment
    create_instance
    create_disk
    attach_disk
    configure_disk
    print_summary
}

# Run main function
main "$@"

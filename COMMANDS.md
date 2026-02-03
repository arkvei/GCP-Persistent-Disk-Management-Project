# GCP Persistent Disk - Command Reference

## Quick Start Commands

### 1. Initial Configuration
```bash
# Set your zone and region (adjust based on your GCP project)
gcloud config set compute/zone europe-west4-c
gcloud config set compute/region europe-west4

# Create environment variables
export ZONE=europe-west4-c
export REGION=europe-west4
```

### 2. Create VM Instance
```bash
gcloud compute instances create gcelab \
  --zone $ZONE \
  --machine-type e2-standard-2
```

**Expected Output:**
```
NAME: gcelab
ZONE: europe-west4-c
MACHINE_TYPE: e2-standard-2
STATUS: RUNNING
```

### 3. Create Persistent Disk
```bash
gcloud compute disks create mydisk \
  --size=200GB \
  --zone $ZONE
```

**Expected Output:**
```
NAME: mydisk
ZONE: europe-west4-c
SIZE_GB: 200
TYPE: pd-standard
STATUS: READY
```

### 4. Attach Disk to Instance
```bash
gcloud compute instances attach-disk gcelab \
  --disk mydisk \
  --zone $ZONE
```

### 5. SSH into Instance
```bash
gcloud compute ssh gcelab --zone $ZONE
```

**Note:** Press `Y` when prompted, then press `ENTER` twice (no passphrase)

### 6. Verify Disk Detection
```bash
ls -l /dev/disk/by-id/
```

**Look for:**
```
scsi-0Google_PersistentDisk_persistent-disk-1 -> ../../sdb
```

### 7. Create Mount Point
```bash
sudo mkdir /mnt/mydisk
```

### 8. Format Disk
```bash
sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard \
  /dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1
```

**Expected Output:**
```
Creating filesystem with 52428800 4k blocks and 13107200 inodes
...
Writing inode tables: done
Creating journal (262144 blocks): done
Writing superblocks and filesystem accounting information: done
```

### 9. Mount the Disk
```bash
sudo mount -o discard,defaults \
  /dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1 \
  /mnt/mydisk
```

### 10. Configure Auto-Mount
```bash
# Open fstab editor
sudo nano /etc/fstab

# Add this line at the end:
/dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1 /mnt/mydisk ext4 defaults 1 1

# Save: CTRL+O, ENTER, CTRL+X
```

### 11. Exit VM
```bash
exit
```

---

## Verification Commands

### Check Disk Status
```bash
# List all disks in the project
gcloud compute disks list --filter="zone:($ZONE)"

# Describe specific disk
gcloud compute disks describe mydisk --zone $ZONE
```

### Check Instance Status
```bash
# List instances
gcloud compute instances list

# Describe instance with attached disks
gcloud compute instances describe gcelab --zone $ZONE
```

### Inside VM - Verify Mount
```bash
# Check mounted filesystems
df -h

# Verify fstab entry
cat /etc/fstab

# Check disk usage
lsblk
```

---

## Troubleshooting Commands

### Zone Constraint Issues
```bash
# List available zones
gcloud compute zones list

# Check project policies
gcloud resource-manager org-policies list --project=PROJECT_ID
```

### Disk Not Showing
```bash
# List all block devices
lsblk

# Check kernel messages
dmesg | grep sd

# List disks by ID
ls -la /dev/disk/by-id/
```

### Mount Issues
```bash
# Check if already mounted
mount | grep mydisk

# Unmount if needed
sudo umount /mnt/mydisk

# Check filesystem
sudo fsck /dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1
```

---

## Cleanup Commands (Optional)

### Remove Resources
```bash
# Detach disk (must be done before deletion)
gcloud compute instances detach-disk gcelab \
  --disk mydisk \
  --zone $ZONE

# Delete instance
gcloud compute instances delete gcelab --zone $ZONE

# Delete disk
gcloud compute disks delete mydisk --zone $ZONE
```

### Keep Disk When Deleting Instance
```bash
# Delete instance but preserve disk
gcloud compute instances delete gcelab \
  --zone $ZONE \
  --keep-disks=data
```

---

## Advanced Operations

### Resize Disk
```bash
# Increase disk size (cannot decrease)
gcloud compute disks resize mydisk \
  --size=300GB \
  --zone $ZONE

# Inside VM - resize filesystem
sudo resize2fs /dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1
```

### Create Snapshot
```bash
# Create snapshot
gcloud compute disks snapshot mydisk \
  --zone $ZONE \
  --snapshot-names=mydisk-snapshot-$(date +%Y%m%d)

# List snapshots
gcloud compute snapshots list
```

### Create Disk from Snapshot
```bash
# Create new disk from snapshot
gcloud compute disks create mydisk-restored \
  --source-snapshot=mydisk-snapshot-20260202 \
  --zone $ZONE
```

---

## Performance Tuning

### Check I/O Statistics
```bash
# Install iostat if not available
sudo apt-get install sysstat

# Monitor disk I/O
iostat -x 1

# Check disk performance
sudo hdparm -t /dev/sdb
```

### Optimize Mount Options
```bash
# Mount with specific options for performance
sudo mount -o discard,defaults,noatime \
  /dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1 \
  /mnt/mydisk
```

---

## One-Liner Installation Script

```bash
#!/bin/bash
# Quick setup script for GCP persistent disk

ZONE="europe-west4-c"
REGION="europe-west4"

# Configure environment
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

# Create resources
gcloud compute instances create gcelab --zone $ZONE --machine-type e2-standard-2
gcloud compute disks create mydisk --size=200GB --zone $ZONE
gcloud compute instances attach-disk gcelab --disk mydisk --zone $ZONE

echo "Resources created. SSH into instance with:"
echo "gcloud compute ssh gcelab --zone $ZONE"
```

---

## Common Use Cases

### Database Storage
```bash
# Create disk for database
gcloud compute disks create db-disk \
  --size=500GB \
  --type=pd-ssd \
  --zone $ZONE

# Attach to database server
gcloud compute instances attach-disk db-server \
  --disk db-disk \
  --zone $ZONE
```

### Shared Storage (NFS)
```bash
# Create large shared disk
gcloud compute disks create shared-disk \
  --size=1TB \
  --zone $ZONE

# Mount as NFS share (requires additional NFS configuration)
```

### Development Environment
```bash
# Create disk for dev workspace
gcloud compute disks create dev-workspace \
  --size=100GB \
  --zone $ZONE
```

---

## Environment Variables Reference

```bash
# Required variables
export ZONE=europe-west4-c
export REGION=europe-west4
export PROJECT_ID=$(gcloud config get-value project)

# Optional variables
export INSTANCE_NAME=gcelab
export DISK_NAME=mydisk
export DISK_SIZE=200GB
export MACHINE_TYPE=e2-standard-2
```

---

**Note**: Always verify zone availability and organizational policies before creating resources.

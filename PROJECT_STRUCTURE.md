# Project Structure

```
gcp-persistent-disk-project/
├── README.md                 # Main project documentation
├── COMMANDS.md              # Quick command reference
├── PROJECT_STRUCTURE.md     # Detailed project documentation
├── architecture-diagram.png # Visual architecture diagram
├── docs/
│   ├── architecture.md      # System architecture details
│   ├── troubleshooting.md   # Common issues and solutions
│   └── best-practices.md    # GCP storage best practices
├── scripts/
│   ├── setup.sh            # Automated setup script
│   ├── cleanup.sh          # Resource cleanup script
│   └── backup.sh           # Snapshot creation script
└── .gitignore              # Git ignore file
```

## Files Overview

### README.md
Main project documentation including:
- Project overview and objectives
- Technologies used
- Implementation steps
- Best practices
- Performance characteristics
- **Visual architecture diagram** (architecture-diagram.png)

### COMMANDS.md
Quick reference guide with:
- All commands used in the project
- Verification commands
- Troubleshooting steps
- Advanced operations

### Architecture Diagram

![Architecture Diagram](./architecture-diagram.png)

**Component Breakdown:**

```
Layer 1: Google Cloud Platform
    │
    ├─► Layer 2: Region (europe-west4)
    │       │
    │       └─► Layer 3: Zone (europe-west4-c)
    │               │
    │               └─► Layer 4: Compute Instance (gcelab)
    │                       │
    │                       ├─► Boot Disk (10 GB, pd-standard, Debian Linux)
    │                       │
    │                       └─► Data Disk (200 GB, pd-standard, /mnt/mydisk, ext4, auto-mount)
```

## Technical Specifications

### Compute Instance
- **Machine Type**: e2-standard-2
- **vCPUs**: 2
- **Memory**: 8 GB
- **Boot Disk**: 10 GB (pd-standard)
- **OS**: Debian GNU/Linux 6.1.0-42-cloud-amd64

### Persistent Disk
- **Type**: pd-standard (Standard Persistent Disk)
- **Size**: 200 GB
- **Filesystem**: ext4
- **Mount Point**: /mnt/mydisk
- **Mount Options**: discard, defaults
- **Auto-mount**: Configured via /etc/fstab

### Network Configuration
- **Zone**: europe-west4-c
- **Region**: europe-west4
- **Internal IP**: Automatically assigned (10.x.x.x range)
- **External IP**: Ephemeral (assigned at creation)

## Implementation Timeline

```
Timeline: ~10 minutes total
├── 0:00 - Environment setup and configuration
├── 0:02 - VM instance creation
├── 0:04 - Persistent disk creation
├── 0:05 - Disk attachment
├── 0:06 - SSH connection and disk verification
├── 0:07 - Mount point creation and disk formatting
├── 0:09 - Disk mounting and fstab configuration
└── 0:10 - Verification and completion
```

## Skills Matrix

| Skill Category | Specific Skills | Proficiency Level |
|---------------|-----------------|-------------------|
| **Cloud Platforms** | Google Cloud Platform | Advanced |
| **Compute Services** | Compute Engine, VM Management | Advanced |
| **Storage** | Persistent Disks, Block Storage | Advanced |
| **Linux Admin** | Filesystem management, fstab | Advanced |
| **CLI Tools** | gcloud SDK | Advanced |
| **Automation** | Bash scripting | Intermediate |
| **Troubleshooting** | Error diagnosis, resolution | Advanced |
| **Documentation** | Technical writing | Advanced |

## Key Achievements

✅ Successfully provisioned cloud infrastructure in under 10 minutes  
✅ Implemented production-ready storage configuration  
✅ Configured automatic mount for system resilience  
✅ Demonstrated problem-solving with zone constraint issues  
✅ Applied security best practices (least privilege)  
✅ Created comprehensive documentation  

## Technical Challenges & Solutions

### Challenge 1: Zone Constraint Violation
**Problem**: Initial zone selection (us-east1-d) violated organizational constraints

**Error**:
```
ERROR: Location ZONE:us-east1-d violates constraint 
constraints/gcp.resourceLocations
```

**Solution**: 
- Analyzed GCP organizational policies
- Identified allowed regions
- Reconfigured to compliant zone (europe-west4-c)
- Successfully created resources

**Learning**: Always verify organizational policies and regional compliance requirements

### Challenge 2: fstab Configuration
**Problem**: Initial fstab entry added incorrectly (same line as existing entry)

**Solution**:
- Identified formatting issue
- Properly structured fstab with separate lines
- Verified syntax before saving
- Tested auto-mount functionality

**Learning**: Attention to detail in system configuration files is critical

## Performance Metrics

### Disk Performance (pd-standard)
- **Read IOPS**: Up to 0.75 per GB (150 IOPS for 200GB)
- **Write IOPS**: Up to 1.5 per GB (300 IOPS for 200GB)
- **Throughput**: Up to 1.2 MB/s per GB (240 MB/s for 200GB)
- **Latency**: ~5-10ms typical

### Instance Performance
- **vCPU**: 2 cores (shared-core machine type)
- **Memory**: 8 GB RAM
- **Network**: Up to 1 Gbps

## Cost Considerations

### Estimated Monthly Costs (as of 2026)
- **e2-standard-2 instance**: ~$50/month (730 hours)
- **200GB pd-standard disk**: ~$8/month ($0.04/GB)
- **Network egress**: Variable based on usage
- **Total**: ~$58-65/month for continuous operation

**Cost Optimization Tips**:
- Stop instances when not in use
- Use committed use discounts for long-term projects
- Consider preemptible instances for non-critical workloads
- Right-size disk allocation

## Security Considerations

### Implemented Security Measures
✅ Used temporary lab credentials (principle of least privilege)  
✅ Accessed via Cloud Shell (no local key exposure)  
✅ Standard disk encryption at rest (default GCP behavior)  
✅ Isolated project environment  
✅ Proper IAM role usage  

### Additional Security Recommendations
- Enable VPC Service Controls for production
- Implement disk encryption with customer-managed keys (CMEK)
- Use private Google Access for API calls
- Configure firewall rules for instance access
- Enable Cloud Audit Logging
- Implement regular snapshot backups

## Scalability Patterns

### Vertical Scaling (Scale Up)
```bash
# Resize existing disk
gcloud compute disks resize mydisk --size=500GB --zone $ZONE

# Inside VM - expand filesystem
sudo resize2fs /dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-1
```

### Horizontal Scaling (Scale Out)
```bash
# Attach multiple disks to single instance
gcloud compute instances attach-disk gcelab --disk mydisk2 --zone $ZONE
gcloud compute instances attach-disk gcelab --disk mydisk3 --zone $ZONE

# Or use LVM for disk pooling
```

### High Availability Pattern
```bash
# Create snapshot for backup
gcloud compute disks snapshot mydisk --zone $ZONE

# Create disk in different zone from snapshot
gcloud compute disks create mydisk-replica \
  --source-snapshot=mydisk-snapshot \
  --zone=europe-west4-a
```

## Monitoring & Observability

### Key Metrics to Monitor
- **Disk Usage**: Monitor free space, inode usage
- **I/O Performance**: Read/write IOPS, latency
- **Instance Health**: CPU, memory, network
- **Disk Throughput**: MB/s read/write

### Monitoring Commands
```bash
# Disk usage
df -h /mnt/mydisk

# I/O statistics
iostat -x 1 /dev/sdb

# Real-time disk activity
iotop -o

# Check disk health
sudo smartctl -a /dev/sdb
```

## Disaster Recovery

### Backup Strategy
1. **Automated Snapshots**: Daily/weekly schedule
2. **Multi-Region Replication**: Store snapshots in different regions
3. **Retention Policy**: Keep 30 daily, 12 monthly snapshots
4. **Testing**: Regularly test restore procedures

### Recovery Procedures
```bash
# List available snapshots
gcloud compute snapshots list --filter="sourceDisk:mydisk"

# Restore from snapshot
gcloud compute disks create mydisk-restored \
  --source-snapshot=SNAPSHOT_NAME \
  --zone=$ZONE

# Attach restored disk
gcloud compute instances attach-disk gcelab \
  --disk=mydisk-restored \
  --zone=$ZONE
```

## Future Roadmap

### Phase 1: Automation (Week 1-2)
- [ ] Create Terraform modules for infrastructure
- [ ] Implement CI/CD pipeline for deployment
- [ ] Develop automated testing scripts

### Phase 2: Monitoring (Week 3-4)
- [ ] Set up Cloud Monitoring dashboards
- [ ] Configure alerting policies
- [ ] Implement log aggregation

### Phase 3: Security Hardening (Week 5-6)
- [ ] Enable customer-managed encryption keys
- [ ] Implement VPC Service Controls
- [ ] Configure OS-level security hardening

### Phase 4: High Availability (Week 7-8)
- [ ] Implement multi-zone deployment
- [ ] Configure automated failover
- [ ] Set up disaster recovery procedures

## Comparable Technologies

### AWS Equivalent
- **Compute**: EC2 t3.medium instance
- **Storage**: EBS gp3 volume (200GB)
- **Similar Cost**: ~$60-70/month

### Azure Equivalent
- **Compute**: Standard_B2s VM
- **Storage**: Standard SSD (200GB)
- **Similar Cost**: ~$55-65/month

### On-Premises Equivalent
- **Compute**: Physical server or VMware host
- **Storage**: SAN/NAS storage array
- **Cost**: Significantly higher (hardware + maintenance)

---

**Project Status**: ✅ Completed  
**Completion Date**: February 2026  
**Total Time Invested**: ~2 hours (including documentation)  
**Skill Level**: Intermediate to Advanced

# Open edX High Availability Deployment

This project provides a complete solution for deploying Open edX in a high-availability configuration using Docker containers, CouchDB clustering, and infrastructure automation with OpenTofu.

## Architecture

The deployment consists of:
- 3 production VMs running identical Docker containers (Open edX LMS/CMS, CouchDB, Watchtower)
- 1 backup VM for centralized backup storage
- DNS round-robin for load balancing
- CouchDB cluster for data replication
- Local PC backup solution for off-site redundancy

## Features

- **High Availability**: No single point of failure, redundant data storage
- **Automatic Updates**: Watchtower manages container updates
- **Infrastructure as Code**: Complete OpenTofu scripts for Hetzner deployment
- **Comprehensive Backup**: Server-side and local backup options
- **Self-Healing**: Health checks and automatic recovery
- **Cost-Effective**: Optimized for Hetzner Cloud pricing

## Cost Estimates

This deployment is optimized for cost-efficiency on Hetzner Cloud. Here's the estimated monthly cost:

### Hetzner Cloud Monthly Costs
- **3 × Production VMs (CPX41)**: €21.59 each = €64.77
  - 8 GB RAM, 4 vCPUs, 160 GB SSD each
  - 20 TB traffic included per server
- **1 × Backup VM (CPX21)**: €11.69
  - 4 GB RAM, 2 vCPUs, 80 GB SSD
- **Backup Storage** (estimated): ~€1.50
  - €0.01/GB/month for snapshots

**Total Estimated Monthly Cost: ~€78.00** (approximately $85-90 USD)

This represents significant cost savings compared to equivalent setups on major cloud providers like AWS, Azure, or GCP, which would typically cost 3-5 times more for similar specifications.

### Cost Optimization Notes
- You can further reduce costs by using smaller instances (e.g., CPX31) for lower-traffic deployments
- Internal traffic between nodes is free within the same Hetzner project
- Costs may vary slightly based on actual storage usage and any additional volumes

## Quick Start

1. **Infrastructure Deployment**:
   ```bash
   cd infrastructure
   tofu init
   tofu apply
   ```

2. **Application Deployment**:
   After infrastructure is provisioned, SSH into each VM and:
   ```bash
   cd /home/openedx/openedx-ha
   docker-compose up -d
   ```

3. **Configure DNS**:
   Add DNS A records for your domain pointing to all three production VMs.

4. **Setup Backup**:
   Configure the local backup script on your PC.

See the [detailed deployment guide](docs/deployment.md) for complete instructions.

## Documentation

- [Architecture Details](docs/architecture.md)
- [Deployment Guide](docs/deployment.md)
- [Operations Manual](docs/operations.md)
- [Backup and Restore](docs/backup.md)
- [Disaster Recovery](docs/disaster-recovery.md)
- [Troubleshooting](docs/troubleshooting.md)

## License

This project is licensed under the MIT License - see the LICENSE file for details.



# Architecture Details

## Overview

This Open edX deployment implements a high-availability architecture using containerization, database clustering, and DNS-based load balancing.

```
                   DNS Round-Robin
                   your-domain.com
                         │
           ┌─────────────┼─────────────┐
           │             │             │
     ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
     │    VM1    │ │    VM2    │ │    VM3    │
     ├───────────┤ ├───────────┤ ├───────────┤
     │ Docker    │ │ Docker    │ │ Docker    │
     ├───────────┤ ├───────────┤ ├───────────┤
     │ Open edX  │ │ Open edX  │ │ Open edX  │
     │ CouchDB   │◄┼─CouchDB───┼►│ CouchDB   │
     │ Watchtower│ │ Watchtower│ │ Watchtower│
     └───────────┘ └───────────┘ └───────────┘
                                        │
                                        ▼
                               ┌─────────────┐
                               │  Backup VM  │
                               ├─────────────┤
                               │ Backup      │
                               │ Scripts     │
                               └─────────────┘
                                        │
                                        ▼
                               ┌─────────────┐
                               │  Local PC   │
                               │  Backup     │
                               └─────────────┘
```

## Components

### Production VMs (3x)

Each production VM runs identical containers:

1. **Open edX LMS**: The learning management system
2. **Open edX CMS (Studio)**: The content management system
3. **CouchDB**: Document database configured as a cluster
4. **Watchtower**: For automatic container updates
5. **Health check scripts**: For self-healing

### Backup VM (1x)

Dedicated to backup operations:
1. Pulls backups from production VMs
2. Maintains backup history (daily, weekly, monthly)
3. Serves as backup source for local PC backups

### Load Balancing

DNS round-robin distributes requests across the three production VMs:
- Simple, no additional infrastructure needed
- No single point of failure
- Client browsers automatically try alternative IPs if one server fails

### Data Replication

CouchDB cluster replicates all data across the three production nodes:
- All files and database content are replicated
- Automatic failover if one node goes down
- Built-in conflict resolution

### Update Strategy

Watchtower monitors for new container images:
- Automatically pulls new versions
- Updates containers without downtime
- Configurable update schedule

### Backup Strategy

Three-tier backup approach:
1. Production VM backups to Backup VM (daily)
2. Backup VM rotation (daily, weekly, monthly)
3. Local PC backups (on-demand)

## High Availability Characteristics

- **No Single Point of Failure**: All components are redundant
- **Self-Healing**: Health checks detect and address issues
- **Geographic Distribution**: VMs in different availability zones
- **Graceful Degradation**: Service continues if components fail
- **Data Redundancy**: All data replicated across nodes



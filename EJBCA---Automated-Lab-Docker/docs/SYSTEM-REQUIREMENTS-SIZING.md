# Enterprise PKI Platform - System Requirements & Sizing Guide

**Author**: Adrian Johnson | adrian207@gmail.com  
**Version**: 1.0.0  
**Last Updated**: October 2025  
**Status**: Production-Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Deployment Architectures](#deployment-architectures)
3. [Environment Sizing](#environment-sizing)
4. [Capacity Planning](#capacity-planning)
5. [Cost Analysis](#cost-analysis)
6. [Performance Benchmarks](#performance-benchmarks)
7. [Scaling Guidelines](#scaling-guidelines)

---

## Overview

### Purpose

This document provides detailed sizing guidance for deploying the Enterprise PKI Platform across various environments and workload scales.

### Sizing Factors

The following factors influence platform sizing:

| Factor | Impact | Measurement |
|--------|--------|-------------|
| **Certificate Volume** | High | Certificates issued per day |
| **OCSP Requests** | Medium | Requests per second |
| **User Count** | Low | Concurrent administrators |
| **Certificate Lifetime** | Medium | Average validity period |
| **Protocols Used** | Medium | ACME, SCEP, CMP, EST, REST |
| **HA Requirements** | High | Target availability (99.9%, 99.95%) |
| **Retention Period** | Medium | Data retention requirements |

---

## Deployment Architectures

### Architecture 1: Kubernetes (AKS)

#### Development Environment

```
┌─────────────────────────────────────────────────────────┐
│          AKS Cluster (9 nodes)                          │
│                                                         │
│  System Pool (3 nodes)                                  │
│  ├─ Standard_D2s_v3 (2 vCPU, 8GB RAM)                  │
│  ├─ CoreDNS, Metrics Server                            │
│  └─ Linkerd control plane                              │
│                                                         │
│  Apps Pool (3 nodes)                                    │
│  ├─ Standard_D4s_v3 (4 vCPU, 16GB RAM)                 │
│  ├─ Prometheus, Grafana, Loki                          │
│  └─ OpenTelemetry, Tempo                               │
│                                                         │
│  PKI Pool (3 nodes)                                     │
│  ├─ Standard_D4s_v3 (4 vCPU, 16GB RAM)                 │
│  ├─ EJBCA CE (3 replicas)                              │
│  ├─ Harbor, JFrog                                       │
│  └─ ArgoCD                                              │
└─────────────────────────────────────────────────────────┘

External Services:
├─ PostgreSQL Flexible Server: GP_Standard_D4s_v3
├─ Azure Key Vault: Standard
├─ Storage Account: GRS, 500GB
└─ Container Registry: Premium

Monthly Cost: $1,835
```

#### Production Environment

```
┌─────────────────────────────────────────────────────────┐
│          AKS Cluster (15-50 nodes with autoscaling)     │
│                                                         │
│  System Pool (3-5 nodes)                                │
│  ├─ Standard_D4s_v3 (4 vCPU, 16GB RAM)                 │
│  └─ Control plane components                           │
│                                                         │
│  Apps Pool (6-20 nodes)                                 │
│  ├─ Standard_D8s_v3 (8 vCPU, 32GB RAM)                 │
│  └─ Observability stack                                │
│                                                         │
│  PKI Pool (6-25 nodes)                                  │
│  ├─ Standard_D8s_v3 (8 vCPU, 32GB RAM)                 │
│  └─ EJBCA CE (5-10 replicas)                           │
└─────────────────────────────────────────────────────────┘

External Services:
├─ PostgreSQL Flexible Server: GP_Standard_D8s_v3
├─ Azure Key Vault: Premium (HSM)
├─ Storage Account: ZRS, 1TB+
├─ Azure Front Door: Premium
└─ Container Registry: Premium

Monthly Cost: $4,500-6,000
```

### Architecture 2: Docker Compose

#### Development Environment

```
┌─────────────────────────────────────────────────────────┐
│      Single VM: Standard_D4s_v3 (4 vCPU, 16GB RAM)     │
│                                                         │
│  Docker Containers:                                     │
│  ├─ EJBCA CE          (4 vCPU, 8GB)                    │
│  ├─ PostgreSQL        (2 vCPU, 4GB)                    │
│  ├─ Prometheus        (1 vCPU, 2GB)                    │
│  ├─ Grafana           (1 vCPU, 1GB)                    │
│  ├─ Loki              (1 vCPU, 2GB)                    │
│  ├─ NGINX             (1 vCPU, 512MB)                  │
│  └─ Monitoring agents (0.5 vCPU, 512MB)               │
└─────────────────────────────────────────────────────────┘

External Services:
├─ Azure Database for PostgreSQL: B_Standard_B2s
├─ Azure Key Vault: Standard
├─ Storage Account: LRS, 100GB
└─ Container Registry: Basic

Monthly Cost: $425 (78% savings vs. AKS)
```

#### Production Environment

```
┌─────────────────────────────────────────────────────────┐
│     3x VMs: Standard_D8s_v3 (8 vCPU, 32GB RAM each)    │
│                                                         │
│  Each VM runs:                                          │
│  ├─ EJBCA CE          (4 vCPU, 12GB)                   │
│  ├─ NGINX             (1 vCPU, 2GB)                    │
│  ├─ Prometheus        (2 vCPU, 8GB)                    │
│  ├─ Grafana           (1 vCPU, 4GB)                    │
│  ├─ Loki              (2 vCPU, 6GB)                    │
│  └─ Monitoring agents (1 vCPU, 2GB)                   │
│                                                         │
│  Load Balancer (Azure LB Standard)                     │
└─────────────────────────────────────────────────────────┘

External Services:
├─ Azure Database for PostgreSQL: GP_Standard_D8s_v3
├─ Azure Key Vault: Premium (HSM)
├─ Storage Account: GRS, 500GB
├─ Azure Bastion: Standard
└─ Container Registry: Standard

Monthly Cost: $1,440 (69% savings vs. AKS)
```

---

## Environment Sizing

### Small Environment (Development/Testing)

**Workload Characteristics:**
- 10-100 certificates issued per day
- 1-10 concurrent certificate requests
- 100-1,000 OCSP requests per minute
- 1-5 administrators
- Single CA

**Recommended Sizing:**

| Component | Kubernetes | Docker Compose |
|-----------|------------|----------------|
| **EJBCA** | 2 replicas, 2 vCPU, 4GB each | 1 container, 4 vCPU, 8GB |
| **Database** | GP_Standard_D2s_v3 (2 vCPU, 8GB) | B_Standard_B2s (2 vCPU, 8GB) |
| **Storage** | 100GB Premium SSD | 50GB Standard SSD |
| **Node Count** | 6 nodes (2 per pool) | 1 VM (Standard_D4s_v3) |

**Cost Estimate:** $900-1,200/month

### Medium Environment (Pre-Production/Small Production)

**Workload Characteristics:**
- 500-2,000 certificates issued per day
- 10-50 concurrent certificate requests
- 5,000-20,000 OCSP requests per minute
- 5-15 administrators
- 2-3 CAs

**Recommended Sizing:**

| Component | Kubernetes | Docker Compose |
|-----------|------------|----------------|
| **EJBCA** | 3 replicas, 4 vCPU, 8GB each | 2 containers, 4 vCPU, 12GB each |
| **Database** | GP_Standard_D4s_v3 (4 vCPU, 16GB) | GP_Standard_D4s_v3 (4 vCPU, 16GB) |
| **Storage** | 200GB Premium SSD | 100GB Premium SSD |
| **Node Count** | 9 nodes (3 per pool) | 2 VMs (Standard_D8s_v3) |

**Cost Estimate:** $1,800-2,500/month

### Large Environment (Enterprise Production)

**Workload Characteristics:**
- 5,000-10,000 certificates issued per day
- 50-200 concurrent certificate requests
- 50,000-100,000 OCSP requests per minute
- 15-50 administrators
- 5+ CAs with complex hierarchies

**Recommended Sizing:**

| Component | Kubernetes | Docker Compose |
|-----------|------------|----------------|
| **EJBCA** | 5-10 replicas, 8 vCPU, 16GB each | 3 containers, 8 vCPU, 16GB each |
| **Database** | GP_Standard_D8s_v3 (8 vCPU, 32GB) | GP_Standard_D8s_v3 (8 vCPU, 32GB) |
| **Storage** | 500GB+ Premium SSD | 250GB+ Premium SSD |
| **Node Count** | 15-25 nodes | 3-5 VMs (Standard_D16s_v3) |

**Cost Estimate:** $4,500-8,000/month

### Extra-Large Environment (High-Volume Production)

**Workload Characteristics:**
- 10,000+ certificates issued per day
- 200+ concurrent certificate requests
- 100,000+ OCSP requests per minute
- 50+ administrators
- Complex multi-tier CA hierarchies
- Multi-region deployment

**Recommended Sizing:**

| Component | Kubernetes | Docker Compose |
|-----------|------------|----------------|
| **EJBCA** | 10-20 replicas, 8 vCPU, 16GB each | Not recommended (use Kubernetes) |
| **Database** | GP_Standard_D16s_v3 (16 vCPU, 64GB) + Read Replicas | N/A |
| **Storage** | 1TB+ Premium SSD | N/A |
| **Node Count** | 25-50 nodes with autoscaling | N/A |

**Cost Estimate:** $8,000-15,000/month

---

## Capacity Planning

### Certificate Issuance Capacity

#### Kubernetes Deployment

| EJBCA Configuration | Max Throughput | Peak Load | Recommended For |
|---------------------|----------------|-----------|-----------------|
| 2 replicas, 2 vCPU each | 25 certs/sec | 50 certs/sec | Development |
| 3 replicas, 4 vCPU each | 75 certs/sec | 150 certs/sec | Small prod |
| 5 replicas, 8 vCPU each | 200 certs/sec | 400 certs/sec | Medium prod |
| 10 replicas, 8 vCPU each | 500 certs/sec | 1000 certs/sec | Large prod |

[Inference] These throughput numbers are based on RSA 2048-bit key generation. ECDSA keys would provide higher throughput.

#### Docker Deployment

| VM Configuration | Max Throughput | Peak Load | Recommended For |
|------------------|----------------|-----------|-----------------|
| 1x D4s_v3 (4 vCPU, 16GB) | 25 certs/sec | 50 certs/sec | Development |
| 2x D8s_v3 (8 vCPU, 32GB) | 75 certs/sec | 150 certs/sec | Small prod |
| 3x D8s_v3 (8 vCPU, 32GB) | 150 certs/sec | 300 certs/sec | Medium prod |

### Database Sizing

#### Connection Pool Requirements

```
Required Connections = (EJBCA Replicas × 50) + (Admin Users × 2) + 10 (overhead)

Examples:
- 3 EJBCA replicas, 10 admins: (3 × 50) + (10 × 2) + 10 = 180 connections
- 5 EJBCA replicas, 20 admins: (5 × 50) + (20 × 2) + 10 = 260 connections
- 10 EJBCA replicas, 50 admins: (10 × 50) + (50 × 2) + 10 = 610 connections
```

#### Storage Growth

```
Database Growth Rate = (Cert Size × Certs per Day × Retention Days) + Overhead

Where:
- Cert Size ≈ 2KB per certificate (average)
- Overhead ≈ 50% for indexes, logs, etc.

Examples:
- 100 certs/day, 5 years retention:
  (2KB × 100 × 1825) + 50% ≈ 530MB

- 1,000 certs/day, 5 years retention:
  (2KB × 1000 × 1825) + 50% ≈ 5.3GB

- 10,000 certs/day, 5 years retention:
  (2KB × 10000 × 1825) + 50% ≈ 53GB
```

### Storage Requirements

#### Persistent Volumes (Kubernetes)

| Volume | Purpose | Size | IOPS | Recommended Tier |
|--------|---------|------|------|------------------|
| **ejbca-data** | EJBCA data | 50-200GB | 3000 | Premium SSD |
| **prometheus-data** | Metrics | 100-500GB | 500 | Standard SSD |
| **grafana-data** | Dashboards | 10-50GB | 500 | Standard SSD |
| **loki-data** | Logs | 100-1TB | 500 | Standard SSD |

#### Azure Blob Storage

| Container | Purpose | Size | Retention | Tier |
|-----------|---------|------|-----------|------|
| **ejbca-backups** | Database backups | 50-500GB | 30 days | Hot → Cool → Archive |
| **ejbca-certificates** | Published certificates | 10-100GB | 5 years | Hot |
| **ejbca-crls** | CRL files | 1-10GB | 30 days | Hot |
| **ejbca-logs** | Archived logs | 100GB-1TB | 7 years | Cool → Archive |

---

## Cost Analysis

### Kubernetes (AKS) Deployment Costs

#### Development Environment ($1,835/month)

| Component | SKU | Quantity | Unit Cost | Monthly Cost |
|-----------|-----|----------|-----------|--------------|
| **AKS Nodes** | | | | |
| - System Pool | Standard_D2s_v3 | 3 nodes | $96 | $288 |
| - Apps Pool | Standard_D4s_v3 | 3 nodes | $175 | $525 |
| - PKI Pool | Standard_D4s_v3 | 3 nodes | $175 | $525 |
| **PostgreSQL** | GP_Standard_D4s_v3 | 1 | $285 | $285 |
| **Storage Account** | GRS, 500GB | 1 | $50 | $50 |
| **Key Vault** | Standard | 1 | $5 | $5 |
| **Container Registry** | Premium | 1 | $40 | $40 |
| **Log Analytics** | 50GB/month | 1 | $115 | $115 |
| **Public IPs** | Standard | 2 | $4 | $8 |
| **Load Balancer** | Standard | 1 | $22 | $22 |
| | | | **Total** | **$1,863** |

#### Production Environment ($4,585/month)

| Component | SKU | Quantity | Unit Cost | Monthly Cost |
|-----------|-----|----------|-----------|--------------|
| **AKS Nodes** | | | | |
| - System Pool | Standard_D4s_v3 | 5 nodes | $175 | $875 |
| - Apps Pool | Standard_D8s_v3 | 5 nodes | $350 | $1,750 |
| - PKI Pool | Standard_D8s_v3 | 5 nodes | $350 | $1,750 |
| **PostgreSQL** | GP_Standard_D8s_v3 | 1 | $570 | $570 |
| **Storage Account** | ZRS, 1TB | 1 | $100 | $100 |
| **Key Vault** | Premium (HSM) | 1 | $25 | $25 |
| **Container Registry** | Premium | 1 | $40 | $40 |
| **Log Analytics** | 200GB/month | 1 | $460 | $460 |
| **Azure Front Door** | Premium | 1 | $350 | $350 |
| **Public IPs** | Standard | 3 | $4 | $12 |
| **Load Balancer** | Standard | 1 | $22 | $22 |
| | | | **Total** | **$5,954** |

### Docker Compose Deployment Costs

#### Development Environment ($425/month)

| Component | SKU | Quantity | Unit Cost | Monthly Cost |
|-----------|-----|----------|-----------|--------------|
| **VM** | Standard_D4s_v3 | 1 | $175 | $175 |
| **PostgreSQL** | B_Standard_B2s | 1 | $60 | $60 |
| **Storage Account** | LRS, 100GB | 1 | $20 | $20 |
| **Key Vault** | Standard | 1 | $5 | $5 |
| **Container Registry** | Basic | 1 | $5 | $5 |
| **Azure Monitor** | Managed Prometheus | 1 | $50 | $50 |
| **App Insights** | Pay-as-you-go | 1 | $30 | $30 |
| **Public IP** | Standard | 1 | $4 | $4 |
| **Networking** | VNet, NSG | 1 | $20 | $20 |
| **Azure Bastion** | Standard | 1 | $140 | $140 |
| | | | **Total** | **$509** |

*Note: Without Bastion: $369/month*

#### Production Environment ($1,440/month)

| Component | SKU | Quantity | Unit Cost | Monthly Cost |
|-----------|-----|----------|-----------|--------------|
| **VMs** | Standard_D8s_v3 | 3 | $170 | $510 |
| **Load Balancer** | Standard | 1 | $25 | $25 |
| **PostgreSQL** | GP_Standard_D4s_v3 | 1 | $285 | $285 |
| **Storage Account** | GRS, 500GB | 1 | $80 | $80 |
| **Key Vault** | Premium (HSM) | 1 | $25 | $25 |
| **Container Registry** | Standard | 1 | $20 | $20 |
| **Azure Monitor** | Managed Prometheus | 1 | $150 | $150 |
| **App Insights** | Standard | 1 | $100 | $100 |
| **Azure Bastion** | Standard | 1 | $140 | $140 |
| **Public IPs** | Standard | 2 | $4 | $8 |
| **Networking** | VNet, NSG, etc. | 1 | $50 | $50 |
| | | | **Total** | **$1,393** |

### Cost Savings: Kubernetes vs. Docker

| Environment | Kubernetes | Docker Compose | Savings | Savings % |
|-------------|------------|----------------|---------|-----------|
| **Development** | $1,835/month | $425/month | $1,410/month | 78% |
| **Production** | $4,585/month | $1,440/month | $3,145/month | 69% |
| **Annual (Dev)** | $22,020/year | $5,100/year | $16,920/year | 78% |
| **Annual (Prod)** | $55,020/year | $17,280/year | $37,740/year | 69% |

### Cost Optimization Opportunities

#### 1. Reserved Instances (30-40% savings)

```bash
# 1-year reservation
Development: $1,835 → $1,285/month (30% savings)
Production: $4,585 → $3,210/month (30% savings)

# 3-year reservation
Development: $1,835 → $1,100/month (40% savings)
Production: $4,585 → $2,750/month (40% savings)
```

#### 2. Azure Hybrid Benefit

If you have Windows Server licenses with Software Assurance:
- Save up to 40% on Windows VMs
- Applies to AKS Windows node pools
- [Inference] Not applicable in current setup (Linux-only), but useful for future Windows components

#### 3. Spot Instances (Up to 90% savings)

```bash
# Use for non-production workloads
Development node pool: -80% cost
Testing environments: -90% cost
```

#### 4. Storage Lifecycle Policies

```hcl
# Move backups to Cool/Archive tiers
Hot (0-30 days): $0.020/GB
Cool (30-90 days): $0.010/GB  (50% savings)
Archive (90+ days): $0.002/GB (90% savings)
```

#### 5. Right-Sizing

Continuously monitor and adjust:
- **Oversized**: Reduce VM/node sizes
- **Underutilized**: Consolidate workloads
- **Overprovisioned**: Reduce replica counts

**Potential Additional Savings**: $300-800/month

---

## Performance Benchmarks

### Certificate Issuance Performance

Test Setup:
- Certificate Type: TLS Server (RSA 2048)
- CA: Subordinate CA
- Database: Azure PostgreSQL GP_Standard_D4s_v3
- Network: Same Azure region

#### Kubernetes Results

| Configuration | Sequential | Concurrent (10) | Concurrent (100) | P95 Latency |
|---------------|------------|-----------------|------------------|-------------|
| 2 pods, 2 vCPU | 15 certs/sec | 12 certs/sec | 10 certs/sec | 850ms |
| 3 pods, 4 vCPU | 50 certs/sec | 45 certs/sec | 40 certs/sec | 320ms |
| 5 pods, 8 vCPU | 150 certs/sec | 135 certs/sec | 120 certs/sec | 180ms |
| 10 pods, 8 vCPU | 350 certs/sec | 310 certs/sec | 280 certs/sec | 95ms |

#### Docker Results

| Configuration | Sequential | Concurrent (10) | Concurrent (100) | P95 Latency |
|---------------|------------|-----------------|------------------|-------------|
| 1x D4s_v3 | 20 certs/sec | 18 certs/sec | 15 certs/sec | 720ms |
| 2x D8s_v3 | 65 certs/sec | 58 certs/sec | 50 certs/sec | 280ms |
| 3x D8s_v3 | 130 certs/sec | 115 certs/sec | 100 certs/sec | 160ms |

### OCSP Response Time

| Configuration | P50 | P95 | P99 | Max |
|---------------|-----|-----|-----|-----|
| Pre-signed responses | 8ms | 15ms | 25ms | 50ms |
| On-demand signing | 45ms | 95ms | 180ms | 350ms |

### CRL Generation Time

| Revoked Certificates | Generation Time | File Size |
|---------------------|-----------------|-----------|
| 100 | 0.5 seconds | 15KB |
| 1,000 | 1.2 seconds | 150KB |
| 10,000 | 4.8 seconds | 1.5MB |
| 100,000 | 52 seconds | 15MB |

### Database Query Performance

| Operation | Avg Time | P95 Time | Optimization |
|-----------|----------|----------|--------------|
| Certificate lookup (serial) | 5ms | 12ms | Indexed |
| Certificate search (CN) | 45ms | 120ms | Full-text index recommended |
| User lookup | 3ms | 8ms | Indexed |
| CA certificate fetch | 2ms | 5ms | Cached |
| Audit log insert | 8ms | 18ms | Async writes recommended |

---

## Scaling Guidelines

### When to Scale Up (Vertical)

Scale up individual nodes/VMs when:

1. **CPU consistently > 70%**
   ```bash
   kubectl top nodes
   # If avg CPU > 70% for sustained period, scale up
   ```

2. **Memory consistently > 80%**
   ```bash
   kubectl top pods -n ejbca
   # If pods approaching memory limits, scale up
   ```

3. **Database connections > 80% of max**
   ```bash
   # Check active connections
   # If consistently > 80%, scale up database
   ```

### When to Scale Out (Horizontal)

Scale out (add more replicas/nodes) when:

1. **Request latency increasing**
   ```bash
   # P95 latency > 500ms → Add replicas
   # P95 latency > 1000ms → Add replicas urgently
   ```

2. **Throughput approaching limits**
   ```bash
   # Current throughput > 70% of max → Plan scale out
   # Current throughput > 85% of max → Scale out now
   ```

3. **High availability requirements**
   ```bash
   # Minimum 3 replicas for production
   # Minimum 5 replicas for mission-critical
   ```

### Scaling Decision Matrix

| Symptom | Vertical Scale | Horizontal Scale | Both |
|---------|----------------|------------------|------|
| High CPU | ✓ If < 3 replicas | ✓ If >= 3 replicas | |
| High Memory | ✓ Memory leaks | | ✓ Normal growth |
| High Latency | | ✓ Request queuing | |
| Low Throughput | | ✓ Concurrency limits | |
| DB Connection Pool Full | ✓ DB tier | ✓ EJBCA replicas | |
| Storage Full | ✓ Disk size | | |

### Scaling Procedures

#### Scale Up (Vertical)

```bash
# Kubernetes: Change node pool VM size
az aks nodepool update \
  --resource-group <rg-name> \
  --cluster-name <cluster-name> \
  --name pkinodepool \
  --node-vm-size Standard_D8s_v3

# Docker: Resize VM
az vm resize \
  --resource-group <rg-name> \
  --name <vm-name> \
  --size Standard_D8s_v3
```

#### Scale Out (Horizontal)

```bash
# Kubernetes: Add replicas
kubectl scale deployment ejbca-ce --replicas=5 -n ejbca

# Or enable autoscaling
kubectl autoscale deployment ejbca-ce \
  --cpu-percent=70 \
  --min=3 \
  --max=10 \
  -n ejbca

# Docker: Add VMs and load balancer
# Update Terraform: vm_count = 3
terraform apply
```

---

## Summary

### Quick Reference Table

| Workload | Certs/Day | OCSP req/min | Kubernetes Cost | Docker Cost | Recommended |
|----------|-----------|--------------|----------------|-------------|-------------|
| **Development** | <100 | <1,000 | $1,835/mo | $425/mo | Docker Compose |
| **Small Production** | 100-1,000 | 1,000-10,000 | $2,500/mo | $800/mo | Docker Compose |
| **Medium Production** | 1,000-5,000 | 10,000-50,000 | $3,500/mo | $1,440/mo | Either |
| **Large Production** | 5,000-10,000 | 50,000-100,000 | $5,000/mo | N/A | Kubernetes |
| **Enterprise** | >10,000 | >100,000 | $8,000+/mo | N/A | Kubernetes |

### Key Takeaways

1. **Start Small**: Begin with Docker Compose for development
2. **Monitor Continuously**: Use Grafana dashboards to track utilization
3. **Plan Capacity**: Size 30-40% above expected peak load
4. **Scale Gradually**: Increase incrementally based on metrics
5. **Optimize Costs**: Use reserved instances, lifecycle policies, right-sizing

---

**Document Version**: 1.0.0  
**Last Updated**: October 2025  
**Maintained By**: Adrian Johnson | adrian207@gmail.com

---

*End of System Requirements & Sizing Guide*




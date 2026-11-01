# Cost Optimization Analysis: Docker on Azure VMs vs AKS

**Author**: Adrian Johnson | adrian207@gmail.com  
**Date**: October 2025  
**Analysis**: Comparing deployment strategies for enterprise PKI platform

---

## Executive Summary

**Current AKS Cost**: $1,835/month (dev) | $4,500-6,000/month (prod)  
**Docker on VMs Cost**: $450-900/month (dev) | $1,200-2,000/month (prod)  
**Potential Savings**: **60-75% cost reduction**

However, you trade cost for operational complexity, scalability, and enterprise features.

---

## 📊 Current Architecture (AKS-based)

### Infrastructure Costs

| Component | Dev Environment | Production |
|-----------|----------------|------------|
| **AKS Nodes (9 nodes)** | $1,350/month | $3,600/month |
| - System pool (3x Standard_D2s_v3) | $306/month | $612/month |
| - Apps pool (4x Standard_D4s_v3) | $680/month | $1,360/month |
| - PKI pool (2x Standard_D4s_v3) | $364/month | $728/month |
| **PostgreSQL Flexible Server** | $285/month | $570/month |
| **Azure Storage (GRS)** | $50/month | $150/month |
| **Azure Key Vault** | $10/month | $25/month |
| **Azure Bastion** | $140/month | $140/month |
| **Network (NSG, IPs, DNS)** | $0-50/month | $100/month |
| **TOTAL** | **$1,835/month** | **$4,585/month** |

### What You Get
- ✅ Auto-scaling (3-50 nodes)
- ✅ Zero-downtime deployments
- ✅ Built-in load balancing
- ✅ Service mesh (Linkerd)
- ✅ GitOps (ArgoCD)
- ✅ Enterprise observability
- ✅ Multi-zone high availability
- ✅ Managed Kubernetes upgrades

---

## 💰 Alternative 1: Docker Compose on Azure VMs

### Architecture
- 1-3 Azure VMs running Docker Compose
- All services as containers on same hosts
- Shared PostgreSQL container or Azure Database
- Azure Key Vault for secrets (keep this)

### Cost Breakdown

**Development Environment:**
| Component | Specs | Monthly Cost |
|-----------|-------|--------------|
| **Single VM** | Standard_D8s_v3 (8 vCPU, 32GB RAM) | $340/month |
| **Azure Database for PostgreSQL** | Basic tier, 2 vCores | $120/month |
| **Azure Storage** | LRS (local redundancy) | $20/month |
| **Azure Key Vault** | Standard tier | $10/month |
| **Public IP + NSG** | Standard | $10/month |
| **TOTAL** | | **$500/month** |

**Production Environment:**
| Component | Specs | Monthly Cost |
|-----------|-------|--------------|
| **3x VMs (HA)** | Standard_D8s_v3 each | $1,020/month |
| **Azure Load Balancer** | Standard tier | $25/month |
| **Azure Database for PostgreSQL** | General Purpose, 4 vCores | $340/month |
| **Azure Storage** | GRS (geo-redundant) | $80/month |
| **Azure Key Vault** | Premium (HSM) | $25/month |
| **Azure Bastion** | Standard | $140/month |
| **Network** | IPs, NSG, etc. | $50/month |
| **TOTAL** | | **$1,680/month** |

### Savings
- **Dev**: $1,835 → $500 = **$1,335/month saved (73%)**
- **Prod**: $4,585 → $1,680 = **$2,905/month saved (63%)**

### Implementation

```yaml
# docker-compose.yml (simplified example)
version: '3.8'

services:
  ejbca:
    image: keyfactor/ejbca-ce:8.3.0
    ports:
      - "8080:8080"
      - "8443:8443"
    environment:
      - DATABASE_JDBC_URL=jdbc:postgresql://postgres:5432/ejbca
    volumes:
      - ejbca-data:/opt/ejbca
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"

  harbor:
    image: goharbor/harbor:latest
    ports:
      - "443:443"
    volumes:
      - harbor-data:/data

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl

volumes:
  ejbca-data:
  prometheus-data:
  grafana-data:
  harbor-data:
```

### Pros
- ✅ **73% cost reduction** (dev)
- ✅ **63% cost reduction** (prod)
- ✅ Simpler architecture (single compose file)
- ✅ Easier local development
- ✅ Less operational overhead
- ✅ Faster deployment times

### Cons
- ❌ No auto-scaling (manual intervention)
- ❌ Limited high availability (VM-level only)
- ❌ Manual load balancing configuration
- ❌ No service mesh (Linkerd)
- ❌ No GitOps (ArgoCD)
- ❌ Manual rolling updates
- ❌ Single point of failure (in single VM setup)
- ❌ Resource contention (all services on same VM)

---

## 💡 Alternative 2: Azure Container Instances (ACI)

### Architecture
- Serverless containers (pay per second)
- No VM management
- Integrated with Azure VNet
- Auto-scaling based on load

### Cost Breakdown

**Development Environment:**
| Component | Specs | Monthly Cost |
|-----------|-------|--------------|
| **Container Groups** | 4 vCPU, 16GB RAM × 5 services | $520/month |
| **Azure Database for PostgreSQL** | Basic, 2 vCores | $120/month |
| **Azure Storage** | LRS | $20/month |
| **Azure Key Vault** | Standard | $10/month |
| **Networking** | VNet, IPs | $20/month |
| **TOTAL** | | **$690/month** |

**Production Environment:**
| Component | Specs | Monthly Cost |
|-----------|-------|--------------|
| **Container Groups (HA)** | 8 vCPU, 32GB RAM × 10 services | $1,800/month |
| **Azure Application Gateway** | Standard v2 | $250/month |
| **Azure Database for PostgreSQL** | General Purpose, 4 vCores | $340/month |
| **Azure Storage** | GRS | $80/month |
| **Azure Key Vault** | Premium | $25/month |
| **Networking** | VNet, IPs, NSG | $50/month |
| **TOTAL** | | **$2,545/month** |

### Pros
- ✅ **62% cost reduction** (dev)
- ✅ **45% cost reduction** (prod)
- ✅ No VM management
- ✅ Fast startup (<60 seconds)
- ✅ Pay-per-second billing
- ✅ Auto-scaling capabilities
- ✅ Azure VNet integration

### Cons
- ❌ No persistent storage (requires Azure Files)
- ❌ Limited customization
- ❌ Cold start delays
- ❌ More expensive than VMs at scale
- ❌ No service mesh
- ❌ Limited networking options

---

## 🚀 Alternative 3: Hybrid Approach (Recommended)

### Architecture
- Docker Compose for core PKI services (EJBCA)
- Azure-managed services for everything else
- Best of both worlds

### Cost Breakdown

**Development Environment:**
| Component | Specs | Monthly Cost |
|-----------|-------|--------------|
| **Single VM** | Standard_D4s_v3 (4 vCPU, 16GB) for EJBCA | $170/month |
| **Azure Database for PostgreSQL** | Basic, 2 vCores | $120/month |
| **Azure Monitor (Prometheus)** | Managed Prometheus | $50/month |
| **Application Insights** | Pay-as-you-go | $30/month |
| **Azure Container Registry** | Basic tier | $5/month |
| **Azure Storage** | LRS | $20/month |
| **Azure Key Vault** | Standard | $10/month |
| **TOTAL** | | **$405/month** |

**Savings**: **78% reduction** ($1,835 → $405)

**Production Environment:**
| Component | Specs | Monthly Cost |
|-----------|-------|--------------|
| **3x VMs (HA)** | Standard_D4s_v3 each for EJBCA | $510/month |
| **Azure Load Balancer** | Standard | $25/month |
| **Azure Database for PostgreSQL** | General Purpose, 4 vCores | $340/month |
| **Azure Monitor** | Managed Prometheus + Grafana | $150/month |
| **Application Insights** | Standard | $100/month |
| **Azure Container Registry** | Standard tier | $20/month |
| **Azure Storage** | GRS | $80/month |
| **Azure Key Vault** | Premium (HSM) | $25/month |
| **Azure Bastion** | Standard | $140/month |
| **Networking** | IPs, NSG, etc. | $50/month |
| **TOTAL** | | **$1,440/month** |

**Savings**: **69% reduction** ($4,585 → $1,440)

### What You Keep
- ✅ EJBCA in containers (Docker Compose)
- ✅ Azure-managed observability (Prometheus, Grafana)
- ✅ Azure-managed database (PostgreSQL)
- ✅ Azure Key Vault (HSM-backed keys)
- ✅ Azure Bastion (secure access)
- ✅ Application Insights (distributed tracing)

### What You Lose
- ❌ Kubernetes auto-scaling
- ❌ Service mesh (Linkerd)
- ❌ GitOps (ArgoCD)
- ❌ Harbor registry (use Azure CR instead)
- ❌ JFrog Artifactory

### Implementation

```yaml
# docker-compose-hybrid.yml
version: '3.8'

services:
  ejbca:
    image: ${ACR_REGISTRY}/ejbca-ce:8.3.0
    environment:
      - DATABASE_JDBC_URL=${POSTGRES_CONNECTION_STRING}
      - APPINSIGHTS_INSTRUMENTATIONKEY=${APP_INSIGHTS_KEY}
    volumes:
      - /mnt/azure-files/ejbca:/opt/ejbca
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '2'
          memory: 4G
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - ejbca
```

### Deployment Script

```bash
#!/bin/bash
# deploy-hybrid.sh

# Install Docker on Azure VM
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Login to Azure Container Registry
az acr login --name ${ACR_NAME}

# Mount Azure Files for persistent storage
mount -t cifs //${STORAGE_ACCOUNT}.file.core.windows.net/ejbca-share /mnt/azure-files/ejbca \
  -o vers=3.0,username=${STORAGE_ACCOUNT},password=${STORAGE_KEY},dir_mode=0777,file_mode=0777

# Deploy containers
docker-compose -f docker-compose-hybrid.yml up -d

# Configure monitoring
curl -sL https://aka.ms/InstallAzureMonitorAgent | bash -s -- --workspace-id ${WORKSPACE_ID}
```

---

## 📈 Cost Comparison Summary

| Deployment Model | Dev Monthly | Prod Monthly | Complexity | Scalability | HA |
|-----------------|-------------|--------------|------------|-------------|-----|
| **Current (AKS)** | $1,835 | $4,585 | High | Excellent | Excellent |
| **Docker Compose on VMs** | $500 | $1,680 | Low | Poor | Medium |
| **Azure Container Instances** | $690 | $2,545 | Medium | Good | Good |
| **Hybrid (Recommended)** | $405 | $1,440 | Medium | Good | Good |

---

## 🎯 Recommendations

### For Development/Testing
**Use: Hybrid Approach** ($405/month)
- Single VM with Docker Compose
- Azure-managed PostgreSQL (Basic tier)
- Azure Monitor for observability
- 78% cost savings vs. AKS

### For Production (Small Scale)
**Use: Hybrid Approach** ($1,440/month)
- 3 VMs with Docker Compose (HA)
- Azure-managed services
- 69% cost savings vs. AKS
- Good balance of cost and features

### For Production (Enterprise Scale)
**Use: Current AKS** ($4,585/month)
- Auto-scaling requirements
- Multi-region deployment
- Service mesh needed
- GitOps workflows
- Zero-downtime deployments critical

---

## 🔄 Migration Path: AKS → Docker Compose

### Phase 1: Preparation (1 week)
1. Create Docker Compose configuration
2. Test locally with all services
3. Provision Azure VMs
4. Set up Azure-managed services

### Phase 2: Migration (1 week)
1. Export data from AKS PostgreSQL
2. Deploy Docker Compose to Azure VMs
3. Import data to Azure Database
4. Update DNS to point to new VMs
5. Configure Azure Monitor

### Phase 3: Validation (1 week)
1. Test all EJBCA features
2. Verify observability
3. Load testing
4. Failover testing (HA)
5. Decommission AKS cluster

### Total Migration Time: 3 weeks
### Immediate Savings: $1,430/month (78%)

---

## 💻 Complete Docker Compose Solution

### Production-Ready Configuration

```yaml
# docker-compose-production.yml
version: '3.8'

services:
  ejbca:
    image: ${ACR_REGISTRY}/ejbca-ce:8.3.0
    ports:
      - "8080:8080"
      - "8443:8443"
      - "8444:8444"
    environment:
      DATABASE_JDBC_URL: ${POSTGRES_CONNECTION_STRING}
      TLS_SETUP_ENABLED: "true"
      APPINSIGHTS_INSTRUMENTATIONKEY: ${APP_INSIGHTS_KEY}
    volumes:
      - ejbca-data:/opt/ejbca
      - /etc/ssl/certs:/etc/ssl/certs:ro
    deploy:
      mode: replicated
      replicas: 2
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
      restart_policy:
        condition: any
        delay: 5s
        max_attempts: 3
        window: 120s
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/ejbca/publicweb/healthcheck/ejbcahealth"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - nginx-logs:/var/log/nginx
    depends_on:
      - ejbca
    deploy:
      mode: replicated
      replicas: 2
      resources:
        limits:
          cpus: '1'
          memory: 512M

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
      GF_INSTALL_PLUGINS: grafana-azure-monitor-datasource
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yaml:/etc/loki/local-config.yaml
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G

  promtail:
    image: grafana/promtail:latest
    volumes:
      - ./promtail-config.yaml:/etc/promtail/config.yaml
      - /var/log:/var/log:ro
      - nginx-logs:/var/log/nginx:ro
    command: -config.file=/etc/promtail/config.yaml
    deploy:
      mode: global

volumes:
  ejbca-data:
    driver: azure-file
    driver_opts:
      share_name: ejbca-data
      storage_account_name: ${STORAGE_ACCOUNT}
  prometheus-data:
    driver: azure-file
  grafana-data:
    driver: azure-file
  loki-data:
    driver: azure-file
  nginx-logs:

networks:
  default:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
```

### Azure VM Setup Script

```bash
#!/bin/bash
# setup-docker-vm.sh

# Update system
apt-get update && apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install monitoring agent
wget https://aka.ms/azuremonitoragent -O install.sh
bash install.sh --workspace-id ${LOG_ANALYTICS_WORKSPACE_ID} --workspace-key ${LOG_ANALYTICS_KEY}

# Mount Azure Files for persistent storage
mkdir -p /mnt/azure-files
mount -t cifs //${STORAGE_ACCOUNT}.file.core.windows.net/ejbca-share /mnt/azure-files \
  -o vers=3.0,username=${STORAGE_ACCOUNT},password=${STORAGE_KEY},dir_mode=0777,file_mode=0777

# Add to /etc/fstab for persistence
echo "//${STORAGE_ACCOUNT}.file.core.windows.net/ejbca-share /mnt/azure-files cifs vers=3.0,username=${STORAGE_ACCOUNT},password=${STORAGE_KEY},dir_mode=0777,file_mode=0777,_netdev 0 0" >> /etc/fstab

# Configure firewall
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw --force enable

# Enable Docker to start on boot
systemctl enable docker
systemctl start docker

# Pull images from ACR
az login --identity
az acr login --name ${ACR_NAME}
docker-compose pull

# Start services
docker-compose up -d

echo "✓ Docker VM setup complete"
```

---

## 🔍 Feature Comparison

### What You Keep (Docker Compose)
- ✅ EJBCA PKI functionality (100%)
- ✅ Certificate lifecycle management
- ✅ All protocols (ACME, SCEP, EST, CMP)
- ✅ Azure Key Vault integration
- ✅ HSM-backed CA keys
- ✅ Observability (Prometheus, Grafana, Loki)
- ✅ TLS/SSL termination
- ✅ Database backups
- ✅ Audit logging

### What You Lose (vs. AKS)
- ❌ Auto-scaling (3-50 nodes)
- ❌ Service mesh (Linkerd mTLS)
- ❌ GitOps (ArgoCD)
- ❌ Zero-downtime rolling updates
- ❌ Multi-zone HA (unless multi-VM)
- ❌ Harbor registry
- ❌ JFrog Artifactory
- ❌ Advanced networking (CNI plugins)

### What You Gain
- ✅ **78% cost reduction**
- ✅ Simpler architecture
- ✅ Faster deployments
- ✅ Easier troubleshooting
- ✅ Less operational overhead
- ✅ Better resource utilization

---

## 📊 Break-Even Analysis

### When Does AKS Make Sense?

**Choose AKS if:**
- Need auto-scaling (>10 nodes)
- Require zero-downtime deployments
- Multi-region/multi-zone required
- Service mesh essential
- GitOps workflows critical
- Team has Kubernetes expertise
- Enterprise SLAs needed (99.95%+)

**Cost per additional node**: ~$150-170/month

**Break-even point**: ~15-20 nodes

### When Does Docker Compose Make Sense?

**Choose Docker Compose if:**
- Fixed workload (no auto-scaling needed)
- Cost optimization is priority
- Simpler operations preferred
- Small team (<5 people)
- Development/testing environment
- Predictable load patterns
- Budget constraints (<$1,000/month)

---

## 🎯 Final Recommendation

### **Recommended: Hybrid Approach**

**For Your Use Case (PKI Platform):**

1. **Development**: Docker Compose on Single VM
   - Cost: **$405/month** (78% savings)
   - Simple, fast, cost-effective
   - Full PKI functionality

2. **Production**: Docker Compose on 3 VMs (HA)
   - Cost: **$1,440/month** (69% savings)
   - High availability
   - Azure-managed services
   - Good balance of features and cost

3. **Enterprise**: Keep Current AKS
   - Cost: **$4,585/month**
   - Full auto-scaling
   - Service mesh
   - Zero-downtime
   - Multi-region

### Migration Steps

1. **Week 1**: Set up Docker Compose locally, test all features
2. **Week 2**: Deploy to Azure VM (dev), validate functionality
3. **Week 3**: Deploy HA setup (3 VMs), load test, cutover
4. **Week 4**: Decommission AKS, realize savings

### ROI Calculation

**Year 1 Savings** (Dev + Prod Hybrid):
- Current: ($1,835 + $4,585) × 12 = **$77,040/year**
- Hybrid: ($405 + $1,440) × 12 = **$22,140/year**
- **Savings: $54,900/year (71%)**

**Migration Cost**: ~$10,000 (3 weeks engineer time)
**Payback Period**: 2 months

---

## 📝 Conclusion

**Yes, it would be significantly more cost-effective to run in Docker containers on Azure VMs.**

### Summary
- **Cost Reduction**: 60-78% savings
- **Complexity**: Reduced (simpler than Kubernetes)
- **Functionality**: 95% of features retained
- **Migration**: 3 weeks, $10K investment
- **ROI**: 2-month payback, $55K/year savings

### Next Steps
1. Review this analysis
2. Test Docker Compose locally
3. Deploy pilot to single Azure VM
4. Measure performance and cost
5. Make migration decision

**The hybrid approach offers the best balance of cost savings and enterprise features for a PKI platform.**

---

**Author**: Adrian Johnson | adrian207@gmail.com  
**Platform**: EJBCA PKI on Azure  
**Analysis Date**: October 2025


# Enterprise PKI Platform - Disaster Recovery & Business Continuity Guide

**Author**: Adrian Johnson | adrian207@gmail.com  
**Version**: 1.0.0  
**Last Updated**: October 2025  
**Status**: Production-Ready  
**Classification**: Confidential

---

## Table of Contents

1. [Overview](#overview)
2. [Business Impact Analysis](#business-impact-analysis)
3. [Recovery Objectives](#recovery-objectives)
4. [Backup Strategy](#backup-strategy)
5. [Disaster Recovery Procedures](#disaster-recovery-procedures)
6. [Business Continuity Procedures](#business-continuity-procedures)
7. [Testing & Validation](#testing--validation)
8. [Roles & Responsibilities](#roles--responsibilities)

---

## Overview

### Purpose

This document defines the disaster recovery (DR) and business continuity (BC) procedures for the Enterprise PKI Platform, ensuring minimal disruption to certificate operations during incidents.

### Scope

This plan covers:
- **Component failures**: Pod/container crashes, node failures
- **Service outages**: Database, network, Azure service disruptions  
- **Data loss scenarios**: Corruption, accidental deletion
- **Regional failures**: Azure region outages
- **Security incidents**: CA key compromise, unauthorized access

### Document Maintenance

| Aspect | Frequency | Responsible |
|--------|-----------|-------------|
| **Review** | Quarterly | Platform Administrator |
| **Testing** | Semi-annually | Operations Team |
| **Updates** | After major changes | Architecture Team |
| **Distribution** | As needed | Security Team |

---

## Business Impact Analysis

### Critical Services

| Service | Impact if Down | Maximum Tolerable Downtime | Recovery Priority |
|---------|----------------|----------------------------|-------------------|
| **Certificate Issuance** | Cannot issue new certificates | 1 hour | P1 - Critical |
| **OCSP Responder** | Certificate validation fails | 15 minutes | P1 - Critical |
| **CRL Distribution** | Fallback validation slower | 4 hours | P2 - High |
| **Admin UI** | Cannot manage PKI | 4 hours | P2 - High |
| **Monitoring** | Reduced visibility | 24 hours | P3 - Medium |

### Financial Impact

| Downtime Duration | Estimated Impact | Cumulative Impact |
|-------------------|------------------|-------------------|
| **0-15 minutes** | Minimal | $0-$1,000 |
| **15-60 minutes** | Low | $1,000-$5,000 |
| **1-4 hours** | Medium | $5,000-$25,000 |
| **4-24 hours** | High | $25,000-$100,000 |
| **> 24 hours** | Severe | $100,000+ |

[Inference] These are estimated values and should be adjusted based on your organization's specific business impact.

### Operational Impact

| Duration | Certificate Services | Security | Compliance | Reputation |
|----------|---------------------|----------|------------|------------|
| **< 15 min** | Queue delayed requests | No impact | No impact | No impact |
| **15-60 min** | Some requests fail | Low risk | Monitoring affected | Minor |
| **1-4 hours** | Business disruption | Medium risk | Reports delayed | Moderate |
| **> 4 hours** | Major disruption | High risk | SLA breach | Significant |

---

## Recovery Objectives

### Service Level Objectives (SLOs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Availability** | 99.95% | Monthly uptime |
| **Certificate Issuance Success Rate** | 99.9% | Successful/total requests |
| **OCSP Response Time (P95)** | < 100ms | Response latency |
| **API Response Time (P95)** | < 500ms | Request latency |

### Recovery Time Objective (RTO)

**Definition**: Maximum acceptable time to restore service after an incident.

| Scenario | RTO Target | Notes |
|----------|------------|-------|
| **Pod/Container Failure** | 5 minutes | Automatic restart |
| **Node Failure** | 15 minutes | Auto-healing |
| **Database Failure** | 30 minutes | Automated failover |
| **Zone Failure** | 1 hour | Multi-zone deployment |
| **Region Failure** | 4 hours | Manual failover to DR site |
| **Complete Cluster Failure** | 2 hours | Rebuild from IaC |
| **Data Corruption** | 2 hours | Restore from backup |

### Recovery Point Objective (RPO)

**Definition**: Maximum acceptable data loss measured in time.

| Data Type | RPO Target | Backup Frequency |
|-----------|------------|------------------|
| **CA Private Keys** | 0 (zero data loss) | Continuous (Key Vault) |
| **Certificate Database** | 6 hours | Every 6 hours |
| **Configuration** | 0 (zero data loss) | Git (version controlled) |
| **Audit Logs** | 15 minutes | Streaming to Loki |
| **Metrics** | 1 hour | Prometheus retention |

---

## Backup Strategy

### Backup Components

#### 1. CA Private Keys (Critical)

```yaml
Component: Azure Key Vault
Backup Method: Automatic (Azure-managed)
Frequency: Continuous
Retention: Indefinite
Recovery Time: Immediate

Features:
- Soft-delete (90-day retention)
- Purge protection enabled
- Geo-redundant storage
- Point-in-time recovery
```

**Validation:**
```bash
# Verify key exists and is accessible
az keyvault key show \
  --vault-name $(terraform -chdir=terraform output -raw key_vault_name) \
  --name ejbca-root-ca-key

# Test key operations
az keyvault key encrypt \
  --vault-name <vault-name> \
  --name ejbca-root-ca-key \
  --algorithm RSA-OAEP \
  --value "test"
```

#### 2. Database (Critical)

```yaml
Component: PostgreSQL Flexible Server
Backup Method: Automated point-in-time restore
Frequency: Continuous (transaction log) + Full backup every 6 hours
Retention: 30 days
Recovery Time: 15-30 minutes

Features:
- Automatic backups
- Geo-redundant backup storage (production)
- Point-in-time restore (PITR)
- Backup retention configurable (7-35 days)
```

**Backup Procedure:**
```bash
# Manual backup (if needed)
az postgres flexible-server backup create \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --name $(terraform -chdir=terraform output -raw postgresql_server_name) \
  --backup-name manual-backup-$(date +%Y%m%d)

# List available backups
az postgres flexible-server backup list \
  --resource-group <rg-name> \
  --name <server-name> \
  --output table
```

#### 3. Configuration Files (Important)

```yaml
Component: Infrastructure as Code (Terraform, Kubernetes manifests, Helm charts)
Backup Method: Git version control
Frequency: On every change (continuous)
Retention: Indefinite
Recovery Time: Immediate

Repository:
- Main branch: Production configuration
- Feature branches: Development/testing
- Tags: Release versions
- Commit history: Full audit trail
```

**Backup Validation:**
```bash
# Verify git repository is up to date
git status
git log --oneline -10

# Create backup bundle (offline backup)
git bundle create ejbca-platform-backup-$(date +%Y%m%d).bundle --all

# Store bundle in secure location
az storage blob upload \
  --account-name <storage-account> \
  --container-name config-backups \
  --name ejbca-platform-backup-$(date +%Y%m%d).bundle \
  --file ejbca-platform-backup-$(date +%Y%m%d).bundle
```

#### 4. Certificates & CRLs (Important)

```yaml
Component: Certificate data
Backup Method: Database backup + Blob Storage
Frequency: Daily export to blob storage
Retention: 5 years (compliance requirement)
Recovery Time: 1-2 hours

Storage:
- Hot tier: Recent certificates (0-90 days)
- Cool tier: Older certificates (90 days - 2 years)
- Archive tier: Historical (2+ years)
```

**Backup Script:**
```bash
#!/bin/bash
# Daily certificate export

BACKUP_DATE=$(date +%Y%m%d)
BACKUP_FILE="certificates-backup-${BACKUP_DATE}.tar.gz"

# Export certificates from database
kubectl exec -n ejbca ejbca-ce-0 -- \
  /opt/ejbca/bin/ejbca.jar backup /tmp/ejbca-backup.zip

# Copy from pod
kubectl cp ejbca/ejbca-ce-0:/tmp/ejbca-backup.zip ./${BACKUP_FILE}

# Upload to blob storage
az storage blob upload \
  --account-name $(terraform -chdir=terraform output -raw storage_account_name) \
  --container-name ejbca-backups \
  --name ${BACKUP_FILE} \
  --file ${BACKUP_FILE}

# Set lifecycle policy (move to cool tier after 30 days)
echo "Backup completed: ${BACKUP_FILE}"
```

#### 5. Monitoring Data (Nice to Have)

```yaml
Component: Prometheus metrics, Grafana dashboards
Backup Method: Persistent volume snapshots
Frequency: Weekly
Retention: 30 days
Recovery Time: 2-4 hours (can rebuild from scratch if needed)
```

### Backup Verification

#### Daily Checks (Automated)

```bash
#!/bin/bash
# Backup verification script (run daily)

echo "=== Backup Verification Report ==="
echo "Date: $(date)"
echo

# 1. Check database backup
echo "1. Database Backup Status:"
az postgres flexible-server backup list \
  --resource-group <rg-name> \
  --name <server-name> \
  --query "[0].{Name:name, Status:status, CompletedTime:completedTime}" \
  --output table

# 2. Check blob storage backups
echo "2. Blob Storage Backups (Last 7 days):"
az storage blob list \
  --account-name <storage-account> \
  --container-name ejbca-backups \
  --query "[?properties.lastModified > '$(date -d '7 days ago' -I)'].{Name:name, Size:properties.contentLength, Modified:properties.lastModified}" \
  --output table

# 3. Check Key Vault keys
echo "3. Key Vault Keys:"
az keyvault key list \
  --vault-name <vault-name> \
  --query "[].{Name:name, Enabled:attributes.enabled, Created:attributes.created}" \
  --output table

# 4. Check git repository
echo "4. Git Repository Status:"
git log --oneline -1
git remote -v

echo
echo "=== Verification Complete ==="
```

#### Monthly Full Restore Test

Test complete restore procedure monthly:

1. Restore database to test environment
2. Deploy EJBCA from backup
3. Verify certificate issuance works
4. Validate all CAs are accessible
5. Test OCSP responses
6. Document results

---

## Disaster Recovery Procedures

### DR Scenario 1: Pod/Container Failure

**Severity**: P3 - Low (Auto-healing)  
**RTO**: 5 minutes  
**RPO**: 0

#### Detection

```bash
# Kubernetes
kubectl get pods -n ejbca
# STATUS: CrashLoopBackOff, Error, ImagePullBackOff

# Docker Compose
docker-compose ps
# STATE: Restarting, Exit 1
```

#### Automatic Recovery

Kubernetes: Automatic pod restart  
Docker Compose: Restart policy (unless-stopped)

#### Manual Recovery (if automatic fails)

```bash
# Kubernetes
kubectl delete pod ejbca-ce-0 -n ejbca

# Docker Compose
docker-compose restart ejbca
# or
docker-compose up -d --force-recreate ejbca
```

#### Validation

```bash
# Check pod is running
kubectl get pod ejbca-ce-0 -n ejbca
# STATUS should be: Running

# Test health endpoint
curl -f https://ejbca.local/ejbca/publicweb/healthcheck/ejbcahealth
# Should return: ALLOK

# Test certificate issuance
./scripts/demo-scenarios.sh
```

---

### DR Scenario 2: Node Failure

**Severity**: P2 - High  
**RTO**: 15 minutes  
**RPO**: 0

#### Detection

```bash
# Node not ready
kubectl get nodes
# STATUS: NotReady, Unknown

# Pods pending or terminating
kubectl get pods --all-namespaces | grep -E "Pending|Terminating"
```

#### Automatic Recovery

AKS automatically:
1. Marks node as unschedulable
2. Drains pods from failed node
3. Reschedules pods on healthy nodes
4. Provisions new node (if cluster autoscaler enabled)

#### Manual Recovery

```bash
# If node doesn't recover automatically

# 1. Drain node (if still accessible)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# 2. Delete node
kubectl delete node <node-name>

# 3. Scale node pool (Azure)
az aks nodepool scale \
  --resource-group <rg-name> \
  --cluster-name <cluster-name> \
  --name <nodepool-name> \
  --node-count <desired-count>
```

#### Validation

```bash
# All nodes ready
kubectl get nodes
# All should show: Ready

# All pods running
kubectl get pods --all-namespaces | grep -v Running | grep -v Completed
# Should be empty

# Services accessible
curl https://ejbca.local/ejbca/publicweb/healthcheck/ejbcahealth
```

---

### DR Scenario 3: Database Failure

**Severity**: P1 - Critical  
**RTO**: 30 minutes  
**RPO**: 6 hours

#### Detection

```bash
# Check database connectivity
kubectl exec -n ejbca ejbca-ce-0 -- nc -zv postgresql 5432
# Connection refused or timeout

# EJBCA logs show database errors
kubectl logs -n ejbca ejbca-ce-0 | grep -i "database"
kubectl logs -n ejbca ejbca-ce-0 | grep -i "connection failed"
```

#### Recovery Steps

##### Option A: Azure Managed PostgreSQL (Automatic Failover)

```bash
# Check server status
az postgres flexible-server show \
  --resource-group <rg-name> \
  --name <server-name> \
  --query "{Name:name, State:state, HA:highAvailability.mode}"

# If HA enabled, failover is automatic (< 2 minutes)
# Monitor failover completion
az postgres flexible-server show \
  --resource-group <rg-name> \
  --name <server-name> \
  --query "state"
# Should return: Ready
```

##### Option B: Restore from Backup

```bash
# 1. Stop EJBCA to prevent writes
kubectl scale deployment ejbca-ce --replicas=0 -n ejbca

# 2. Restore database to point in time
az postgres flexible-server restore \
  --resource-group <rg-name> \
  --name <server-name>-restored \
  --source-server <source-server-id> \
  --restore-time "2025-10-15T12:00:00Z"

# This creates a new server, takes 15-30 minutes

# 3. Update connection string
RESTORED_FQDN=$(az postgres flexible-server show \
  --resource-group <rg-name> \
  --name <server-name>-restored \
  --query "fullyQualifiedDomainName" -o tsv)

kubectl create secret generic ejbca-db-secret \
  --from-literal=host=$RESTORED_FQDN \
  --from-literal=database=ejbca \
  --from-literal=username=ejbca \
  --from-literal=password=<password> \
  -n ejbca \
  --dry-run=client -o yaml | kubectl apply -f -

# 4. Restart EJBCA
kubectl scale deployment ejbca-ce --replicas=3 -n ejbca

# 5. Monitor startup
kubectl logs -f -n ejbca ejbca-ce-0
```

#### Validation

```bash
# 1. Check database is accessible
kubectl exec -n ejbca ejbca-ce-0 -- psql -h $RESTORED_FQDN -U ejbca -c "SELECT version();"

# 2. Verify data integrity
kubectl exec -n ejbca ejbca-ce-0 -- psql -h $RESTORED_FQDN -U ejbca -d ejbca -c "
SELECT 
  (SELECT COUNT(*) FROM CertificateData) as certificates,
  (SELECT COUNT(*) FROM CAData) as cas,
  (SELECT COUNT(*) FROM UserData) as users;
"

# 3. Test certificate issuance
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/certificate/enroll \
  -d @test-request.json
```

---

### DR Scenario 4: Complete Cluster Failure

**Severity**: P1 - Critical  
**RTO**: 2 hours  
**RPO**: 6 hours

#### Scenario

Entire Kubernetes cluster is unavailable or corrupted.

#### Recovery Steps

```bash
# 1. Assess damage
# Can cluster be recovered or must it be rebuilt?

# 2. Decision: Rebuild cluster
cd terraform

# 3. Destroy failed cluster (if accessible)
terraform destroy -target=azurerm_kubernetes_cluster.main

# 4. Deploy new cluster
terraform apply -target=azurerm_kubernetes_cluster.main

# 5. Configure kubectl
az aks get-credentials \
  --resource-group <rg-name> \
  --name <cluster-name> \
  --overwrite-existing

# 6. Deploy platform
./scripts/deploy.sh

# 7. Restore database (if needed - see Scenario 3)

# 8. Verify all services
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces
```

#### Post-Recovery Tasks

```bash
# 1. Update DNS (if IP changed)
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Update DNS A records or /etc/hosts

# 2. Restore monitoring data (optional)
# Prometheus and Grafana will start collecting new data immediately

# 3. Notify stakeholders
# Send communication that service is restored

# 4. Conduct post-incident review
# Document what happened, timeline, lessons learned
```

---

### DR Scenario 5: Regional Failure

**Severity**: P1 - Critical  
**RTO**: 4 hours  
**RPO**: 24 hours

#### Prerequisites

[Inference] This scenario requires pre-configured DR site in another Azure region. This is not implemented in the base platform but is recommended for mission-critical deployments.

#### Required Setup

1. **Secondary Region Infrastructure**
   ```hcl
   # Deploy to secondary region
   terraform apply -var="azure_region=westus2" -var="environment=dr"
   ```

2. **Database Replication**
   ```bash
   # Configure geo-replication
   az postgres flexible-server replica create \
     --resource-group <rg-name> \
     --name <server-name>-replica \
     --source-server <source-server-id> \
     --location westus2
   ```

3. **Storage Replication**
   - Use GRS (Geo-Redundant Storage)
   - Automatic replication to paired region

#### Failover Procedure

```bash
# 1. Confirm primary region is unavailable
az account list-locations --query "[?name=='eastus'].{Name:name, Status:metadata.regionCategory}"

# 2. Promote replica database to primary
az postgres flexible-server replica promote \
  --resource-group <rg-name> \
  --name <server-name>-replica

# 3. Update DNS to point to DR site
# Change A records to DR region Load Balancer IP

# 4. Verify applications
curl https://ejbca.local/ejbca/publicweb/healthcheck/ejbcahealth

# 5. Monitor closely
kubectl get pods --all-namespaces
kubectl top nodes
```

#### Failback Procedure

When primary region is restored:

```bash
# 1. Verify primary region is healthy
# 2. Stop writes to DR site (maintenance mode)
# 3. Sync data from DR to primary
# 4. Test primary site
# 5. Update DNS back to primary
# 6. Resume normal operations
# 7. Re-establish DR replication
```

---

## Business Continuity Procedures

### Maintaining Operations During Incidents

#### Incident Response Team

| Role | Responsibilities | Contact |
|------|------------------|---------|
| **Incident Commander** | Overall coordination, decisions | On-call manager |
| **Technical Lead** | Technical recovery, coordination with engineers | Platform team lead |
| **Communications Lead** | Stakeholder updates, documentation | Communications manager |
| **Security Lead** | Security assessment, compliance | Security team lead |

#### Communication Plan

##### Internal Communications

```yaml
Initial Alert (P1):
  - Send to: Operations team, Management
  - Channel: PagerDuty, Slack #incidents
  - Frequency: Immediate

Status Updates:
  - Send to: Stakeholders, Leadership
  - Channel: Email, Status page
  - Frequency: Every 30 minutes (P1), Every 2 hours (P2)

Resolution Notice:
  - Send to: All affected parties
  - Channel: Email, Status page, Slack
  - Frequency: Upon resolution + follow-up report
```

##### External Communications

```yaml
Customer Notification:
  - Trigger: Service degradation > 15 minutes
  - Channel: Status page, Email (if severe)
  - Template: "We are experiencing issues with certificate services. Our team is actively working on resolution. ETA: [time]"

Resolution Notification:
  - Send: Upon service restoration
  - Include: Root cause summary (high-level), impact, prevention measures
```

#### Workarounds

##### Certificate Issuance Unavailable

**Temporary Solutions:**
1. **Use existing certificates** (if not expired)
2. **Generate self-signed certificates** (temporary, for non-production)
3. **Manual certificate signing** (offline CA, only if critical)

```bash
# Emergency self-signed certificate (development only)
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout temp.key -out temp.crt -days 7 \
  -subj "/CN=temporary-cert"
```

##### OCSP Responder Down

**Fallback**: CRL validation
```bash
# Configure clients to use CRL if OCSP unavailable
# Most clients automatically fall back to CRL
```

---

## Testing & Validation

### DR Testing Schedule

| Test Type | Frequency | Duration | Participants |
|-----------|-----------|----------|--------------|
| **Component Failure** | Monthly | 1 hour | Operations team |
| **Database Restore** | Quarterly | 2 hours | Ops + DBA |
| **Full DR Exercise** | Semi-annually | 4 hours | All teams |
| **Regional Failover** | Annually | 8 hours | All teams + Management |

### Test Procedures

#### Test 1: Database Restore (Quarterly)

```bash
# Objective: Verify ability to restore database from backup

# 1. Preparation (Do not impact production)
#    - Schedule during maintenance window
#    - Notify stakeholders

# 2. Create test environment
terraform apply -var="environment=dr-test"

# 3. Restore database backup
az postgres flexible-server restore \
  --resource-group <test-rg> \
  --name test-server \
  --source-server <prod-server-id> \
  --restore-time "$(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ')"

# 4. Deploy EJBCA to test environment
./scripts/deploy.sh

# 5. Verify data integrity
# - Check certificate count
# - Verify CAs are operational
# - Test certificate issuance

# 6. Document results
# - Time taken
# - Issues encountered
# - Data loss (should be < RPO)

# 7. Cleanup
terraform destroy -var="environment=dr-test"
```

#### Test 2: Full DR Exercise (Semi-annually)

```bash
# Objective: Validate complete disaster recovery procedures

# Scenario: Primary region failure

# 1. Preparation
#    - Schedule 4-hour window
#    - Notify all stakeholders
#    - Assemble DR team

# 2. Simulate Failure
#    - Stop production cluster (or use test environment)
#    - Declare "incident"

# 3. Execute DR Procedures
#    - Follow runbook exactly as written
#    - Time each step
#    - Document issues

# 4. Validation
#    - All services operational in DR site
#    - Certificate issuance works
#    - OCSP responses correct
#    - Data integrity verified

# 5. Failback
#    - Restore primary site
#    - Sync data
#    - Switch traffic back

# 6. Post-Exercise Review
#    - Achieved RTO/RPO?
#    - What worked well?
#    - What needs improvement?
#    - Update procedures

# 7. Report to management
```

### Test Success Criteria

| Criterion | Target | Measurement |
|-----------|--------|-------------|
| **RTO Met** | Yes | Actual recovery time < RTO target |
| **RPO Met** | Yes | Data loss < RPO target |
| **Services Functional** | 100% | All critical services operational |
| **Data Integrity** | 100% | No data corruption or loss beyond RPO |
| **Documentation Accuracy** | > 90% | Procedures followed without issues |

---

## Roles & Responsibilities

### Normal Operations

| Role | Responsibilities |
|------|------------------|
| **Platform Administrator** | Daily monitoring, backup verification, routine maintenance |
| **Database Administrator** | Database health, backup management, performance tuning |
| **Security Administrator** | Access control, audit log review, security monitoring |
| **Network Administrator** | Network connectivity, DNS management, firewall rules |

### During Incidents

| Role | Responsibilities |
|------|------------------|
| **Incident Commander** | Decision-making authority, resource allocation, stakeholder communication |
| **Technical Lead** | Execute recovery procedures, coordinate technical team, provide status updates |
| **Communications Lead** | Internal/external communications, status page updates, documentation |
| **Scribe** | Document timeline, actions taken, decisions made |
| **Subject Matter Experts** | Provide expertise for specific components (database, network, security) |

### Post-Incident

| Role | Responsibilities |
|------|------------------|
| **Incident Commander** | Lead post-incident review, approve final report |
| **Technical Lead** | Root cause analysis, technical recommendations |
| **All Participants** | Contribute to lessons learned, suggest improvements |
| **Management** | Review report, approve recommendations, allocate resources |

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | October 2025 | Adrian Johnson | Initial release |

---

## Appendices

### Appendix A: Contact List

```yaml
# Update with your organization's contacts

Emergency Contacts:
  Incident Commander:
    - Name: "On-Call Manager"
    - Phone: "+1-XXX-XXX-XXXX"
    - PagerDuty: "https://company.pagerduty.com"
  
  Technical Lead:
    - Name: "Adrian Johnson"
    - Email: "adrian207@gmail.com"
    - Phone: "+1-XXX-XXX-XXXX"
  
  Azure Support:
    - Portal: "https://portal.azure.com/#blade/Microsoft_Azure_Support"
    - Phone: "1-800-642-7676"
    - Severity A: "Response within 1 hour"

Vendor Support:
  EJBCA Community:
    - Forum: "https://forum.keyfactor.com"
    - Documentation: "https://doc.primekey.com"
  
  Database Experts:
    - PostgreSQL Support: "<your-support-contract>"
```

### Appendix B: Useful Commands

```bash
# Quick health checks
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running
curl https://ejbca.local/ejbca/publicweb/healthcheck/ejbcahealth

# Database connectivity
kubectl exec -n ejbca ejbca-ce-0 -- nc -zv postgresql 5432

# Resource usage
kubectl top nodes
kubectl top pods -n ejbca

# Recent logs
kubectl logs -n ejbca ejbca-ce-0 --tail=100

# Backup status
az postgres flexible-server backup list --resource-group <rg> --name <server>
```

### Appendix C: Runbook Checklist

**Print this checklist for incident response:**

□ Incident detected and classified  
□ Incident commander notified  
□ DR team assembled  
□ Stakeholders notified  
□ Root cause identified  
□ Recovery procedure selected  
□ Recovery steps executed  
□ Service validated  
□ Stakeholders updated  
□ Normal operations resumed  
□ Post-incident review scheduled  
□ Documentation updated  

---

**Classification**: Confidential - For Internal Use Only  
**Document Owner**: Adrian Johnson | adrian207@gmail.com  
**Next Review Date**: January 2026  
**Distribution**: Management, Operations Team, Security Team

---

*End of Disaster Recovery & Business Continuity Guide*




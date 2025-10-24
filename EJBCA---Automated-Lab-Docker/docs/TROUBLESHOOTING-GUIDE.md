# Enterprise PKI Platform - Troubleshooting Guide

**Author**: Adrian Johnson | adrian207@gmail.com  
**Version**: 1.0.0  
**Last Updated**: October 2025  
**Status**: Production-Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Diagnostic Tools](#diagnostic-tools)
3. [Common Issues](#common-issues)
4. [Platform-Specific Issues](#platform-specific-issues)
5. [Performance Issues](#performance-issues)
6. [Security Issues](#security-issues)
7. [Integration Issues](#integration-issues)
8. [Emergency Procedures](#emergency-procedures)

---

## Overview

### How to Use This Guide

1. **Identify the symptom** from the table of contents
2. **Follow the diagnostic steps** to confirm the issue
3. **Apply the resolution** steps
4. **Verify the fix** using the validation commands
5. **Document the incident** for future reference

### Severity Levels

| Level | Description | Response Time | Example |
|-------|-------------|---------------|---------|
| **P1 - Critical** | Complete service outage | Immediate | EJBCA not responding, database down |
| **P2 - High** | Major functionality impaired | < 1 hour | Certificate issuance failing |
| **P3 - Medium** | Minor functionality impaired | < 4 hours | Slow response times |
| **P4 - Low** | Cosmetic or documentation | < 24 hours | UI display issue |

---

## Diagnostic Tools

### Essential Commands

#### Kubernetes Cluster

```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running

# Check specific namespace
kubectl get all -n ejbca
kubectl get events -n ejbca --sort-by='.lastTimestamp'

# View pod logs
kubectl logs -n ejbca ejbca-ce-0 --tail=100 -f
kubectl logs -n ejbca ejbca-ce-0 --previous  # Previous instance

# Describe resources
kubectl describe pod ejbca-ce-0 -n ejbca
kubectl describe deployment ejbca-ce -n ejbca
kubectl describe service ejbca-ce -n ejbca

# Check resource usage
kubectl top nodes
kubectl top pods -n ejbca
```

#### Docker Compose

```bash
# Check service status
docker-compose ps
docker-compose ps -a  # Include stopped containers

# View logs
docker-compose logs ejbca --tail=100 -f
docker-compose logs --tail=1000 > all-logs.txt

# Check resource usage
docker stats

# Inspect container
docker-compose inspect ejbca
docker-compose exec ejbca bash
```

#### Database

```bash
# Check database connectivity (Kubernetes)
kubectl exec -n ejbca ejbca-ce-0 -- psql -h postgresql -U ejbca -c "SELECT version();"

# Check active connections
kubectl exec -n database postgresql-0 -- psql -U postgres -c "
SELECT count(*) as active_connections,
       max_conn - count(*) as available_connections
FROM pg_stat_activity, 
     (SELECT setting::int as max_conn FROM pg_settings WHERE name='max_connections') mc;
"

# Check slow queries
kubectl exec -n database postgresql-0 -- psql -U postgres -c "
SELECT pid, now() - query_start as duration, query
FROM pg_stat_activity
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%'
ORDER BY duration DESC;
"

# Check database size
kubectl exec -n database postgresql-0 -- psql -U postgres -c "
SELECT pg_size_pretty(pg_database_size('ejbca'));
"
```

#### Network

```bash
# Test connectivity
curl -v https://ejbca.local/ejbca/publicweb/healthcheck/ejbcahealth
curl -I https://grafana.local

# Check DNS
nslookup ejbca.local
dig ejbca.local

# Check certificates
echo | openssl s_client -connect ejbca.local:443 -servername ejbca.local 2>/dev/null | openssl x509 -noout -dates

# Check ingress
kubectl get ingress -A
kubectl describe ingress ejbca-ingress -n ejbca
```

### Log Locations

| Component | Kubernetes | Docker Compose |
|-----------|------------|----------------|
| **EJBCA** | `kubectl logs -n ejbca ejbca-ce-0` | `docker-compose logs ejbca` |
| **PostgreSQL** | `kubectl logs -n database postgresql-0` | `docker-compose logs postgres` |
| **NGINX** | `kubectl logs -n ingress-nginx <pod>` | `docker-compose logs nginx` |
| **Prometheus** | `kubectl logs -n observability prometheus-0` | `docker-compose logs prometheus` |
| **Grafana** | `kubectl logs -n observability grafana-<pod>` | `docker-compose logs grafana` |

---

## Common Issues

### Issue 1: EJBCA Not Responding

#### Symptoms
- `502 Bad Gateway` error
- EJBCA health check fails
- Timeouts when accessing admin UI

#### Diagnosis

```bash
# Check if pods are running (Kubernetes)
kubectl get pods -n ejbca

# Check container status (Docker)
docker-compose ps ejbca

# Check logs for errors
kubectl logs -n ejbca ejbca-ce-0 --tail=100
# or
docker-compose logs ejbca --tail=100

# Check if database is accessible
kubectl exec -n ejbca ejbca-ce-0 -- psql -h postgresql -U ejbca -c "SELECT 1;"
```

#### Common Causes & Solutions

##### Cause 1: Pod/Container Crashed

```bash
# Check pod status
kubectl describe pod ejbca-ce-0 -n ejbca

# Look for:
# - OOMKilled (out of memory)
# - CrashLoopBackOff
# - Error state

# Solution: Restart pod
kubectl delete pod ejbca-ce-0 -n ejbca  # Kubernetes
docker-compose restart ejbca  # Docker
```

##### Cause 2: Out of Memory

```bash
# Check memory usage
kubectl top pod ejbca-ce-0 -n ejbca

# If near limit, increase resources
kubectl edit deployment ejbca-ce -n ejbca

# Change:
resources:
  limits:
    memory: 16Gi  # From 8Gi
  requests:
    memory: 8Gi   # From 4Gi
```

##### Cause 3: Database Connection Failed

```bash
# Check database connectivity
kubectl exec -n ejbca ejbca-ce-0 -- nc -zv postgresql 5432

# Check database credentials
kubectl get secret ejbca-db-secret -n ejbca -o yaml

# Verify database is running
kubectl get pods -n database
kubectl logs -n database postgresql-0 --tail=50

# Solution: Restart database connection
kubectl delete pod ejbca-ce-0 -n ejbca
```

##### Cause 4: WildFly Not Started

```bash
# Check WildFly logs
kubectl logs -n ejbca ejbca-ce-0 | grep "WildFly.*started"

# If not started, check for deployment errors
kubectl logs -n ejbca ejbca-ce-0 | grep "ERROR"

# Common issues:
# - Port already in use
# - Configuration error
# - Missing dependencies

# Solution: Check configuration and restart
kubectl delete pod ejbca-ce-0 -n ejbca
```

---

### Issue 2: Certificate Issuance Failing

#### Symptoms
- REST API returns error codes
- ACME challenges fail
- "Unable to issue certificate" errors

#### Diagnosis

```bash
# Check CA status via admin UI
# Navigate to: CA Functions → Certificate Authorities

# Check logs
kubectl logs -n ejbca ejbca-ce-0 | grep -i "certificate"
kubectl logs -n ejbca ejbca-ce-0 | grep -i "error"

# Test certificate issuance via curl
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/certificate/enroll \
  -d '{"certificate_request": "...", ...}'
```

#### Common Causes & Solutions

##### Cause 1: CA is Offline

```bash
# Diagnosis: Check CA status in admin UI
# CA Functions → Certificate Authorities → [CA Name]
# Status shows "Offline" or "Uninitialized"

# Solution: Activate CA
# In admin UI:
# 1. Select CA
# 2. Click "Edit"
# 3. Ensure "CA Status" is "Active"
# 4. Save changes
```

##### Cause 2: Key Vault Access Denied

```bash
# Check Key Vault access
kubectl logs -n ejbca ejbca-ce-0 | grep -i "keyvault"
kubectl logs -n ejbca ejbca-ce-0 | grep -i "unauthorized"

# Verify managed identity has access
az keyvault show \
  --name $(terraform -chdir=terraform output -raw key_vault_name) \
  --query properties.accessPolicies

# Solution: Grant access to managed identity
MANAGED_IDENTITY_PRINCIPAL_ID=$(kubectl get pods -n ejbca ejbca-ce-0 -o jsonpath='{.spec.serviceAccount}')

az keyvault set-policy \
  --name $(terraform -chdir=terraform output -raw key_vault_name) \
  --object-id $MANAGED_IDENTITY_PRINCIPAL_ID \
  --key-permissions get list sign unwrapKey wrapKey
```

##### Cause 3: Certificate Profile Misconfigured

```bash
# Diagnosis: Check certificate profile in admin UI
# CA Functions → Certificate Profiles → [Profile Name]

# Common misconfigurations:
# - Validity period too long/short
# - Key usage incorrect
# - Extended key usage missing

# Solution: Fix certificate profile
# 1. Edit profile in admin UI
# 2. Correct settings
# 3. Save and test
```

##### Cause 4: End Entity Does Not Exist

```bash
# Check if end entity exists
kubectl exec -n ejbca ejbca-ce-0 -- \
  /opt/ejbca/bin/ejbca.jar ra finduser --username testuser

# Solution: Create end entity first
# Either via REST API or admin UI
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/endentity \
  -d '{
    "username": "testuser",
    "password": "enrollment_password",
    ...
  }'
```

---

### Issue 3: Unable to Access Admin UI

#### Symptoms
- "Connection refused" error
- "404 Not Found" error
- Browser shows certificate warning

#### Diagnosis

```bash
# Check ingress configuration
kubectl get ingress -n ejbca
kubectl describe ingress ejbca-ingress -n ejbca

# Check service
kubectl get svc -n ejbca ejbca-ce

# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx <ingress-controller-pod>

# Test direct pod access
kubectl port-forward -n ejbca ejbca-ce-0 8443:8443
# Then access https://localhost:8443/ejbca/adminweb
```

#### Common Causes & Solutions

##### Cause 1: DNS Not Configured

```bash
# Check DNS resolution
nslookup ejbca.local
ping ejbca.local

# Solution: Add to /etc/hosts or configure DNS
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "$INGRESS_IP ejbca.local" | sudo tee -a /etc/hosts
```

##### Cause 2: Ingress Certificate Invalid

```bash
# Check certificate
echo | openssl s_client -connect ejbca.local:443 -servername ejbca.local 2>/dev/null | openssl x509 -noout -text

# Check cert-manager
kubectl get certificate -n ejbca
kubectl describe certificate ejbca-tls -n ejbca

# Solution: Renew certificate
kubectl delete secret ejbca-tls -n ejbca
kubectl delete certificate ejbca-tls -n ejbca
kubectl apply -f kubernetes/ejbca/ingress.yaml
```

##### Cause 3: Ingress Controller Not Running

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# If not running, redeploy
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -f kubernetes/ingress-nginx/values.yaml \
  -n ingress-nginx
```

---

### Issue 4: Database Connection Pool Exhausted

#### Symptoms
- "Connection pool exhausted" errors
- Slow certificate issuance
- Timeouts

#### Diagnosis

```bash
# Check active connections
kubectl exec -n database postgresql-0 -- psql -U postgres -c "
SELECT count(*) as connections, 
       (SELECT setting::int FROM pg_settings WHERE name='max_connections') as max_connections
FROM pg_stat_activity;
"

# Check connection age
kubectl exec -n database postgresql-0 -- psql -U postgres -c "
SELECT pid, usename, application_name, client_addr, 
       now() - backend_start as connection_age,
       state
FROM pg_stat_activity
WHERE datname = 'ejbca'
ORDER BY backend_start;
"
```

#### Solutions

##### Solution 1: Increase Max Connections

```bash
# Kubernetes with managed PostgreSQL
az postgres flexible-server parameter set \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --server-name $(terraform -chdir=terraform output -raw postgresql_server_name) \
  --name max_connections \
  --value 500

# Docker Compose
# Edit docker/docker-compose.yml:
postgres:
  command: postgres -c max_connections=500
```

##### Solution 2: Kill Idle Connections

```bash
# Kill connections idle for more than 1 hour
kubectl exec -n database postgresql-0 -- psql -U postgres -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'ejbca'
  AND state = 'idle'
  AND now() - state_change > interval '1 hour';
"
```

##### Solution 3: Configure Connection Pooling

```bash
# Edit EJBCA database configuration
kubectl edit configmap ejbca-config -n ejbca

# Add/modify:
data:
  database.properties: |
    datasource.pool.minSize=5
    datasource.pool.maxSize=100
    datasource.pool.timeout=30000

# Restart EJBCA
kubectl rollout restart deployment/ejbca-ce -n ejbca
```

---

### Issue 5: High Resource Usage

#### Symptoms
- Slow response times
- High CPU/memory usage
- Pod evictions

#### Diagnosis

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n ejbca

# Check for resource pressure
kubectl describe nodes | grep -A 5 "Allocated resources"

# Check for pod evictions
kubectl get events --all-namespaces | grep Evicted

# Check database queries
kubectl exec -n database postgresql-0 -- psql -U postgres -c "
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
"
```

#### Solutions

##### Solution 1: Increase Resource Limits

```bash
# Edit deployment
kubectl edit deployment ejbca-ce -n ejbca

# Increase resources:
resources:
  limits:
    cpu: 8000m     # From 4000m
    memory: 16Gi   # From 8Gi
  requests:
    cpu: 4000m     # From 2000m
    memory: 8Gi    # From 4Gi
```

##### Solution 2: Scale Horizontally

```bash
# Add more replicas
kubectl scale deployment ejbca-ce --replicas=5 -n ejbca

# Or enable autoscaling
kubectl autoscale deployment ejbca-ce \
  --cpu-percent=70 \
  --min=3 \
  --max=10 \
  -n ejbca
```

##### Solution 3: Optimize Database

```bash
# Run VACUUM and ANALYZE
kubectl exec -n database postgresql-0 -- vacuumdb -U postgres -d ejbca --analyze

# Update statistics
kubectl exec -n database postgresql-0 -- psql -U postgres -d ejbca -c "ANALYZE;"

# Add indexes if needed (consult DBA)
```

---

## Platform-Specific Issues

### Kubernetes-Specific Issues

#### Issue: ImagePullBackOff

```bash
# Diagnosis
kubectl describe pod ejbca-ce-0 -n ejbca | grep -A 10 "Events"

# Common causes:
# 1. Image doesn't exist
# 2. Registry authentication failed
# 3. Network issue

# Solution 1: Check image name
kubectl get deployment ejbca-ce -n ejbca -o jsonpath='{.spec.template.spec.containers[0].image}'

# Solution 2: Check image pull secrets
kubectl get secret -n ejbca
kubectl describe secret harbor-registry-secret -n ejbca

# Solution 3: Pull image manually to test
docker pull keyfactor/ejbca-ce:8.3.0
```

#### Issue: Persistent Volume Claim Pending

```bash
# Diagnosis
kubectl get pvc -n ejbca
kubectl describe pvc ejbca-data-pvc -n ejbca

# Common causes:
# 1. No storage class available
# 2. Insufficient storage
# 3. Zone mismatch

# Solution: Check storage class
kubectl get storageclass

# Create storage class if needed
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-premium
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
EOF
```

### Docker-Specific Issues

#### Issue: Container Keeps Restarting

```bash
# Check restart count
docker-compose ps

# Check logs
docker-compose logs ejbca --tail=200

# Check exit code
docker-compose ps -a | grep ejbca

# Common causes:
# 1. Out of memory
# 2. Configuration error
# 3. Port conflict

# Solution 1: Check resources
docker stats

# Solution 2: Check port conflicts
netstat -tulpn | grep 8443

# Solution 3: Start with debug
docker-compose up ejbca  # Without -d to see output
```

#### Issue: Volume Permission Denied

```bash
# Diagnosis
docker-compose logs ejbca | grep -i "permission denied"

# Solution: Fix volume permissions
docker-compose exec --user root ejbca chown -R 1000:1000 /opt/ejbca/p12
docker-compose restart ejbca
```

---

## Performance Issues

### Slow Certificate Issuance

#### Diagnosis

```bash
# Measure response time
time curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/certificate/enroll \
  -d @request.json

# Check database query performance
kubectl exec -n database postgresql-0 -- psql -U postgres -c "
SELECT query, calls, total_time/calls as avg_time_ms
FROM pg_stat_statements
WHERE query LIKE '%CertificateData%'
ORDER BY total_time DESC
LIMIT 10;
"

# Check EJBCA thread pools
kubectl exec -n ejbca ejbca-ce-0 -- jstack 1 | grep -A 5 "pool"
```

#### Solutions

```bash
# 1. Add database indexes
kubectl exec -n database postgresql-0 -- psql -U postgres -d ejbca -c "
CREATE INDEX CONCURRENTLY idx_cert_username ON CertificateData(username);
CREATE INDEX CONCURRENTLY idx_cert_serialnumber ON CertificateData(serialNumber);
"

# 2. Increase database shared_buffers
az postgres flexible-server parameter set \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --server-name $(terraform -chdir=terraform output -raw postgresql_server_name) \
  --name shared_buffers \
  --value 4GB

# 3. Scale EJBCA horizontally
kubectl scale deployment ejbca-ce --replicas=5 -n ejbca
```

### Slow OCSP Responses

```bash
# Check OCSP response time
time openssl ocsp \
  -issuer ca.crt \
  -cert server.crt \
  -url http://ocsp.ejbca.local

# Solution: Enable OCSP pre-generation
# In EJBCA Admin UI:
# System Configuration → OCSP
# - Enable pre-signed OCSP responses
# - Set signing interval to 10 minutes
# - Enable OCSP response caching
```

---

## Security Issues

### Unauthorized Access Attempts

#### Detection

```bash
# Check failed authentication attempts
kubectl logs -n ejbca ejbca-ce-0 | grep "Authentication failed"

# Check Key Vault access logs
az monitor activity-log list \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --max-events 100 \
  --query "[?contains(resourceId, 'keyvault') && contains(operationName.value, 'Unauthorized')].{Time:eventTimestamp, User:caller, Operation:operationName.localizedValue}" \
  --output table
```

#### Response

```bash
# 1. Block suspicious IPs in NSG
az network nsg rule create \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --nsg-name ejbca-platform-dev-services-nsg \
  --name block-suspicious-ip \
  --priority 100 \
  --source-address-prefixes "SUSPICIOUS_IP" \
  --destination-port-ranges "*" \
  --access Deny

# 2. Rotate API keys
# Via EJBCA Admin UI: System Functions → API Keys → Revoke

# 3. Review and revoke suspicious certificates
# Via EJBCA Admin UI or REST API
```

### Certificate Compromise

```bash
# Immediate actions:
# 1. Revoke compromised certificate
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/certificate/revoke \
  -d '{
    "issuer_dn": "CN=TLS Issuing CA,O=Enterprise PKI,C=US",
    "certificate_serial_number": "COMPROMISED_SERIAL",
    "reason": "KEY_COMPROMISE"
  }'

# 2. Update CRL immediately
# Via EJBCA Admin UI: CA Functions → [CA Name] → Create CRL

# 3. Notify certificate consumers
# Send notification emails/alerts

# 4. Investigate how compromise occurred
kubectl logs -n ejbca ejbca-ce-0 --since=24h | grep "COMPROMISED_SERIAL"
```

---

## Integration Issues

### ACME Client Failing

```bash
# Common certbot issues

# Issue: HTTP-01 challenge fails
# Check: Port 80 accessible?
curl -v http://ejbca.local/.well-known/acme-challenge/test

# Solution: Ensure ingress allows HTTP
kubectl get ingress -n ejbca
# Verify HTTP (port 80) is configured

# Issue: DNS-01 challenge fails
# Check: DNS record created?
dig _acme-challenge.example.com TXT

# Issue: Rate limiting
# Check: EJBCA logs for rate limit messages
kubectl logs -n ejbca ejbca-ce-0 | grep -i "rate limit"

# Solution: Implement exponential backoff in client
```

### SCEP Enrollment Failing

```bash
# Diagnosis
# Check SCEP logs
kubectl logs -n ejbca ejbca-ce-0 | grep -i "scep"

# Test SCEP endpoint
curl "https://ejbca.local/ejbca/publicweb/apply/scep/pkiclient.exe?operation=GetCACert&message=scep"

# Common issues:
# 1. Challenge password incorrect
# 2. CSR format invalid
# 3. End entity profile misconfigured

# Solution: Verify SCEP configuration
# EJBCA Admin UI → System Functions → Protocol Configuration → SCEP
```

---

## Emergency Procedures

### Complete Service Outage

```bash
# Priority: Restore service as quickly as possible

# Step 1: Check overall health
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running

# Step 2: Identify failed components
# Database down?
kubectl get pods -n database

# EJBCA down?
kubectl get pods -n ejbca

# Network issue?
kubectl get svc --all-namespaces
kubectl get ingress --all-namespaces

# Step 3: Quick fixes
# Restart failed pods
kubectl delete pod <failed-pod> -n <namespace>

# Scale up if needed
kubectl scale deployment ejbca-ce --replicas=5 -n ejbca

# Step 4: If still down, restore from backup
# See Deployment & Operations Guide → Backup & Recovery
```

### Database Corruption

```bash
# CRITICAL: Stop all EJBCA instances immediately
kubectl scale deployment ejbca-ce --replicas=0 -n ejbca

# Restore database from backup
# See disaster recovery procedures

# Verify data integrity
kubectl exec -n database postgresql-0 -- psql -U postgres -d ejbca -c "
SELECT COUNT(*) FROM CertificateData;
SELECT COUNT(*) FROM CAData;
"

# Restart EJBCA
kubectl scale deployment ejbca-ce --replicas=3 -n ejbca
```

### CA Key Compromise (CRITICAL)

```bash
# THIS IS A CRITICAL SECURITY INCIDENT
# Follow your organization's incident response plan

# Immediate actions:
# 1. Isolate affected CA
#    - Disable CA in EJBCA
#    - Revoke access to Key Vault

# 2. Notify stakeholders
#    - Security team
#    - Management
#    - Certificate consumers

# 3. Revoke CA certificate
#    - Contact parent CA
#    - Publish revocation

# 4. Generate new CA with new keys
#    - Use different Key Vault key
#    - New subject DN

# 5. Re-issue all certificates
#    - Automate where possible
#    - Track progress

# 6. Conduct post-incident review
#    - Document timeline
#    - Identify root cause
#    - Implement preventive measures
```

---

## Escalation Procedures

### When to Escalate

| Scenario | Escalate To | Priority |
|----------|-------------|----------|
| **P1 outage > 30 minutes** | Infrastructure Lead | Immediate |
| **Security incident** | Security Team | Immediate |
| **Data loss** | DBA + Management | Immediate |
| **Performance degradation** | Platform Team | 1 hour |
| **Configuration issues** | PKI Administrator | 4 hours |

### Escalation Contacts

```yaml
# Update with your organization's contacts
contacts:
  infrastructure_lead:
    name: "Infrastructure Manager"
    email: "infra-lead@example.com"
    phone: "+1-XXX-XXX-XXXX"
    oncall: "https://pagerduty.com/infra"
  
  security_team:
    email: "security@example.com"
    phone: "+1-XXX-XXX-XXXX"
    oncall: "https://pagerduty.com/security"
  
  pki_admin:
    name: "Adrian Johnson"
    email: "adrian207@gmail.com"
  
  vendor_support:
    ejbca: "https://forum.keyfactor.com"
    azure: "https://portal.azure.com/#blade/Microsoft_Azure_Support"
```

---

## Useful Resources

### Documentation
- [EJBCA Troubleshooting](https://doc.primekey.com/ejbca/ejbca-operations/troubleshooting)
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [PostgreSQL Wiki](https://wiki.postgresql.org/wiki/Main_Page)

### Tools
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [OpenSSL Commands](https://www.openssl.org/docs/man1.1.1/man1/)
- [curl Manual](https://curl.se/docs/manual.html)

### Community
- [EJBCA Community Forum](https://forum.keyfactor.com)
- [Stack Overflow - EJBCA Tag](https://stackoverflow.com/questions/tagged/ejbca)

---

## Document History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| Oct 2025 | 1.0.0 | Adrian Johnson | Initial release |

---

**Maintained By**: Adrian Johnson | adrian207@gmail.com  
**Review Schedule**: Quarterly  
**Next Review**: January 2026

---

*End of Troubleshooting Guide*




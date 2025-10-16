# EJBCA CE Major Features Demonstration Guide

**Author**: Adrian Johnson | adrian207@gmail.com

This document provides comprehensive guidance on demonstrating all major features of Keyfactor EJBCA Community Edition within this PKI platform.

## Table of Contents

1. [Certificate Authority Management](#certificate-authority-management)
2. [Protocol Support](#protocol-support)
3. [Certificate Lifecycle Management](#certificate-lifecycle-management)
4. [Advanced Features](#advanced-features)
5. [Administration and Security](#administration-and-security)

---

## Certificate Authority Management

### 1. CA Hierarchy

EJBCA supports complex CA hierarchies with multiple levels:

```
Root CA (Offline)
├── Issuing CA - TLS (Online)
├── Issuing CA - Code Signing (Online)
└── Issuing CA - Device (Online)
```

**Demo Steps:**
1. Access EJBCA Admin UI: `https://ejbca.local/ejbca/adminweb`
2. Navigate to "CA Functions" → "Certificate Authorities"
3. View the configured CA hierarchy
4. Examine each CA's:
   - Certificate profile
   - CRL distribution points
   - OCSP configuration
   - Key storage (Azure Key Vault integration)

**Key Features:**
- **Offline Root CA**: Highest security, rarely used
- **Online Subordinate CAs**: Issue end-entity certificates
- **Separate CAs by Purpose**: TLS, Code Signing, Device certificates
- **Cross-certification**: Support for multiple trust paths

### 2. Certificate Profiles

Eight distinct certificate profiles demonstrate different use cases:

| Profile | Use Case | Key Type | Validity |
|---------|----------|----------|----------|
| SERVER_CERTIFICATE | TLS/SSL servers | RSA 2048+ | 2 years |
| CLIENT_CERTIFICATE | User authentication | RSA/ECDSA | 1 year |
| CODE_SIGNING | Software signing | RSA 3072+ | 3 years |
| DOCUMENT_SIGNING | PDF signing | RSA/ECDSA | 2 years |
| IPSEC_VPN | VPN endpoints | RSA/ECDSA | 1 year |
| CONTAINER_SIGNING | Docker/OCI images | ECDSA | 1 year |
| IOT_DEVICE | IoT devices | ECDSA | 3 years |
| TIMESTAMPING | TSA certificates | RSA 4096 | 10 years |

**Demo Steps:**
1. Navigate to "CA Functions" → "Certificate Profiles"
2. Select each profile to view:
   - Key usage extensions
   - Extended key usage (EKU)
   - Subject Alternative Names (SAN)
   - Certificate policies
   - Validity periods

### 3. End Entity Profiles

End Entity Profiles control how certificates are issued:

**Demo:**
- **WEB_SERVER**: Automated issuance, DNS validation
- **USER_AUTHENTICATION**: Email validation required
- **SOFTWARE_PUBLISHER**: Approval workflow (2 approvers)
- **IOT_FLEET**: SCEP/EST enabled for automated provisioning

---

## Protocol Support

### 1. ACME (Automated Certificate Management Environment)

**Compatible with:** Let's Encrypt clients (certbot, acme.sh)

**Demo:**
```bash
# Using certbot
certbot certonly --standalone \
  --server https://ejbca.local/ejbca/.well-known/acme/directory \
  --domain example.pki.local \
  --email admin@pki.local

# Using acme.sh
acme.sh --issue \
  --server https://ejbca.local/ejbca/.well-known/acme/directory \
  -d example.pki.local \
  --standalone
```

**Features Demonstrated:**
- HTTP-01 challenge
- DNS-01 challenge (with DNS plugins)
- Wildcard certificates
- Automatic renewal
- External Account Binding (EAB)

### 2. SCEP (Simple Certificate Enrollment Protocol)

**Used by:** Network devices, MDM solutions, IoT devices

**Demo:**
```bash
# Get CA certificate
sscep getca -u https://ejbca.local/ejbca/publicweb/apply/scep/pkiclient.exe

# Enroll certificate
sscep enroll \
  -u https://ejbca.local/ejbca/publicweb/apply/scep/pkiclient.exe \
  -k device.key \
  -r device.csr \
  -c ca.crt \
  -l device.crt
```

**Features:**
- GetCACert operation
- PKCSReq enrollment
- GetCert certificate retrieval
- GetCRL CRL download
- Automatic renewal

### 3. CMP (Certificate Management Protocol)

**Enterprise PKI protocol** (RFC 4210)

**Demo:**
```bash
openssl cmp \
  -cmd ir \
  -server ejbca.local:8442/ejbca/publicweb/cmp \
  -path "CMP" \
  -ref "reference-id" \
  -secret "password:secret123" \
  -subject "/CN=server.local/O=Company" \
  -newkey server.key \
  -certout server.crt
```

**Operations:**
- IR (Initialization Request)
- CR (Certification Request)
- KUR (Key Update Request)
- RR (Revocation Request)

### 4. EST (Enrollment over Secure Transport)

**Modern IoT enrollment protocol** (RFC 7030)

**Demo:**
```bash
# Get CA certificates
curl https://ejbca.local:8443/ejbca/.well-known/est/cacerts

# Simple enroll
curl -X POST \
  https://ejbca.local:8443/ejbca/.well-known/est/simpleenroll \
  -H "Content-Type: application/pkcs10" \
  --data-binary @device.csr
```

**Features:**
- CA certificates distribution
- Simple enrollment
- Re-enrollment
- Server-side key generation

### 5. REST API

**Modern programmatic access**

**Demo:**
```bash
curl -X POST https://ejbca.local/ejbca/ejbca-rest-api/v1/certificate/enroll \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{
    "certificate_request": "BASE64_CSR",
    "certificate_profile_name": "SERVER",
    "end_entity_profile_name": "WEB_SERVER",
    "username": "server123",
    "password": "changeme"
  }'
```

**Endpoints:**
- `/v1/certificate/enroll` - Issue certificates
- `/v1/certificate/revoke` - Revoke certificates
- `/v1/certificate/search` - Search certificates
- `/v1/ca` - CA management
- `/v1/endentity` - User management

### 6. Web Services (SOAP)

**Legacy enterprise integration**

**Features:**
- WS-Security authentication
- WSDL-based integration
- Full CA operations via SOAP

---

## Certificate Lifecycle Management

### 1. Issuance Workflows

**Automated Issuance:**
- ACME for web servers
- SCEP for devices
- EST for IoT fleets

**Manual Approval:**
- Code signing certificates (2-person rule)
- High-value certificates
- Configurable approval chains

**Demo:**
1. Submit code signing CSR
2. View in "RA Functions" → "Approve Requests"
3. Approve with 2 different admin accounts
4. Certificate issued after approvals

### 2. Renewal

**Methods:**
- ACME auto-renewal (certbot timers)
- SCEP renewal (before expiration)
- CMP Key Update Request
- Manual renewal via Admin UI

**Monitoring:**
```bash
# Check certificates expiring in 30 days
./scripts/check-expiring-certificates.sh 30
```

### 3. Revocation

**Methods:**
- REST API
- Admin UI
- CMP Revocation Request
- Automated on key compromise

**Demo:**
```bash
# Revoke via REST API
curl -X POST https://ejbca.local/ejbca/ejbca-rest-api/v1/certificate/revoke \
  -H "Content-Type: application/json" \
  -d '{
    "serial_number": "1234567890ABCDEF",
    "reason": "keyCompromise"
  }'
```

**Revocation Reasons:**
- unspecified
- keyCompromise
- cACompromise
- affiliationChanged
- superseded
- cessationOfOperation
- certificateHold
- removeFromCRL

### 4. CRL Generation and Distribution

**Configuration:**
- Period: 24 hours
- Issue Interval: 1 hour
- Delta CRL supported

**Distribution Points:**
- HTTP: `http://crl.pki.local/`
- LDAP: `ldap://ldap.pki.local/`
- Azure Blob Storage

**Demo:**
```bash
# Download CRL
curl http://crl.pki.local/tls-ca.crl -o tls-ca.crl

# Parse CRL
openssl crl -in tls-ca.crl -inform DER -text -noout
```

### 5. OCSP (Online Certificate Status Protocol)

**Configuration:**
- Response validity: 10 minutes
- Pre-generated responses (performance)
- Dedicated OCSP responder certificates

**Demo:**
```bash
openssl ocsp \
  -issuer issuing-ca.crt \
  -cert server.crt \
  -url http://ocsp.pki.local \
  -text
```

**Response Types:**
- Good
- Revoked (with reason and time)
- Unknown

---

## Advanced Features

### 1. Azure Key Vault Integration

**HSM-backed CA keys** stored in Azure Key Vault

**Features:**
- FIPS 140-2 Level 2 compliance
- Key rotation policies
- Audit logging
- Managed identities for access

**Demo:**
1. View CA configuration
2. Note "Crypto Token: AZURE_KEY_VAULT"
3. Show Azure portal key access logs

### 2. Certificate Transparency

**Google Certificate Transparency** integration

**Features:**
- Automatic SCT embedding
- Pre-certificate submission
- CT log monitoring

**Verification:**
```bash
# Check for embedded SCTs
openssl x509 -in cert.crt -text | grep -A 10 "CT Precertificate SCTs"

# Search CT logs
curl "https://crt.sh/?q=%.pki.local&output=json"
```

### 3. Publishers

**Automatic certificate distribution:**

1. **Azure Storage Publisher**
   - Publishes to Blob Storage
   - Certificates and CRLs
   - Public access for distribution

2. **LDAP Publisher**
   - Enterprise directory integration
   - userCertificate attribute
   - certificateRevocationList attribute

3. **Custom Publishers**
   - Webhook notifications
   - Database integration
   - Custom scripts

### 4. Key Recovery and Archival

**Configuration:**
- End entity keys can be archived
- Encrypted in database
- Recovery requires multiple admins

**Use Cases:**
- S/MIME encryption keys
- Document signing keys
- Regulatory compliance

### 5. Custom Certificate Extensions

**Demo:**
```json
{
  "extensions": {
    "1.2.3.4.5.6.7.8": {
      "critical": false,
      "value": "custom-data-here"
    }
  }
}
```

**Use Cases:**
- Proprietary application data
- Policy indicators
- Custom identifiers

---

## Administration and Security

### 1. Role-Based Access Control (RBAC)

**Predefined Roles:**
- **Super Administrator**: Full access
- **CA Administrator**: Manage CAs
- **RA Administrator**: Issue/revoke certificates
- **Auditor**: Read-only access

**Custom Roles:**
- Fine-grained permissions
- Resource-level access
- Action-based rules

**Demo:**
1. Navigate to "System Functions" → "Administrator Roles"
2. Create custom role "Certificate Approver"
3. Grant only approval permissions
4. Assign to user

### 2. Audit Logging

**Comprehensive logging** of all actions:

**Events Logged:**
- Certificate issuance
- Certificate revocation
- CA operations
- Configuration changes
- Login attempts
- API calls

**Integration:**
- Loki (via OpenTelemetry)
- Azure Log Analytics
- Syslog export
- Database audit log

**Demo:**
```bash
# Query audit logs
kubectl logs -n ejbca -l app=ejbca-ce | grep AUDIT
```

### 3. Administrator Approval Workflows

**Multi-person control** for sensitive operations:

**Configurable Approvals:**
- CA key usage
- Certificate profile changes
- High-value certificate issuance
- Administrator role changes

**Demo:**
1. Submit action requiring approval
2. View in approval queue
3. Multiple admins approve
4. Action executes

### 4. Backup and Restore

**Critical Data:**
- CA keys (Azure Key Vault backup)
- Database (PostgreSQL backups)
- Configuration files
- Audit logs

**Automated Backups:**
```yaml
# Backup schedule (daily)
- Database: PostgreSQL automated backups (30 days retention)
- Keys: Azure Key Vault soft delete (90 days)
- Certificates: Azure Blob Storage (versioning enabled)
- Logs: Loki (30 days retention)
```

**Disaster Recovery:**
1. Restore database from backup
2. Recover keys from Key Vault
3. Restore configuration
4. Verify CA functionality

### 5. Health Monitoring

**Endpoints:**
- `/ejbca/publicweb/healthcheck/ejbcahealth` - Overall health
- `/metrics` - Prometheus metrics

**Monitored Metrics:**
- Certificate issuance rate
- OCSP response time
- CRL generation time
- Database connection pool
- Memory usage
- CPU usage

**Alerts:**
- CA key expiration approaching
- CRL generation failures
- OCSP responder down
- High error rates

---

## Integration Examples

### Kubernetes Certificate Management

```yaml
# cert-manager Issuer using EJBCA ACME
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ejbca-acme
spec:
  acme:
    server: https://ejbca.local/ejbca/.well-known/acme/directory
    email: admin@pki.local
    privateKeySecretRef:
      name: ejbca-acme-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

### Container Image Signing

```bash
# Sign container image with EJBCA-issued certificate
cosign sign --key ejbca-signing.key \
  harbor.local/ejbca/app:v1.0.0
```

### IoT Device Provisioning

```python
# Python example using EST
import requests

# Get CA certificate
ca_certs = requests.get(
    'https://ejbca.local:8443/ejbca/.well-known/est/cacerts'
)

# Enroll device certificate
csr = generate_csr()
response = requests.post(
    'https://ejbca.local:8443/ejbca/.well-known/est/simpleenroll',
    data=csr,
    headers={'Content-Type': 'application/pkcs10'}
)
```

---

## Performance Benchmarks

**Typical Performance:**
- Certificate issuance: < 500ms
- OCSP response: < 50ms
- CRL generation: < 5 seconds
- API requests: < 200ms

**Scaling:**
- Horizontal scaling with multiple EJBCA nodes
- PostgreSQL read replicas
- Redis cache for OCSP responses
- CDN for CRL distribution

---

## Conclusion

This EJBCA CE platform demonstrates enterprise-grade PKI capabilities including:

✅ Complete CA hierarchy with HSM integration  
✅ Multiple enrollment protocols (ACME, SCEP, CMP, EST, REST)  
✅ Comprehensive certificate lifecycle management  
✅ Advanced security features and RBAC  
✅ Full observability and monitoring  
✅ Cloud-native deployment on Kubernetes  
✅ Integration with modern DevOps tools  

For additional resources:
- [EJBCA Official Documentation](https://doc.primekey.com/ejbca)
- [Demo Scripts](../scripts/demo-scenarios.sh)
- [API Reference](https://doc.primekey.com/ejbca/ejbca-operations/ejbca-rest-interface)


# Enterprise PKI Platform - API & Integration Guide

**Author**: Adrian Johnson | adrian207@gmail.com  
**Version**: 1.0.0  
**Last Updated**: October 2025  
**Status**: Production-Ready

---

## Table of Contents

1. [Overview](#overview)
2. [REST API](#rest-api)
3. [ACME Protocol](#acme-protocol)
4. [SCEP Protocol](#scep-protocol)
5. [CMP Protocol](#cmp-protocol)
6. [EST Protocol](#est-protocol)
7. [Web Services (SOAP)](#web-services-soap)
8. [Integration Examples](#integration-examples)
9. [Authentication & Authorization](#authentication--authorization)
10. [Best Practices](#best-practices)

---

## Overview

### Available Integration Methods

The EJBCA PKI Platform provides multiple integration methods to support various use cases:

| Protocol/API | Use Case | Transport | Authentication |
|--------------|----------|-----------|----------------|
| **REST API** | Modern applications, custom integrations | HTTPS | API Key, Client Cert |
| **ACME** | Web servers, automated certificate management | HTTPS | Account key |
| **SCEP** | Network devices, IoT enrollment | HTTP/HTTPS | Challenge password |
| **CMP** | Enterprise PKI, large-scale enrollment | HTTP/HTTPS | Shared secret, cert |
| **EST** | Modern IoT devices | HTTPS | Client cert, password |
| **Web Services** | Legacy enterprise applications | HTTPS/SOAP | WS-Security |

### Base URLs

```bash
# Production
REST_API_BASE="https://ejbca.local/ejbca/ejbca-rest-api/v1"
ACME_BASE="https://ejbca.local/ejbca/.well-known/acme"
SCEP_BASE="https://ejbca.local/ejbca/publicweb/apply/scep"
CMP_BASE="https://ejbca.local:8442/ejbca/publicweb/cmp"
EST_BASE="https://ejbca.local:8443/ejbca/.well-known/est"
WS_BASE="https://ejbca.local/ejbca/ejbcaws/ejbcaws"
```

---

## REST API

### Authentication

#### Method 1: Client Certificate Authentication

```bash
# Generate client certificate
openssl req -new -x509 -days 365 -key client.key -out client.crt \
  -subj "/CN=API Client/O=MyOrg/C=US"

# Make API call with client certificate
curl -X GET \
  --cert client.crt \
  --key client.key \
  --cacert ca.crt \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/ca
```

#### Method 2: API Key Authentication

```bash
# Generate API key in EJBCA Admin UI
# System Functions → API Keys → Create New

# Use API key in requests
curl -X GET \
  -H "X-API-Key: your-api-key-here" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/ca
```

### Certificate Operations

#### 1. Issue Certificate

```bash
# Endpoint: POST /certificate/enroll

curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/certificate/enroll \
  -d '{
    "certificate_request": "'$(cat request.csr | base64 -w0)'",
    "certificate_profile_name": "SERVER",
    "end_entity_profile_name": "WEB_SERVER",
    "certificate_authority_name": "TLS-CA",
    "username": "server.example.com",
    "password": "enrollment_password"
  }'
```

**Response:**
```json
{
  "certificate": "-----BEGIN CERTIFICATE-----\nMIIE...\n-----END CERTIFICATE-----",
  "serial_number": "1A2B3C4D5E6F",
  "response_format": "PEM"
}
```

#### 2. Revoke Certificate

```bash
# Endpoint: POST /certificate/revoke

curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/certificate/revoke \
  -d '{
    "issuer_dn": "CN=TLS Issuing CA,O=Enterprise PKI,C=US",
    "certificate_serial_number": "1A2B3C4D5E6F",
    "reason": "KEY_COMPROMISE"
  }'
```

**Revocation Reasons:**
- `UNSPECIFIED`
- `KEY_COMPROMISE`
- `CA_COMPROMISE`
- `AFFILIATION_CHANGED`
- `SUPERSEDED`
- `CESSATION_OF_OPERATION`
- `CERTIFICATE_HOLD`
- `REMOVE_FROM_CRL`

#### 3. Search Certificates

```bash
# Endpoint: POST /certificate/search

curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/certificate/search \
  -d '{
    "criteria": [
      {
        "property": "QUERY",
        "value": "CN=server.example.com",
        "operation": "LIKE"
      },
      {
        "property": "STATUS",
        "value": "CERT_ACTIVE",
        "operation": "EQUAL"
      }
    ],
    "max_number_of_results": 100
  }'
```

**Response:**
```json
{
  "certificates": [
    {
      "fingerprint": "SHA256:abc123...",
      "certificate_data": "-----BEGIN CERTIFICATE-----...",
      "subject_dn": "CN=server.example.com,O=MyOrg,C=US",
      "issuer_dn": "CN=TLS Issuing CA,O=Enterprise PKI,C=US",
      "serial_number": "1A2B3C4D5E6F",
      "not_before": "2025-01-01T00:00:00Z",
      "not_after": "2027-01-01T00:00:00Z",
      "status": "ACTIVE"
    }
  ],
  "more_results": false
}
```

#### 4. Get Certificate by Serial Number

```bash
# Endpoint: GET /certificate/{issuer_dn}/{serial_number}

curl -X GET \
  -H "X-API-Key: your-api-key" \
  "https://ejbca.local/ejbca/ejbca-rest-api/v1/certificate/CN=TLS%20Issuing%20CA,O=Enterprise%20PKI,C=US/1A2B3C4D5E6F"
```

### CA Operations

#### List Certificate Authorities

```bash
# Endpoint: GET /ca

curl -X GET \
  -H "X-API-Key: your-api-key" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/ca
```

**Response:**
```json
{
  "certificate_authorities": [
    {
      "name": "Root-CA",
      "subject_dn": "CN=Root CA,O=Enterprise PKI,C=US",
      "id": 1,
      "expiration_date": "2045-01-01T00:00:00Z"
    },
    {
      "name": "TLS-CA",
      "subject_dn": "CN=TLS Issuing CA,O=Enterprise PKI,C=US",
      "id": 2,
      "expiration_date": "2035-01-01T00:00:00Z"
    }
  ]
}
```

#### Get CA Certificate

```bash
# Endpoint: GET /ca/{ca_name}/certificate/download

curl -X GET \
  -H "X-API-Key: your-api-key" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/ca/TLS-CA/certificate/download \
  -o tls-ca.crt
```

### End Entity Operations

#### Create End Entity

```bash
# Endpoint: POST /endentity

curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/endentity \
  -d '{
    "username": "user@example.com",
    "password": "enrollment_password",
    "subject_dn": "CN=user@example.com,O=MyOrg,C=US",
    "subject_alt_name": "rfc822Name=user@example.com",
    "email": "user@example.com",
    "ca_name": "TLS-CA",
    "certificate_profile_name": "CLIENT",
    "end_entity_profile_name": "USER_AUTHENTICATION",
    "token": "P12",
    "send_notification": true
  }'
```

---

## ACME Protocol

### Overview

ACME (Automated Certificate Management Environment) is the protocol used by Let's Encrypt. It enables automated certificate issuance and renewal.

### ACME Directory

```bash
# Get ACME directory
curl https://ejbca.local/ejbca/.well-known/acme/directory

# Response:
{
  "newNonce": "https://ejbca.local/ejbca/.well-known/acme/new-nonce",
  "newAccount": "https://ejbca.local/ejbca/.well-known/acme/new-acct",
  "newOrder": "https://ejbca.local/ejbca/.well-known/acme/new-order",
  "revokeCert": "https://ejbca.local/ejbca/.well-known/acme/revoke-cert",
  "keyChange": "https://ejbca.local/ejbca/.well-known/acme/key-change"
}
```

### Using Certbot

#### Basic Certificate Issuance

```bash
# Install certbot
sudo apt-get install certbot  # Debian/Ubuntu
brew install certbot           # macOS

# Issue certificate using standalone authenticator
sudo certbot certonly --standalone \
  --server https://ejbca.local/ejbca/.well-known/acme/directory \
  --domain example.com \
  --email admin@example.com \
  --agree-tos \
  --non-interactive

# Certificate saved to: /etc/letsencrypt/live/example.com/
```

#### Wildcard Certificates

```bash
# Requires DNS-01 challenge
sudo certbot certonly --manual \
  --server https://ejbca.local/ejbca/.well-known/acme/directory \
  --preferred-challenges dns \
  --domain "*.example.com" \
  --domain example.com \
  --email admin@example.com \
  --agree-tos

# Follow prompts to create DNS TXT records
```

#### Automatic Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Setup automatic renewal (systemd timer)
sudo systemctl enable certbot-renew.timer
sudo systemctl start certbot-renew.timer

# Verify timer
sudo systemctl list-timers certbot-renew
```

### Using acme.sh

```bash
# Install acme.sh
curl https://get.acme.sh | sh

# Issue certificate
acme.sh --issue \
  --server https://ejbca.local/ejbca/.well-known/acme/directory \
  -d example.com \
  -d www.example.com \
  --standalone

# Install certificate
acme.sh --install-cert -d example.com \
  --cert-file /etc/nginx/certs/example.com.crt \
  --key-file /etc/nginx/certs/example.com.key \
  --fullchain-file /etc/nginx/certs/example.com.fullchain.crt \
  --reloadcmd "systemctl reload nginx"

# Enable auto-upgrade
acme.sh --upgrade --auto-upgrade
```

### Kubernetes Integration with cert-manager

```yaml
# Create ClusterIssuer
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ejbca-acme
spec:
  acme:
    server: https://ejbca.local/ejbca/.well-known/acme/directory
    email: admin@example.com
    privateKeySecretRef:
      name: ejbca-acme-account-key
    solvers:
      # HTTP-01 solver
      - http01:
          ingress:
            class: nginx
      # DNS-01 solver (for wildcards)
      - dns01:
          azureDNS:
            subscriptionID: "<azure-subscription-id>"
            resourceGroupName: "<dns-zone-rg>"
            hostedZoneName: example.com
            managedIdentity:
              clientID: "<managed-identity-client-id>"
```

```yaml
# Request certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com-tls
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: ejbca-acme
    kind: ClusterIssuer
  dnsNames:
    - example.com
    - www.example.com
```

---

## SCEP Protocol

### Overview

SCEP (Simple Certificate Enrollment Protocol) is widely used for automated device and network equipment enrollment.

### SCEP Endpoints

```bash
# Get CA certificate
curl "https://ejbca.local/ejbca/publicweb/apply/scep/pkiclient.exe?operation=GetCACert&message=scep"

# Get CA certificate chain
curl "https://ejbca.local/ejbca/publicweb/apply/scep/pkiclient.exe?operation=GetCACertChain&message=scep"
```

### Using sscep Client

```bash
# Install sscep
git clone https://github.com/certnanny/sscep.git
cd sscep
make
sudo make install

# Get CA certificate
sscep getca -u https://ejbca.local/ejbca/publicweb/apply/scep/pkiclient.exe \
  -c ca.crt

# Generate key and CSR
openssl genrsa -out device.key 2048
openssl req -new -key device.key -out device.csr \
  -subj "/CN=device001/O=MyOrg/C=US"

# Enroll
sscep enroll \
  -u https://ejbca.local/ejbca/publicweb/apply/scep/pkiclient.exe \
  -c ca.crt \
  -k device.key \
  -r device.csr \
  -l device.crt \
  -S sha256 \
  -v

# Certificate saved to device.crt
```

### SCEP Configuration in EJBCA

```bash
# Configure SCEP alias in EJBCA Admin UI:
# System Functions → Protocol Configuration → SCEP

# Settings:
# - Alias: scep
# - Operation mode: CA
# - Include CA certificate chain: Yes
# - Certificate profile: DEVICE
# - End entity profile: IOT_DEVICE
# - Default CA: TLS-CA
```

### Network Device Examples

#### Cisco IOS

```cisco
! Configure trustpoint
crypto pki trustpoint EJBCA-SCEP
 enrollment mode ra
 enrollment url http://ejbca.local/ejbca/publicweb/apply/scep/pkiclient.exe
 subject-name CN=router001,O=MyOrg,C=US
 revocation-check crl
 rsakeypair EJBCA-SCEP 2048

! Authenticate CA
crypto pki authenticate EJBCA-SCEP

! Enroll
crypto pki enroll EJBCA-SCEP
```

#### Juniper JunOS

```juniper
# Configure SCEP
set security pki ca-profile EJBCA-CA ca-identity ejbca
set security pki ca-profile EJBCA-CA enrollment url http://ejbca.local/ejbca/publicweb/apply/scep/pkiclient.exe
set security pki ca-profile EJBCA-CA revocation-check crl

# Enroll
request security pki ca-certificate enroll ca-profile EJBCA-CA
request security pki local-certificate enroll ca-profile EJBCA-CA certificate-id router001 subject "CN=router001,O=MyOrg,C=US"
```

---

## CMP Protocol

### Overview

CMP (Certificate Management Protocol) is an enterprise-grade protocol for certificate lifecycle management.

### CMP Configuration

```bash
# CMP endpoint
CMP_URL="https://ejbca.local:8442/ejbca/publicweb/cmp/CMP"
```

### Using OpenSSL CMP

#### Initial Registration (IR)

```bash
# Generate key pair
openssl genrsa -out client.key 2048

# Create certificate request
openssl req -new -key client.key -out client.csr \
  -subj "/CN=client001/O=MyOrg/C=US"

# Send IR request
openssl cmp \
  -cmd ir \
  -server ejbca.local:8442/ejbca/publicweb/cmp/CMP \
  -path "CMP" \
  -ref "reference-id-12345" \
  -secret "pass:enrollment_password" \
  -newkey client.key \
  -subject "/CN=client001/O=MyOrg/C=US" \
  -certout client.crt \
  -cacertsout ca-chain.pem

# Certificate saved to client.crt
```

#### Certificate Update (KUR)

```bash
# Renew certificate before expiration
openssl cmp \
  -cmd kur \
  -server ejbca.local:8442/ejbca/publicweb/cmp/CMP \
  -path "CMP" \
  -cert client.crt \
  -key client.key \
  -newkey client-new.key \
  -certout client-renewed.crt \
  -cacertsout ca-chain.pem
```

#### Revocation Request (RR)

```bash
# Revoke certificate
openssl cmp \
  -cmd rr \
  -server ejbca.local:8442/ejbca/publicweb/cmp/CMP \
  -path "CMP" \
  -cert client.crt \
  -key client.key \
  -oldcert client.crt
```

---

## EST Protocol

### Overview

EST (Enrollment over Secure Transport) is a modern, lightweight protocol designed for IoT and constrained devices.

### EST Endpoints

```bash
EST_BASE="https://ejbca.local:8443/ejbca/.well-known/est/default"

# Available operations:
# /cacerts         - Get CA certificates
# /simpleenroll    - Simple enrollment
# /simplereenroll  - Re-enrollment
# /serverkeygen    - Server-side key generation
# /csrattrs        - Get CSR attributes
```

### Using curl

#### Get CA Certificates

```bash
# Get CA certificate chain
curl -k https://ejbca.local:8443/ejbca/.well-known/est/default/cacerts \
  --output cacerts.p7b

# Convert to PEM
openssl pkcs7 -inform DER -in cacerts.p7b -print_certs -out ca-chain.pem
```

#### Simple Enrollment

```bash
# Generate key and CSR
openssl genrsa -out device.key 2048
openssl req -new -key device.key -out device.csr \
  -subj "/CN=device001/O=MyOrg/C=US"

# Enroll (requires basic auth or client cert)
curl -k \
  --user "device001:enrollment_password" \
  --data-binary @device.csr \
  -H "Content-Type: application/pkcs10" \
  https://ejbca.local:8443/ejbca/.well-known/est/default/simpleenroll \
  --output device.p7b

# Extract certificate
openssl pkcs7 -inform DER -in device.p7b -print_certs -out device.crt
```

### Python EST Client Example

```python
import requests
import base64
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography import x509
from cryptography.x509.oid import NameOID

# Generate key pair
private_key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048
)

# Create CSR
csr = x509.CertificateSigningRequestBuilder().subject_name(x509.Name([
    x509.NameAttribute(NameOID.COMMON_NAME, "device001"),
    x509.NameAttribute(NameOID.ORGANIZATION_NAME, "MyOrg"),
    x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
])).sign(private_key, hashes.SHA256())

# Encode CSR to DER
csr_der = csr.public_bytes(serialization.Encoding.DER)

# Enroll via EST
response = requests.post(
    'https://ejbca.local:8443/ejbca/.well-known/est/default/simpleenroll',
    data=csr_der,
    headers={'Content-Type': 'application/pkcs10'},
    auth=('device001', 'enrollment_password'),
    verify='ca-chain.pem'
)

if response.status_code == 200:
    # Save certificate
    with open('device.p7b', 'wb') as f:
        f.write(response.content)
    print("Certificate enrolled successfully")
else:
    print(f"Enrollment failed: {response.status_code}")
```

---

## Web Services (SOAP)

### WSDL Location

```bash
# EJBCA Web Services WSDL
https://ejbca.local/ejbca/ejbcaws/ejbcaws?wsdl
```

### Java Client Example

```java
import org.ejbca.core.protocol.ws.*;

public class EJBCAWebServiceClient {
    
    public static void main(String[] args) throws Exception {
        // Create service
        EjbcaWS ejbcaWS = new EjbcaWSService().getEjbcaWSPort();
        
        // Configure TLS with client certificate
        // ... TLS configuration ...
        
        // Issue certificate
        UserDataVOWS userData = new UserDataVOWS();
        userData.setUsername("user001");
        userData.setPassword("enrollment_password");
        userData.setSubjectDN("CN=user001,O=MyOrg,C=US");
        userData.setEmail("user001@example.com");
        userData.setCaName("TLS-CA");
        userData.setCertificateProfileName("SERVER");
        userData.setEndEntityProfileName("WEB_SERVER");
        userData.setTokenType(UserDataVOWS.TOKEN_TYPE_P12);
        
        // Edit user (create or update)
        ejbcaWS.editUser(userData);
        
        // Generate PKCS#12
        KeyStore keyStore = ejbcaWS.pkcs12Req(
            "user001",
            "enrollment_password",
            null,  // hardTokenSN
            "2048",
            "RSA"
        );
        
        // Save keystore
        try (FileOutputStream fos = new FileOutputStream("user001.p12")) {
            keyStore.writeTo(fos);
        }
        
        System.out.println("Certificate issued successfully");
    }
}
```

---

## Integration Examples

### Example 1: Web Application Certificate Automation

```python
#!/usr/bin/env python3
"""
Automated certificate management for web applications
"""
import requests
import subprocess
import time
from datetime import datetime, timedelta

class CertificateManager:
    def __init__(self, api_key, base_url):
        self.api_key = api_key
        self.base_url = base_url
        self.headers = {"X-API-Key": api_key, "Content-Type": "application/json"}
    
    def check_expiry(self, domain):
        """Check when certificate expires"""
        # Search for certificate
        response = requests.post(
            f"{self.base_url}/certificate/search",
            json={
                "criteria": [
                    {"property": "QUERY", "value": f"CN={domain}", "operation": "LIKE"}
                ]
            },
            headers=self.headers
        )
        
        if response.status_code == 200:
            certs = response.json().get("certificates", [])
            if certs:
                expiry = datetime.fromisoformat(certs[0]["not_after"].replace("Z", "+00:00"))
                days_left = (expiry - datetime.now()).days
                return days_left
        return None
    
    def renew_certificate(self, domain):
        """Renew certificate using ACME"""
        print(f"Renewing certificate for {domain}...")
        
        # Use certbot for renewal
        result = subprocess.run([
            "certbot", "certonly",
            "--standalone",
            "--server", f"{self.base_url.replace('/ejbca-rest-api/v1', '')}/.well-known/acme/directory",
            "--domain", domain,
            "--non-interactive",
            "--agree-tos",
            "--force-renewal"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"Certificate renewed successfully for {domain}")
            return True
        else:
            print(f"Renewal failed: {result.stderr}")
            return False
    
    def monitor_and_renew(self, domains, threshold_days=30):
        """Monitor certificates and renew if needed"""
        for domain in domains:
            days_left = self.check_expiry(domain)
            
            if days_left is None:
                print(f"Certificate for {domain} not found")
                continue
            
            print(f"{domain}: {days_left} days until expiration")
            
            if days_left < threshold_days:
                self.renew_certificate(domain)

# Usage
if __name__ == "__main__":
    manager = CertificateManager(
        api_key="your-api-key",
        base_url="https://ejbca.local/ejbca/ejbca-rest-api/v1"
    )
    
    domains = [
        "app.example.com",
        "api.example.com",
        "www.example.com"
    ]
    
    manager.monitor_and_renew(domains, threshold_days=30)
```

### Example 2: IoT Device Fleet Management

```python
#!/usr/bin/env python3
"""
IoT device certificate provisioning via SCEP
"""
import subprocess
import json
import requests

class IoTProvisioner:
    def __init__(self, scep_url, ca_cert_path):
        self.scep_url = scep_url
        self.ca_cert_path = ca_cert_path
    
    def provision_device(self, device_id, device_serial):
        """Provision certificate for IoT device"""
        
        # Generate device key
        key_path = f"/etc/iot/devices/{device_id}/device.key"
        crt_path = f"/etc/iot/devices/{device_id}/device.crt"
        
        # Generate key
        subprocess.run([
            "openssl", "genrsa",
            "-out", key_path,
            "2048"
        ], check=True)
        
        # Create CSR
        csr_path = f"/tmp/{device_id}.csr"
        subprocess.run([
            "openssl", "req", "-new",
            "-key", key_path,
            "-out", csr_path,
            "-subj", f"/CN={device_id}/serialNumber={device_serial}/O=IoT Devices/C=US"
        ], check=True)
        
        # Enroll via SCEP
        result = subprocess.run([
            "sscep", "enroll",
            "-u", self.scep_url,
            "-c", self.ca_cert_path,
            "-k", key_path,
            "-r", csr_path,
            "-l", crt_path,
            "-S", "sha256"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"Device {device_id} provisioned successfully")
            return True
        else:
            print(f"Provisioning failed: {result.stderr}")
            return False
    
    def bulk_provision(self, devices):
        """Provision multiple devices"""
        results = {"success": [], "failed": []}
        
        for device in devices:
            if self.provision_device(device["id"], device["serial"]):
                results["success"].append(device["id"])
            else:
                results["failed"].append(device["id"])
        
        return results

# Usage
if __name__ == "__main__":
    provisioner = IoTProvisioner(
        scep_url="https://ejbca.local/ejbca/publicweb/apply/scep/pkiclient.exe",
        ca_cert_path="/etc/iot/ca.crt"
    )
    
    devices = [
        {"id": "sensor-001", "serial": "SN12345"},
        {"id": "sensor-002", "serial": "SN12346"},
        {"id": "sensor-003", "serial": "SN12347"}
    ]
    
    results = provisioner.bulk_provision(devices)
    print(f"Provisioned: {len(results['success'])}")
    print(f"Failed: {len(results['failed'])}")
```

### Example 3: Container Image Signing

```bash
#!/bin/bash
# Sign container images with EJBCA-issued certificates

# Configuration
EJBCA_API="https://ejbca.local/ejbca/ejbca-rest-api/v1"
API_KEY="your-api-key"
IMAGE_NAME="myapp:v1.0.0"
REGISTRY="harbor.local/myorg"

# 1. Get signing certificate if needed
get_signing_cert() {
    # Check if certificate exists and is valid
    if [ ! -f ~/.docker/signing.crt ] || ! openssl x509 -in ~/.docker/signing.crt -noout -checkend 2592000; then
        echo "Obtaining new signing certificate..."
        
        # Generate key
        openssl genrsa -out ~/.docker/signing.key 2048
        
        # Generate CSR
        openssl req -new -key ~/.docker/signing.key -out /tmp/signing.csr \
            -subj "/CN=Container Signing/O=MyOrg/C=US"
        
        # Request certificate from EJBCA
        CSR_BASE64=$(base64 -w0 /tmp/signing.csr)
        
        curl -X POST \
            -H "X-API-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            "$EJBCA_API/certificate/enroll" \
            -d "{
                \"certificate_request\": \"$CSR_BASE64\",
                \"certificate_profile_name\": \"CONTAINER_SIGNING\",
                \"end_entity_profile_name\": \"SOFTWARE_PUBLISHER\",
                \"username\": \"container-signer\",
                \"password\": \"signing_password\"
            }" | jq -r '.certificate' > ~/.docker/signing.crt
        
        echo "Certificate obtained"
    fi
}

# 2. Sign image
sign_image() {
    local image=$1
    
    echo "Signing image: $image"
    
    # Using Cosign
    cosign sign \
        --key ~/.docker/signing.key \
        --cert ~/.docker/signing.crt \
        "$REGISTRY/$image"
    
    echo "Image signed successfully"
}

# 3. Verify signed image
verify_image() {
    local image=$1
    
    echo "Verifying image: $image"
    
    cosign verify \
        --certificate-identity-regexp ".*" \
        --certificate-oidc-issuer-regexp ".*" \
        --cert ~/.docker/signing.crt \
        "$REGISTRY/$image"
}

# Main workflow
get_signing_cert
sign_image "$IMAGE_NAME"
verify_image "$IMAGE_NAME"
```

---

## Authentication & Authorization

### API Key Management

#### Create API Key (via Admin UI)

1. Login to EJBCA Admin UI
2. Navigate to: **System Functions** → **API Keys**
3. Click **Create New**
4. Configure:
   - Name: `production-api-key`
   - Permissions: Select required operations
   - IP restrictions: Whitelist specific IPs
   - Rate limits: Set appropriate limits
5. Save and securely store the generated key

#### Using API Keys

```bash
# Include in header
curl -H "X-API-Key: your-api-key-here" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/ca

# Or in environment variable
export EJBCA_API_KEY="your-api-key-here"
curl -H "X-API-Key: $EJBCA_API_KEY" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/ca
```

### Client Certificate Authentication

#### Generate Client Certificate

```bash
# Generate key
openssl genrsa -out api-client.key 2048

# Create CSR
openssl req -new -key api-client.key -out api-client.csr \
  -subj "/CN=API Client/O=MyOrg/C=US"

# Issue certificate via EJBCA
# (Use REST API or Admin UI)

# Use certificate in requests
curl --cert api-client.crt --key api-client.key \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/ca
```

### OAuth 2.0 Integration

```yaml
# Configure OAuth in EJBCA
# System Functions → OAuth Configuration

oauth:
  enabled: true
  provider: azure-ad
  client_id: "your-client-id"
  client_secret: "your-client-secret"
  token_endpoint: "https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token"
  authorization_endpoint: "https://login.microsoftonline.com/{tenant}/oauth2/v2.0/authorize"
  scopes:
    - "https://graph.microsoft.com/.default"
```

---

## Best Practices

### Security Best Practices

1. **Use TLS Everywhere**
   ```bash
   # Always use HTTPS
   # Verify certificates
   curl --cacert ca.crt https://ejbca.local/...
   
   # Never disable certificate verification in production
   # curl -k ... # DON'T DO THIS IN PRODUCTION
   ```

2. **Rotate API Keys Regularly**
   ```bash
   # Rotate every 90 days
   # Keep old key active during transition period
   # Revoke old key after migration complete
   ```

3. **Implement Rate Limiting**
   ```python
   # Client-side rate limiting
   import time
   from ratelimit import limits, sleep_and_retry
   
   @sleep_and_retry
   @limits(calls=100, period=60)  # 100 calls per minute
   def api_call():
       response = requests.post(...)
       return response
   ```

4. **Handle Errors Gracefully**
   ```python
   from requests.adapters import HTTPAdapter
   from requests.packages.urllib3.util.retry import Retry
   
   session = requests.Session()
   retry = Retry(
       total=3,
       backoff_factor=0.3,
       status_forcelist=[500, 502, 503, 504]
   )
   adapter = HTTPAdapter(max_retries=retry)
   session.mount('https://', adapter)
   ```

### Performance Best Practices

1. **Connection Pooling**
   ```python
   # Reuse connections
   session = requests.Session()
   session.headers.update({"X-API-Key": api_key})
   
   # Use session for all requests
   response = session.post(...)
   ```

2. **Batch Operations**
   ```python
   # Instead of issuing certificates one by one
   # Batch multiple requests
   
   def batch_enroll(certificates, batch_size=10):
       for i in range(0, len(certificates), batch_size):
           batch = certificates[i:i+batch_size]
           # Process batch
   ```

3. **Cache CA Certificates**
   ```python
   # Cache CA certificate for reuse
   import functools
   
   @functools.lru_cache(maxsize=10)
   def get_ca_cert(ca_name):
       response = requests.get(f"{base_url}/ca/{ca_name}/certificate")
       return response.content
   ```

### Integration Best Practices

1. **Idempotency**
   ```python
   # Check if operation already completed before retrying
   def ensure_certificate_exists(username):
       # Check if certificate already exists
       existing = search_certificate(username)
       if existing:
           return existing
       
       # Issue new certificate
       return issue_certificate(username)
   ```

2. **Audit Logging**
   ```python
   import logging
   
   logger = logging.getLogger('ejbca_integration')
   
   def issue_certificate(username):
       logger.info(f"Issuing certificate for {username}")
       try:
           result = api_call(...)
           logger.info(f"Certificate issued: {result['serial_number']}")
           return result
       except Exception as e:
           logger.error(f"Failed to issue certificate: {e}")
           raise
   ```

3. **Configuration Management**
   ```python
   # Store configuration in environment or config file
   import os
   from dataclasses import dataclass
   
   @dataclass
   class EJBCAConfig:
       api_url: str = os.getenv("EJBCA_API_URL")
       api_key: str = os.getenv("EJBCA_API_KEY")
       ca_name: str = os.getenv("EJBCA_CA_NAME", "TLS-CA")
       timeout: int = int(os.getenv("EJBCA_TIMEOUT", "30"))
   ```

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| **401 Unauthorized** | Invalid API key | Verify API key is correct and not expired |
| **403 Forbidden** | Insufficient permissions | Check API key has required permissions |
| **404 Not Found** | Wrong endpoint or CA name | Verify URL and CA name |
| **429 Too Many Requests** | Rate limit exceeded | Implement exponential backoff |
| **500 Internal Server Error** | Server-side issue | Check EJBCA logs, retry with backoff |
| **SSL Certificate Verify Failed** | CA cert not trusted | Add CA cert to trusted store |

### Debug Mode

```bash
# Enable verbose output
curl -v -H "X-API-Key: $API_KEY" \
  https://ejbca.local/ejbca/ejbca-rest-api/v1/ca

# Python requests debugging
import logging
import http.client as http_client

http_client.HTTPConnection.debuglevel = 1
logging.basicConfig()
logging.getLogger().setLevel(logging.DEBUG)
requests_log = logging.getLogger("requests.packages.urllib3")
requests_log.setLevel(logging.DEBUG)
requests_log.propagate = True
```

---

## Additional Resources

- [EJBCA REST API Documentation](https://doc.primekey.com/ejbca/ejbca-operations/ejbca-rest-interface)
- [ACME RFC 8555](https://datatracker.ietf.org/doc/html/rfc8555)
- [SCEP RFC 8894](https://datatracker.ietf.org/doc/html/rfc8894)
- [CMP RFC 4210](https://datatracker.ietf.org/doc/html/rfc4210)
- [EST RFC 7030](https://datatracker.ietf.org/doc/html/rfc7030)

---

**Document Version**: 1.0.0  
**Last Updated**: October 2025  
**Maintained By**: Adrian Johnson | adrian207@gmail.com

---

*End of API & Integration Guide*


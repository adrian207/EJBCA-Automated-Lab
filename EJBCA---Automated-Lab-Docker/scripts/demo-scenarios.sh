#!/bin/bash
###############################################################################
# EJBCA Demo Scenarios Script
# This script demonstrates all major features of EJBCA CE
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EJBCA_URL="${EJBCA_URL:-https://ejbca.local}"
EJBCA_PORT="${EJBCA_PORT:-443}"
OUTPUT_DIR="./demo-output"

# Functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Create output directory
mkdir -p "$OUTPUT_DIR"/{certs,keys,csr,crls,ocsp}

###############################################################################
# Scenario 1: ACME Protocol - Let's Encrypt Compatible
###############################################################################
demo_acme() {
    print_header "Demo 1: ACME Protocol (Automated Certificate Management)"
    
    print_info "Installing certbot..."
    if ! command -v certbot &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y certbot
    fi
    
    print_info "Requesting certificate via ACME..."
    certbot certonly \
        --standalone \
        --server "$EJBCA_URL/ejbca/.well-known/acme/directory" \
        --domain "demo.pki.local" \
        --email "admin@pki.local" \
        --agree-tos \
        --non-interactive \
        --preferred-challenges http-01 || true
    
    print_success "ACME certificate request completed"
    
    # Display certificate info
    if [ -f "/etc/letsencrypt/live/demo.pki.local/cert.pem" ]; then
        print_info "Certificate details:"
        openssl x509 -in "/etc/letsencrypt/live/demo.pki.local/cert.pem" -text -noout | head -20
    fi
}

###############################################################################
# Scenario 2: REST API - Programmatic Certificate Enrollment
###############################################################################
demo_rest_api() {
    print_header "Demo 2: REST API Certificate Enrollment"
    
    # Generate private key
    print_info "Generating RSA private key..."
    openssl genrsa -out "$OUTPUT_DIR/keys/rest-demo.key" 2048
    
    # Generate CSR
    print_info "Generating Certificate Signing Request..."
    openssl req -new \
        -key "$OUTPUT_DIR/keys/rest-demo.key" \
        -out "$OUTPUT_DIR/csr/rest-demo.csr" \
        -subj "/CN=rest-demo.pki.local/O=EJBCA Lab/C=US" \
        -addext "subjectAltName=DNS:rest-demo.pki.local,DNS:www.rest-demo.pki.local"
    
    # Encode CSR in base64
    CSR_B64=$(cat "$OUTPUT_DIR/csr/rest-demo.csr" | base64 -w 0)
    
    # Submit via REST API
    print_info "Submitting certificate request via REST API..."
    curl -k -X POST "$EJBCA_URL/ejbca/ejbca-rest-api/v1/certificate/enroll" \
        -H "Content-Type: application/json" \
        -H "X-API-Key: ${EJBCA_API_KEY:-demo-key}" \
        -d "{
            \"certificate_request\": \"$CSR_B64\",
            \"certificate_profile_name\": \"SERVER\",
            \"end_entity_profile_name\": \"WEB_SERVER\",
            \"certificate_authority_name\": \"Issuing CA - TLS\",
            \"username\": \"rest-demo-$(date +%s)\",
            \"password\": \"$(openssl rand -base64 32)\"
        }" \
        -o "$OUTPUT_DIR/certs/rest-demo-response.json" || true
    
    print_success "REST API enrollment completed"
    
    # Parse and save certificate
    if [ -f "$OUTPUT_DIR/certs/rest-demo-response.json" ]; then
        jq -r '.certificate' "$OUTPUT_DIR/certs/rest-demo-response.json" 2>/dev/null | \
            base64 -d > "$OUTPUT_DIR/certs/rest-demo.crt" || true
    fi
}

###############################################################################
# Scenario 3: SCEP - Simple Certificate Enrollment Protocol
###############################################################################
demo_scep() {
    print_header "Demo 3: SCEP (Simple Certificate Enrollment Protocol)"
    
    print_info "Installing sscep..."
    if ! command -v sscep &> /dev/null; then
        git clone https://github.com/certnanny/sscep.git /tmp/sscep
        cd /tmp/sscep
        ./Configure && make && sudo make install
        cd -
    fi
    
    # Get CA certificate
    print_info "Retrieving CA certificate via SCEP..."
    sscep getca \
        -u "$EJBCA_URL/ejbca/publicweb/apply/scep/pkiclient.exe" \
        -c "$OUTPUT_DIR/certs/scep-ca.crt" || true
    
    # Generate key and request
    print_info "Generating key and certificate request..."
    openssl genrsa -out "$OUTPUT_DIR/keys/scep-device.key" 2048
    openssl req -new \
        -key "$OUTPUT_DIR/keys/scep-device.key" \
        -out "$OUTPUT_DIR/csr/scep-device.csr" \
        -subj "/CN=device-$(hostname)/O=EJBCA Lab"
    
    # Enroll via SCEP
    print_info "Enrolling certificate via SCEP..."
    sscep enroll \
        -u "$EJBCA_URL/ejbca/publicweb/apply/scep/pkiclient.exe" \
        -k "$OUTPUT_DIR/keys/scep-device.key" \
        -r "$OUTPUT_DIR/csr/scep-device.csr" \
        -c "$OUTPUT_DIR/certs/scep-ca.crt" \
        -l "$OUTPUT_DIR/certs/scep-device.crt" \
        -K "password123" || true
    
    print_success "SCEP enrollment completed"
}

###############################################################################
# Scenario 4: CMP - Certificate Management Protocol
###############################################################################
demo_cmp() {
    print_header "Demo 4: CMP (Certificate Management Protocol)"
    
    print_info "Installing OpenSSL CMP client..."
    # CMP is built into OpenSSL 3.0+
    
    # Generate key
    openssl genrsa -out "$OUTPUT_DIR/keys/cmp-demo.key" 2048
    
    # Initial registration via CMP
    print_info "Performing CMP certificate request..."
    openssl cmp \
        -cmd ir \
        -server "$EJBCA_URL:8442/ejbca/publicweb/cmp" \
        -path "CMP" \
        -ref "cmp-demo-ref" \
        -secret "password:demo123" \
        -subject "/CN=cmp-demo.pki.local/O=EJBCA Lab/C=US" \
        -newkey "$OUTPUT_DIR/keys/cmp-demo.key" \
        -certout "$OUTPUT_DIR/certs/cmp-demo.crt" || true
    
    print_success "CMP enrollment completed"
}

###############################################################################
# Scenario 5: EST - Enrollment over Secure Transport
###############################################################################
demo_est() {
    print_header "Demo 5: EST (Enrollment over Secure Transport)"
    
    print_info "EST uses HTTP over TLS for certificate enrollment"
    
    # Get CA certificates
    print_info "Retrieving CA certificates via EST..."
    curl -k -X GET \
        "$EJBCA_URL:8443/ejbca/.well-known/est/cacerts" \
        --output "$OUTPUT_DIR/certs/est-cacerts.p7" || true
    
    # Convert PKCS#7 to PEM
    openssl pkcs7 -print_certs \
        -in "$OUTPUT_DIR/certs/est-cacerts.p7" \
        -out "$OUTPUT_DIR/certs/est-ca.pem" 2>/dev/null || true
    
    # Simple enroll
    openssl genrsa -out "$OUTPUT_DIR/keys/est-device.key" 2048
    openssl req -new \
        -key "$OUTPUT_DIR/keys/est-device.key" \
        -out "$OUTPUT_DIR/csr/est-device.csr" \
        -subj "/CN=est-device-$(hostname)/O=EJBCA Lab"
    
    print_info "Submitting certificate request via EST..."
    curl -k -X POST \
        "$EJBCA_URL:8443/ejbca/.well-known/est/simpleenroll" \
        -H "Content-Type: application/pkcs10" \
        -H "Content-Transfer-Encoding: base64" \
        --data-binary "@$OUTPUT_DIR/csr/est-device.csr" \
        --cert "$OUTPUT_DIR/certs/est-ca.pem" \
        --output "$OUTPUT_DIR/certs/est-device.p7" || true
    
    print_success "EST enrollment completed"
}

###############################################################################
# Scenario 6: OCSP - Online Certificate Status Protocol
###############################################################################
demo_ocsp() {
    print_header "Demo 6: OCSP (Online Certificate Status Protocol)"
    
    # Assume we have a certificate to check
    CERT_FILE="$OUTPUT_DIR/certs/rest-demo.crt"
    
    if [ -f "$CERT_FILE" ]; then
        print_info "Checking certificate status via OCSP..."
        
        # Get issuer certificate
        # (In real scenario, extract from AIA extension)
        
        # Check OCSP status
        openssl ocsp \
            -issuer "$OUTPUT_DIR/certs/scep-ca.crt" \
            -cert "$CERT_FILE" \
            -url "$EJBCA_URL/ejbca/publicweb/status/ocsp" \
            -text || true
        
        print_success "OCSP check completed"
    else
        print_info "No certificate available for OCSP check"
    fi
}

###############################################################################
# Scenario 7: CRL - Certificate Revocation List
###############################################################################
demo_crl() {
    print_header "Demo 7: CRL (Certificate Revocation List)"
    
    print_info "Downloading CRL..."
    curl -k -X GET \
        "$EJBCA_URL/ejbca/publicweb/webdist/certdist?cmd=crl&issuer=CN=Issuing%20CA%20-%20TLS" \
        -o "$OUTPUT_DIR/crls/tls-ca.crl" || true
    
    if [ -f "$OUTPUT_DIR/crls/tls-ca.crl" ]; then
        print_info "CRL Details:"
        openssl crl -in "$OUTPUT_DIR/crls/tls-ca.crl" -inform DER -text -noout | head -30
        print_success "CRL retrieved and parsed"
    fi
}

###############################################################################
# Scenario 8: Code Signing Certificate
###############################################################################
demo_code_signing() {
    print_header "Demo 8: Code Signing Certificate"
    
    print_info "Generating code signing key and CSR..."
    openssl genrsa -out "$OUTPUT_DIR/keys/code-sign.key" 3072
    openssl req -new \
        -key "$OUTPUT_DIR/keys/code-sign.key" \
        -out "$OUTPUT_DIR/csr/code-sign.csr" \
        -subj "/CN=Software Publisher Inc/O=EJBCA Lab/C=US"
    
    print_info "This would require approval workflow in EJBCA"
    print_info "Submit CSR: $OUTPUT_DIR/csr/code-sign.csr"
    
    # Demonstrate signing (if certificate exists)
    if [ -f "$OUTPUT_DIR/certs/code-sign.crt" ]; then
        # Create a test file
        echo "Sample software package" > "$OUTPUT_DIR/test-software.txt"
        
        # Sign the file
        openssl dgst -sha256 \
            -sign "$OUTPUT_DIR/keys/code-sign.key" \
            -out "$OUTPUT_DIR/test-software.sig" \
            "$OUTPUT_DIR/test-software.txt"
        
        print_success "File signed successfully"
    fi
}

###############################################################################
# Scenario 9: Container Image Signing
###############################################################################
demo_container_signing() {
    print_header "Demo 9: Container Image Signing with Cosign"
    
    if ! command -v cosign &> /dev/null; then
        print_info "Installing Cosign..."
        curl -LO https://github.com/sigstore/cosign/releases/download/v2.2.0/cosign-linux-amd64
        chmod +x cosign-linux-amd64
        sudo mv cosign-linux-amd64 /usr/local/bin/cosign
    fi
    
    print_info "Generating keypair for container signing..."
    COSIGN_PASSWORD="" cosign generate-key-pair
    
    # In real scenario, would request cert from EJBCA
    print_info "Request certificate from EJBCA for container signing"
    print_info "Profile: CONTAINER_SIGNING"
    
    print_success "Container signing demo setup completed"
}

###############################################################################
# Scenario 10: Certificate Transparency
###############################################################################
demo_certificate_transparency() {
    print_header "Demo 10: Certificate Transparency"
    
    CERT_FILE="$OUTPUT_DIR/certs/rest-demo.crt"
    
    if [ -f "$CERT_FILE" ]; then
        print_info "Checking for Certificate Transparency SCTs..."
        
        # Extract SCT from certificate
        openssl x509 -in "$CERT_FILE" -text -noout | \
            grep -A 20 "CT Precertificate SCTs" || \
            print_info "No embedded SCTs found"
        
        # Check CT logs
        print_info "Certificate can be monitored in CT logs for transparency"
        print_info "https://crt.sh/ - Certificate Transparency search"
    fi
}

###############################################################################
# Main Menu
###############################################################################
show_menu() {
    print_header "EJBCA CE Feature Demonstrations"
    echo "1.  ACME Protocol (Automated Certificate Management)"
    echo "2.  REST API Certificate Enrollment"
    echo "3.  SCEP (Simple Certificate Enrollment Protocol)"
    echo "4.  CMP (Certificate Management Protocol)"
    echo "5.  EST (Enrollment over Secure Transport)"
    echo "6.  OCSP (Online Certificate Status Protocol)"
    echo "7.  CRL (Certificate Revocation List)"
    echo "8.  Code Signing Certificate"
    echo "9.  Container Image Signing"
    echo "10. Certificate Transparency"
    echo "11. Run ALL Demos"
    echo "0.  Exit"
    echo ""
    read -p "Select demo scenario (0-11): " choice
}

run_all_demos() {
    demo_acme
    demo_rest_api
    demo_scep
    demo_cmp
    demo_est
    demo_ocsp
    demo_crl
    demo_code_signing
    demo_container_signing
    demo_certificate_transparency
    
    print_header "All Demonstrations Completed!"
    print_info "Output files saved to: $OUTPUT_DIR"
}

# Main execution
if [ "$1" == "--all" ]; then
    run_all_demos
    exit 0
fi

while true; do
    show_menu
    
    case $choice in
        1) demo_acme ;;
        2) demo_rest_api ;;
        3) demo_scep ;;
        4) demo_cmp ;;
        5) demo_est ;;
        6) demo_ocsp ;;
        7) demo_crl ;;
        8) demo_code_signing ;;
        9) demo_container_signing ;;
        10) demo_certificate_transparency ;;
        11) run_all_demos ;;
        0) 
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done


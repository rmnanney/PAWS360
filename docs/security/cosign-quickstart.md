# Container Image Signing with Cosign

This guide covers how to sign and verify PAWS360 container images using Sigstore's Cosign tool for supply-chain security.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Keyless Signing (Recommended)](#keyless-signing-recommended)
- [Key-Based Signing](#key-based-signing)
- [Verification](#verification)
- [Integration with CI/CD](#integration-with-cicd)
- [Troubleshooting](#troubleshooting)

## Overview

**Why Sign Container Images?**

- **Supply Chain Security**: Verify that images haven't been tampered with
- **Provenance**: Prove who built the image and when
- **Compliance**: Meet security requirements for image attestation
- **Trust**: Ensure images come from authorized sources

**Cosign Features**:

- Keyless signing using OIDC (GitHub, Google, Microsoft)
- Traditional key-based signing with generated keypairs
- Integration with container registries (OCI compliant)
- Support for attestations and SBOMs
- Transparency log via Rekor

## Installation

### macOS

```bash
brew install sigstore/tap/cosign
```

### Linux (Ubuntu/Debian)

```bash
wget https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign
```

### Windows (WSL2)

Use the Linux installation method above.

### Verify Installation

```bash
cosign version
```

## Keyless Signing (Recommended)

Keyless signing uses OpenID Connect (OIDC) for identity verification. No private keys to manage!

### Prerequisites

- GitHub account (or Google/Microsoft account)
- Images pushed to a registry (Docker Hub, GHCR, ECR, etc.)

### Sign an Image

```bash
# Sign using GitHub OIDC
cosign sign --oidc-issuer=https://token.actions.githubusercontent.com \
  ghcr.io/zackhawkins/paws360-backend:v1.0.0

# You'll be prompted to:
# 1. Open a browser for OIDC authentication
# 2. Authorize the signing request
# 3. Signature will be stored in the registry alongside the image
```

### Sign with GitHub Actions

```yaml
# .github/workflows/build-and-sign.yml
name: Build and Sign Images

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: read
  packages: write
  id-token: write  # Required for keyless signing

jobs:
  build-and-sign:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Cosign
        uses: sigstore/cosign-installer@v3
      
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build Image
        run: |
          docker build -t ghcr.io/${{ github.repository }}/backend:${{ github.sha }} .
          docker push ghcr.io/${{ github.repository }}/backend:${{ github.sha }}
      
      - name: Sign Image
        run: |
          cosign sign --yes \
            ghcr.io/${{ github.repository }}/backend:${{ github.sha }}
```

### Verify Keyless Signature

```bash
# Verify using certificate identity
cosign verify \
  --certificate-identity=https://github.com/ZackHawkins/PAWS360/.github/workflows/build-and-sign.yml@refs/tags/v1.0.0 \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  ghcr.io/zackhawkins/paws360-backend:v1.0.0
```

## Key-Based Signing

For offline scenarios or when OIDC isn't available.

### Generate Key Pair

```bash
# Generate cosign keypair (will prompt for password)
cosign generate-key-pair

# Creates:
# - cosign.key (private key - KEEP SECRET!)
# - cosign.pub (public key - share freely)
```

**⚠️ Security Warning**: Store `cosign.key` securely! Consider using:
- Password manager
- Hardware security module (HSM)
- Cloud key management (AWS KMS, Google Cloud KMS, Azure Key Vault)

### Sign with Private Key

```bash
# Local signing
cosign sign --key cosign.key paws360-backend:local

# CI/CD signing (key stored as secret)
cosign sign --key env://COSIGN_PRIVATE_KEY paws360-backend:v1.0.0
```

### Verify with Public Key

```bash
cosign verify --key cosign.pub paws360-backend:local
```

## Verification

### Basic Verification

```bash
# Verify signature exists and is valid
cosign verify --key cosign.pub paws360-backend:v1.0.0

# Expected output:
# Verification for paws360-backend:v1.0.0 --
# The following checks were performed on each of these signatures:
#   - The cosign claims were validated
#   - The signatures were verified against the specified public key
```

### Extract Signature Details

```bash
# View signature in JSON format
cosign verify --key cosign.pub \
  --output json \
  paws360-backend:v1.0.0 | jq .
```

### Verify with Policy

```bash
# Create policy file
cat > policy.yaml <<EOF
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: paws360-images
spec:
  images:
    - glob: "ghcr.io/zackhawkins/paws360-*"
  authorities:
    - keyless:
        url: https://fulcio.sigstore.dev
        identities:
          - issuer: https://token.actions.githubusercontent.com
            subject: https://github.com/ZackHawkins/PAWS360/.*
EOF

# Verify against policy
cosign verify --policy policy.yaml paws360-backend:v1.0.0
```

## Integration with CI/CD

### Automated Signing Pipeline

```yaml
# .github/workflows/secure-build.yml
name: Secure Build Pipeline

on:
  push:
    branches: [main]
    tags: ['v*']

permissions:
  contents: read
  packages: write
  id-token: write

jobs:
  build-sign-verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Tools
        run: |
          # Install Cosign
          curl -sLO https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
          sudo mv cosign-linux-amd64 /usr/local/bin/cosign
          sudo chmod +x /usr/local/bin/cosign
          
          # Install Trivy for scanning
          wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
          echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
          sudo apt-get update && sudo apt-get install -y trivy
      
      - name: Build Image
        run: |
          docker build -t paws360-backend:${{ github.sha }} .
      
      - name: Scan Image
        run: |
          trivy image --severity CRITICAL,HIGH --exit-code 1 paws360-backend:${{ github.sha }}
      
      - name: Tag and Push
        run: |
          docker tag paws360-backend:${{ github.sha }} ghcr.io/${{ github.repository }}/backend:${{ github.sha }}
          docker push ghcr.io/${{ github.repository }}/backend:${{ github.sha }}
      
      - name: Sign Image
        run: |
          cosign sign --yes ghcr.io/${{ github.repository }}/backend:${{ github.sha }}
      
      - name: Verify Signature
        run: |
          cosign verify \
            --certificate-identity=https://github.com/${{ github.repository }}/.github/workflows/secure-build.yml@${{ github.ref }} \
            --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
            ghcr.io/${{ github.repository }}/backend:${{ github.sha }}
      
      - name: Generate SBOM
        run: |
          # Generate Software Bill of Materials
          syft ghcr.io/${{ github.repository }}/backend:${{ github.sha }} -o spdx-json > sbom.spdx.json
          cosign attach sbom --sbom sbom.spdx.json ghcr.io/${{ github.repository }}/backend:${{ github.sha }}
```

### Makefile Integration

```makefile
# Add to Makefile.dev

.PHONY: sign-images
sign-images: ## Sign all custom images with Cosign
	@echo "Signing PAWS360 images..."
	cosign sign --key cosign.key paws360-etcd:local
	cosign sign --key cosign.key paws360-patroni:local
	cosign sign --key cosign.key paws360-redis:local
	cosign sign --key cosign.key paws360-backend:local
	cosign sign --key cosign.key paws360-frontend:local
	@echo "✓ All images signed"

.PHONY: verify-images
verify-images: ## Verify signatures on all custom images
	@echo "Verifying PAWS360 image signatures..."
	cosign verify --key cosign.pub paws360-etcd:local
	cosign verify --key cosign.pub paws360-patroni:local
	cosign verify --key cosign.pub paws360-redis:local
	cosign verify --key cosign.pub paws360-backend:local
	cosign verify --key cosign.pub paws360-frontend:local
	@echo "✓ All signatures verified"
```

## Troubleshooting

### Signature Not Found

**Problem**: `Error: no matching signatures`

**Solutions**:
1. Ensure image was actually signed: `cosign tree <image>`
2. Check if using correct registry and tag
3. Verify signature wasn't deleted or overwritten

### OIDC Authentication Fails

**Problem**: `Error: getting signer: getting keyless signer: failed to get access token`

**Solutions**:
1. Ensure `id-token: write` permission in GitHub Actions
2. Check network connectivity to token issuer
3. Verify OIDC issuer URL is correct

### Verification Fails

**Problem**: `Error: signature verification failed`

**Solutions**:
1. Ensure using correct public key (`cosign.pub`)
2. For keyless, verify certificate identity matches
3. Check if image has been modified after signing
4. Verify signature wasn't created with different key

### Image Modified After Signing

**Problem**: `Error: image digest changed`

**Solutions**:
- Re-sign the image after modifications
- Use immutable tags (digests) instead of mutable tags
- Implement policy to prevent image overwrites

## Best Practices

1. **Use Keyless Signing**: Leverage OIDC for zero key management
2. **Sign on Push**: Automate signing in CI/CD pipeline
3. **Verify on Pull**: Always verify signatures before deployment
4. **Immutable Tags**: Use digest-based references for production
5. **Attestations**: Attach build provenance and SBOMs
6. **Audit Logs**: Monitor Rekor transparency log for your images
7. **Policy Enforcement**: Use admission controllers (Kyverno, OPA) to enforce signature verification

## Additional Resources

- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [Sigstore](https://www.sigstore.dev/)
- [Rekor Transparency Log](https://rekor.sigstore.dev/)
- [Fulcio Certificate Authority](https://github.com/sigstore/fulcio)
- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

## Related Documentation

- [Image Scanning with Trivy](../reference/image-scanning.md)
- [Runtime Hardening](runtime-hardening.md)
- [Security Best Practices](security-best-practices.md)

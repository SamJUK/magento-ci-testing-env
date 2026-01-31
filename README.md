# Docker Images for Magento Testing

[![Build and Push](https://github.com/SamJUK/magento-ci-testing-env/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/SamJUK/magento-ci-testing-env/actions/workflows/build-and-push.yml)
[![Security Scan](https://github.com/SamJUK/magento-ci-testing-env/actions/workflows/secret-scan-pr.yml/badge.svg)](https://github.com/SamJUK/magento-ci-testing-env/actions/workflows/security-scan.yml)

A collection of docker images, aimed at facilitating Unit / Integration / E2E testing Magento modules & stores within CI Pipelines.

The main aim of these set of images, is to keep the Image size as small as possible. This allows for faster test executions, quicker builds and reduced pipelines costs. Especially important if your building and testing your modules across multiple Magento / PHP versions.

## 📦 Available Images

Image Name | Size (Compressed) | Docker Hub | GitHub Container Registry
--- | --- | --- | ---
magento-base-ci-testing-env | 50 MB | [Docker Hub](https://hub.docker.com/r/samjuk/magento-base-ci-testing-env/tags?ordering=name) | [GHCR](https://github.com/SamJUK/magento-ci-testing-env/pkgs/container/magento-base-ci-testing-env)
magento-ci-testing-env | 198 MB | [Docker Hub](https://hub.docker.com/r/samjuk/magento-ci-testing-env/tags?ordering=name) | [GHCR](https://github.com/SamJUK/magento-ci-testing-env/pkgs/container/magento-ci-testing-env)
mage-os-ci-testing-env | 190 MB | [Docker Hub](https://hub.docker.com/r/samjuk/mage-os-ci-testing-env/tags?ordering=name) | [GHCR](https://github.com/SamJUK/magento-ci-testing-env/pkgs/container/mage-os-ci-testing-env)

### 🏷️ Image Tagging Strategy

All images are available with two tagging formats:

1. **Rolling Release Tags** (recommended for CI): Updated with each release
   - Base images: `8.3`, `8.2`, `8.1`, `8.4`
   - Application images: `2.4.8-php8.3`, `2.4.7-p8-php8.2`, etc.

2. **Pinned Release Tags**: Locked to specific release versions
   - Base images: `8.3-v1.0.0`, `8.2-v1.0.0`
   - Application images: `2.4.8-php8.3-v1.0.0`, `2.4.7-p8-php8.2-v1.0.0`

#### Examples

```bash
# Using rolling tags (automatically get updates)
docker pull samjuk/magento-ci-testing-env:2.4.8-php8.3
docker pull ghcr.io/samjuk/magento-base-ci-testing-env:8.3

# Using pinned tags (locked to specific release)
docker pull samjuk/magento-ci-testing-env:2.4.8-php8.3-v1.0.0
docker pull ghcr.io/samjuk/magento-base-ci-testing-env:8.3-v1.0.0
```

## 🔒 Security & Attestations

All images are:
- ✅ Scanned for vulnerabilities with Trivy (HIGH/CRITICAL severity)
- ✅ Signed with Cosign (keyless signing via Sigstore)
- ✅ Include SBOM (Software Bill of Materials) in SPDX/CycloneDX format
- ✅ Include provenance attestations for supply chain security
- ✅ Scanned weekly for new vulnerabilities


## 📋 Usage

### For Module Testing

For testing Magento modules, use either the `magento-ci-testing-env` or `mage-os-ci-testing-env` images.

This allows you to save a substantial amount of wasted build time creating a Magento project against.

**Example:**
```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/samjuk/magento-ci-testing-env:2.4.8-php8.3
      # https://github.com/actions/runner/issues/878#issuecomment-1290921350
      options:
        --user 1001:1001
        -v "${{github.workspace}}":"${{github.workspace}}"
    steps:
      # https://github.com/actions/runner/issues/878#issuecomment-1290921350
      - run: cp -R /var/www/html/* ${{ github.workspace }}/
      - uses: actions/checkout@v4
        with:
          path: ./extensions/${{ github.event.repository.name }}
      - run: |
          EXT_NAME=$(cat ./extensions/${{ github.event.repository.name }}/composer.json | jq -r '.name')
          composer require -W --prefer-source ${EXT_NAME}:@dev
        env:
          COMPOSER_NO_SECURITY_BLOCKING: 1
      - name: Run Unit Tests
        run: |
          vendor/bin/phpunit ${{ inputs.test_directory }}
```

### For Project Testing

For testing Magento projects, use the `magento-base-ci-testing-env` image. To keep the image small, as you do not need the preinstalled Magento application.

**Example:**
```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/samjuk/magento-base-ci-testing-env:8.3
      # https://github.com/actions/runner/issues/878#issuecomment-1290921350
      options:
        --user 1001:1001
        -v "${{github.workspace}}":"${{github.workspace}}"
    steps:
      - uses: actions/checkout@v4
      - run: composer install
      - run: vendor/bin/phpunit
```

## 🔐 Verifying Image Signatures

All images are signed with Cosign. You can verify the signature:

```bash
# Install cosign
brew install cosign  # macOS
# or download from https://github.com/sigstore/cosign/releases

# Verify image signature
cosign verify \
  --certificate-identity-regexp="https://github.com/SamJUK/magento-ci-testing-env" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/samjuk/magento-ci-testing-env:2.4.8-php8.3
```

## 🛠️ Building Images

Images are automatically built and published when a new tag is pushed:

```bash
# Create a new release
git tag v1.0.0
git push origin v1.0.0
```

For manual builds, use the [Manual Build workflow](https://github.com/SamJUK/magento-ci-testing-env/actions/workflows/manual-build.yml) in GitHub Actions.

## 🩹 Patches
Some older core Magento versions have known installation issues that we need to patch during the image build process. 
We aim to handle all these via composer patches at build time, to ensure we do not skip any images, and keep the patches maintainable going forward.

If we have patches / operations that cannot be handled via composer, we also have functionality within the `scripts` folder to run custom PHP / shell scripts during the image build process.

## 📊 Supported Versions

Check [`manifest.json`](manifest.json) for the complete list of supported PHP and Magento/Mage-OS versions.

## 📝 License

See [LICENSE](LICENSE) file for details.
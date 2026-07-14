#!/usr/bin/env bash
# Quick "does it run" check for a built image. Not a substitute for tests/unit,
# tests/integration or tests/e2e - just confirms the image boots and its
# primary CLI entrypoint doesn't error.

set -e

CLR_RED='\033[1;31m'
CLR_GREEN='\033[1;32m'
CLR_NC='\033[0m'

IMAGE_TAG=$1
BUILD_TYPE=$2

if [ -z "$IMAGE_TAG" ] || [ -z "$BUILD_TYPE" ]; then
  echo "Usage: $0 <image-tag> <base|magento>"
  exit 1
fi

case "$BUILD_TYPE" in
  base)
    CMD="php -v"
    ;;
  magento)
    CMD="php bin/magento --version"
    ;;
  *)
    echo -e "${CLR_RED}[✗] Unknown build type: $BUILD_TYPE (expected 'base' or 'magento')${CLR_NC}"
    exit 1
    ;;
esac

echo "[i] Smoke testing $IMAGE_TAG ($BUILD_TYPE): running \`$CMD\`"

set +e
OUTPUT=$(docker run --rm "$IMAGE_TAG" sh -c "$CMD" 2>&1)
STATUS=$?
set -e

if [ $STATUS -ne 0 ]; then
  echo -e "${CLR_RED}[✗] Smoke test failed for $IMAGE_TAG${CLR_NC}"
  echo "$OUTPUT"
  exit 1
fi

echo "$OUTPUT"
echo -e "${CLR_GREEN}[✓] Smoke test passed for $IMAGE_TAG${CLR_NC}"

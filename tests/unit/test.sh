#!/usr/bin/env sh
# This set is to ensure the built image is able to run PHPUnit tests

set -e

CLR_RED='\033[1;31m'
CLR_GREEN='\033[1;32m'
CLR_GREY='\033[0;37m'
CLR_NC='\033[0m'

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IMAGE_TAG=$1
if [ -z "$IMAGE_TAG" ]; then
  echo "Usage: $0 <image-tag>"
  exit 1
fi

CONTAINER_NAME=$(echo "testenv-unt-$IMAGE_TAG" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]')
if [ "$(echo "$@" | grep -- '--no-cleanup' || true)" = "" ]; then
  trap 'docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1' EXIT
fi

echo "[i] Starting test container: ${CONTAINER_NAME}"
docker run -d --name "$CONTAINER_NAME" \
    -v "${CWD}/../.fixtures/example-module:/var/www/html/extensions/acme-example-module:ro" \
    "$IMAGE_TAG"

set +e

echo "[i] Install the module via composer"
docker exec "$CONTAINER_NAME" sh -c 'composer require acme/example-module:@dev --no-interaction'
if [ $? -ne 0 ]; then
  echo -e "${CLR_RED}[✗] Failed to install module via composer.${CLR_NC}"
  exit 1
fi

echo "[i] Run PHPUnit Unit tests for the module"
docker exec "$CONTAINER_NAME" sh -c 'vendor/bin/phpunit extensions/acme-example-module/Test/Unit'
if [ $? -ne 0 ]; then
  echo -e "${CLR_RED}[✗] PHPUnit tests failed.${CLR_NC}"
  exit 1
fi

echo -e "${CLR_GREEN}[✓] All PHPUnit tests passed successfully.${CLR_NC}"
exit 0
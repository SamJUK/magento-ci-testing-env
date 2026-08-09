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

PROJECT_NAME=$(echo "testenv-int-$IMAGE_TAG" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]')
if [ "$(echo "$@" | grep -- '--no-cleanup' || true)" = "" ]; then
  trap 'docker compose -p "$PROJECT_NAME" -f "${CWD}/../.fixtures/docker-environment/docker-compose.yaml" down -v || true' EXIT
fi

# Bootstrap Environment
export PROJECT_NAME IMAGE_TAG
sh "${CWD}/../.fixtures/docker-environment/bootstrap.sh"

echo "[i] Copying integration test configuration into container..."
docker compose -p "$PROJECT_NAME" -f "${CWD}/../.fixtures/docker-environment/docker-compose.yaml" cp \
  "${CWD}/install-config-mysql.php" "app:/var/www/html/dev/tests/integration/etc/install-config-mysql.php"

echo "[i] Copy PHPUnit.xml configuration into container..."
docker compose -p "$PROJECT_NAME" -f "${CWD}/../.fixtures/docker-environment/docker-compose.yaml" cp \
  "${CWD}/phpunit.xml" "app:/var/www/html/dev/tests/integration/phpunit.xml"

set +e
echo "[i] Install the module via composer"
docker compose -p "$PROJECT_NAME" -f "${CWD}/../.fixtures/docker-environment/docker-compose.yaml" exec -T app \
  sh -c 'composer require acme/example-module:@dev --no-interaction'
if [ $? -ne 0 ]; then
  echo -e "${CLR_RED}[✗] Failed to install module via composer.${CLR_NC}"
  exit 1
fi


# Hacky Fixes
docker compose -p "$PROJECT_NAME" -f "${CWD}/../.fixtures/docker-environment/docker-compose.yaml" exec -T app \
  sh -c 'apk add --no-cache mysql-client'

echo "[i] Run PHPUnit integration tests for the module"
docker compose -p "$PROJECT_NAME" -f "${CWD}/../.fixtures/docker-environment/docker-compose.yaml" exec -T app \
  sh -c 'vendor/bin/phpunit -c dev/tests/integration/phpunit.xml extensions/acme-example-module/Test/Integration'
if [ $? -ne 0 ]; then
  echo -e "${CLR_RED}[✗] PHPUnit tests failed.${CLR_NC}"
  exit 1
fi

echo -e "${CLR_GREEN}[✓] All PHPUnit tests passed successfully.${CLR_NC}"
exit 0
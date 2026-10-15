#!/usr/bin/env sh

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

PROJECT_NAME=$(echo "testenv-e2e-$IMAGE_TAG" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]')
if [ "$(echo "$@" | grep -- '--no-cleanup' || true)" = "" ]; then
  trap 'docker compose -p "$PROJECT_NAME" -f "${CWD}/docker-compose.yaml" down -v || true' EXIT
fi

# Bootstrap the docker environment
export PROJECT_NAME IMAGE_TAG
sh "${CWD}/../.fixtures/docker-environment/bootstrap.sh"

# Install a fresh Magento instance
echo -e "[i] Installing Magento in test environment...${CLR_GREY}"
docker compose -p "$PROJECT_NAME" -f "${CWD}/docker-compose.yaml" exec -T app \
  php bin/magento setup:install \
    --base-url=http://localhost:8080/ \
    --db-host=db \
    --db-name=magento \
    --db-user=magento \
    --db-password=magento \
    --admin-firstname=Admin \
    --admin-lastname=User \
    --admin-email=admin@example.com \
    --admin-user=admin \
    --admin-password=admin123 \
    --language=en_GB \
    --currency=GBP \
    --timezone=Europe/London \
    --use-rewrites=1 \
    --session-save=redis \
    --session-save-redis-host=redis \
    --session-save-redis-port=6379 \
    --session-save-redis-db=2 \
    --cache-backend=redis \
    --cache-backend-redis-server=redis \
    --cache-backend-redis-db=0 \
    --elasticsearch-host=elasticsearch \
    --elasticsearch-port=9200 \
    --elasticsearch-index-prefix=magento2 \
    --elasticsearch-enable-auth=0 \
    --search-engine=elasticsearch8
echo -e "${CLR_NC}[i] Magento installation complete."

# Rebuild assets, install have just nuked
echo -e "[i] Rebuilding assets...${CLR_GREY}"
docker compose -p "$PROJECT_NAME" -f "${CWD}/docker-compose.yaml" exec -T app \
  php bin/magento setup:static-content:deploy -f
echo -e "${CLR_NC}[i] Asset rebuild complete."

# Run a few smoke tests
echo "[i] Running smoke tests..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ | grep -q "200" && \
  echo -e "${CLR_GREEN}[i] Frontend is accessible.${CLR_NC}" || \
  (echo -e "${CLR_RED}[!] Frontend is not accessible.${CLR_NC}" && exit 1)
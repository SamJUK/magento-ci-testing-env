#!/usr/bin/env sh
# This script handles bootstrapping the docker environment for tests
# 
# Usage: PROJECT_NAME=X IMAGE_TAG=x ./bootstrap.sh

set -e

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

usage() {
    echo "Usage: PROJECT_NAME=<project-name> IMAGE_TAG=<image-tag> $0"
    exit 1
}

if [ -z "$PROJECT_NAME" ] || [ -z "$IMAGE_TAG" ]; then
    usage
fi

# Get Software Requirements:
echo "[i] Fetching software requirements for image tag: $IMAGE_TAG"
VERSION=$(echo "$IMAGE_TAG" | awk -F/ '{print $2}' | sed -E 's/(-p[0-9]+)*-php[0-9.]*$//')
REQUIREMENTS_FILE="${CWD}/software-requirements.yaml"
REQUIREMENTS=$(yq ".\"$VERSION\"" "$REQUIREMENTS_FILE")
VERS_MYSQL=$(echo "$REQUIREMENTS" | yq '.mysql')
VERS_SEARCH=$(echo "$REQUIREMENTS" | yq '.elasticsearch')
VERS_REDIS=$(echo "$REQUIREMENTS" | yq '.redis')

# Run Docker Compose with appropriate environment variables
echo "[i] Starting test environment: ${PROJECT_NAME}"
export IMAGE_TAG VERS_MYSQL VERS_SEARCH VERS_REDIS
docker compose -p "$PROJECT_NAME" -f "${CWD}/docker-compose.yaml" up -d --force-recreate

# Temporary until updated in container
echo "[i] Correcting permissions for Magento files..."
docker compose -p "$PROJECT_NAME" -f "${CWD}/docker-compose.yaml" exec -T app \
  chown -R www-data:www-data /var/www/html/ \
  && find /var/www/html/ -type d -exec chmod 755 {} + \
  && find /var/www/html/ -type f -exec chmod 644 {} + \
  && chmod 755 /var/www/html/bin/magento
echo "[i] Permissions corrected."

# Wait for MySQL to be ready
printf "[i] Waiting for MySQL to be ready..."
docker compose -p "$PROJECT_NAME" -f "${CWD}/docker-compose.yaml" exec -T db \
  sh -c '
    until mysql -h "localhost" -u"magento" -p"magento" -e "SELECT 1" >/dev/null 2>&1; do
      printf "."
      sleep 1
    done'
printf "\n[i] MySQL is ready.\n"

# Wait for Elasticsearch to be ready
printf "[i] Waiting for Elasticsearch to be ready..."
docker compose -p "$PROJECT_NAME" -f "${CWD}/docker-compose.yaml" exec -T app \
  sh -c '
    until curl -s http://elasticsearch:9200 >/dev/null 2>&1; do
      printf "."
      sleep 1
    done'
printf "\n[i] Elasticsearch is ready.\n"
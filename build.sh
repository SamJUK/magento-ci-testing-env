#!/usr/bin/env bash

set -e

PUSH=false
FORCE_BUILD=false
DOCKER_NAMESPACE=${DOCKER_NAMESPACE:-samjuk}

CLR_RED='\033[1;31m'
CLR_GREEN='\033[1;32m'
CLR_YELLOW='\033[1;33m'
CLR_GREY='\033[0;30m'
CLR_NC='\033[0m' # No Color

for arg in "$@"; do
    if [ "$arg" == "--force" ]; then
        FORCE_BUILD=true
    elif [ "$arg" == "--push" ]; then
        PUSH=true
    fi
done

does_image_exist() {
    local IMAGE_TAG=$1
    if [ "$(docker images -q $IMAGE_TAG 2> /dev/null)" == "" ]; then
        return 1
    else
        return 0
    fi
}

build_base () {
    local PHP_VERSION=$1
    local TAG="$DOCKER_NAMESPACE/magento-base-ci-testing-env:$PHP_VERSION"

    if ! $FORCE_BUILD && does_image_exist $TAG; then
        echo -e "ℹ️ ${CLR_GREY}Base image $TAG already exists. Skipping build.${CLR_NC}"
        return
    fi

    echo -e "${CLR_GREY}[i] Building base image $TAG ... ${CLR_NC}"

    set +e 
    docker build -f base/Dockerfile base -t $TAG \
        --platform linux/amd64 \
        --build-arg PHP_VERSION=$PHP_VERSION

    if [ $? -ne 0 ]; then
        echo -e "${CLR_RED}❌ Failed to build image $TAG${CLR_NC}"
        exit 1
    fi

    set -e

    if $PUSH; then
        docker push $TAG
    fi
}

build_application() {
    local APP_DISTRO=$1
    local APP_VERSION=$2
    local PHP_VERSION=$3
    local TAG="$DOCKER_NAMESPACE/$APP_DISTRO-ci-testing-env:$APP_VERSION-php$PHP_VERSION"

    if ! $FORCE_BUILD && does_image_exist $TAG; then
        echo -e "ℹ️ ${CLR_GREY}Magento image $TAG already exists. Skipping build.${CLR_NC}"
        return
    fi

    echo -e "${CLR_GREY}[i] Building Magento image $TAG ... ${CLR_NC}"
    set +e
    docker build -f magento/Dockerfile magento -t $TAG \
        --platform linux/amd64 \
        --build-arg APP_DISTRO=$APP_DISTRO \
        --build-arg APP_VERSION=$APP_VERSION \
        --build-arg PHP_VERSION=$PHP_VERSION
    
    if [ $? -ne 0 ]; then
        echo -e "${CLR_RED}❌ Failed to build image $TAG${CLR_NC}"
        exit 1
    fi
    set -e

    if $PUSH; then
        docker push $TAG
    fi
}



for PHP_VER in $(jq -r 'keys_unsorted | join(" ")' manifest.json ); do 
  echo "[i] Building for PHP version: $PHP_VER"
  build_base "$PHP_VER"

  for PLATFORM in $(jq -r --arg PHP "$PHP_VER" '.[$PHP] | keys_unsorted | join(" ")' manifest.json); do
    echo "[i] Building for platform: $PLATFORM on PHP $PHP_VER"
    for APP_VERSION in $(jq -r --arg PLATFORM "$PLATFORM" --arg PHP "$PHP_VER" '.[$PHP] .[$PLATFORM] | join(" ")' manifest.json); do
        build_application "$PLATFORM" "$APP_VERSION" "$PHP_VER"
    done
  done
done

echo -e "✅ ${CLR_GREEN}All builds completed successfully.${CLR_NC}"
#!/usr/bin/env bash

set -e

FORCE_BUILD=false

for arg in "$@"; do
    if [ "$arg" == "--force" ]; then
        FORCE_BUILD=true
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
    local TAG="samjuk/magento-base-ci-testing-env:$PHP_VERSION"

    if ! $FORCE_BUILD && does_image_exist $TAG; then
        echo "Base image $TAG already exists. Skipping build."
        return
    fi

    echo "Building base image $TAG ..."
    docker build -f base/Dockerfile base -t $TAG \
        --platform linux/amd64 \
        --build-arg PHP_VERSION=$PHP_VERSION
}

build_application() {
    local APP_DISTRO=$1
    local APP_VERSION=$2
    local PHP_VERSION=$3
    local TAG="samjuk/$APP_DISTRO-ci-testing-env:$APP_VERSION-php$PHP_VERSION"

    if ! $FORCE_BUILD && does_image_exist $TAG; then
        echo "Magento image $TAG already exists. Skipping build."
        return
    fi

    echo "Building Magento image $TAG ..."
    docker build -f magento/Dockerfile magento -t $TAG \
        --platform linux/amd64 \
        --build-arg APP_DISTRO=$APP_DISTRO \
        --build-arg APP_VERSION=$APP_VERSION \
        --build-arg PHP_VERSION=$PHP_VERSION

    docker push $TAG
}



for PHP_VER in $(jq -r 'keys_unsorted | join(" ")' manifest.json ); do 
  echo "Building for PHP version: $PHP_VER"
  build_base "$PHP_VER"

  for PLATFORM in $(jq -r --arg PHP "$PHP_VER" '.[$PHP] | keys_unsorted | join(" ")' manifest.json); do
    echo "Building for platform: $PLATFORM"
    for APP_VERSION in $(jq -r --arg PLATFORM "$PLATFORM" --arg PHP "$PHP_VER" '.[$PHP] .[$PLATFORM] | join(" ")' manifest.json); do
        echo "Building $PLATFORM version: $APP_VERSION for PHP $PHP_VER"
        build_application "$PLATFORM" "$APP_VERSION" "$PHP_VER"
        # sleep 5
    done
  done
done

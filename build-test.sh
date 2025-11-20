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

build_base() {
    local PHP_VERSION=$1
    local TAG="samjuk/magento-base-ci-testing-env:$PHP_VERSION"

    if ! $FORCE_BUILD && does_image_exist $TAG; then
        echo "Base image $TAG already exists. Skipping build."
        return
    fi

    echo "Building base image $TAG ..."
    docker build -f base/Dockerfile base \
        --platform linux/amd64 \
        -t $TAG \
        --build-arg PHP_VERSION=$PHP_VERSION
}

build_magento() {
    local APP_DISTRO=$1
    local APP_VERSION=$2
    local PHP_VERSION=$3
    local TAG="samjuk/$APP_DISTRO-ci-testing-env:$APP_VERSION-php$PHP_VERSION"

    if ! $FORCE_BUILD && does_image_exist $TAG; then
        echo "Base image $TAG already exists. Skipping build."
        return
    fi

    echo "Building Magento image $TAG ..."
    docker build -f magento/Dockerfile magento \
        -t $TAG \
        --platform linux/amd64 \
        --build-arg APP_DISTRO=$APP_DISTRO \
        --build-arg APP_VERSION=$APP_VERSION \
        --build-arg PHP_VERSION=$PHP_VERSION

    docker push $TAG
}

echo "[+] Building Base Docker images..."
build_base "8.4"
build_base "8.3"
build_base "8.2"
build_base "8.1"

echo "[+] Building Magento Docker image..."
# build_magento "mage-os" "2.0" "8.4"
# build_magento "mage-os" "2.0" "8.3"
# build_magento "mage-os" "1.3.1" "8.3"
# build_magento "mage-os" "1.3.0" "8.3"
# build_magento "mage-os" "1.2.0" "8.3"
# build_magento "mage-os" "1.1.0" "8.3"

# build_magento "mage-os" "1.0.6" "8.3"
# build_magento "mage-os" "1.0.5" "8.3"
# build_magento "mage-os" "1.0.4" "8.3"
# build_magento "mage-os" "1.0.3" "8.3"
# build_magento "mage-os" "1.0.2" "8.3"
# build_magento "mage-os" "1.0.6" "8.2"
# build_magento "mage-os" "1.0.5" "8.2"
# build_magento "mage-os" "1.0.4" "8.2"
# build_magento "mage-os" "1.0.3" "8.2"
# build_magento "mage-os" "1.0.2" "8.2"

# build_magento "mage-os" "1.0.1" "8.2"
# build_magento "mage-os" "1.0.0" "8.2"
# build_magento "mage-os" "1.0.1" "8.1"
# build_magento "mage-os" "1.0.0" "8.1"

# build_magento "magento" "2.4.8-p3" "8.4"
# build_magento "magento" "2.4.8-p3" "8.3"
# build_magento "magento" "2.4.7-p8" "8.3"
# build_magento "magento" "2.4.7-p8" "8.2"
# build_magento "magento" "2.4.6-p13" "8.2"
# build_magento "magento" "2.4.6-p13" "8.1"
# # build_magento "magento" "2.4.5-p14" "8.1"
# build_magento "magento" "2.4.4-p13" "8.1" # P13 is last non EE release
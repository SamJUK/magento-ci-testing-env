#!/usr/bin/env bash

set -e

PULL=false
PUSH=false
FORCE_BUILD=false
DOCKER_NAMESPACE=${DOCKER_NAMESPACE:-samjuk}

CLR_RED='\033[1;31m'
CLR_GREEN='\033[1;32m'
CLR_YELLOW='\033[1;33m'
CLR_GREY='\033[0;30m'
CLR_NC='\033[0m' # No Color

POSITIONAL_ARGS=()
for arg in "$@"; do
    if [ "$arg" == "--force" ]; then
        FORCE_BUILD=true
    elif [ "$arg" == "--push" ]; then
        PUSH=true
    elif [ "$arg" == "--pull" ]; then
        PULL=true
    else
        POSITIONAL_ARGS+=("$arg")
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

    if $PULL; then
        echo -e "${CLR_GREY}[i] Pulling latest image for $TAG ... ${CLR_NC}"
        docker pull $TAG || echo -e "${CLR_YELLOW}⚠️  Could not pull image $TAG. It may not exist yet.${CLR_NC}"
    fi

    if ! $FORCE_BUILD && does_image_exist $TAG; then
        echo -e "ℹ️ ${CLR_GREY}Base image $TAG already exists. Skipping build.${CLR_NC}"
        return
    fi

    echo -e "${CLR_GREY}[i] Building base image $TAG ... ${CLR_NC}"

    set +e 
    DOCKER_OUTPUT=$(docker build -f src/base/Dockerfile src/base -t $TAG \
        --platform linux/amd64 \
        --build-arg PHP_VERSION=$PHP_VERSION 2>&1)
        
    if [ $? -ne 0 ]; then
        echo -e "${CLR_RED}❌ Failed to build image $TAG${CLR_NC}"
        echo -e "${CLR_GREY}--- Docker Build Output ---${CLR_NC}"
        echo "$DOCKER_OUTPUT"
        echo -e "${CLR_GREY}---------------------------${CLR_NC}"
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

    if $PULL; then
        echo -e "${CLR_GREY}[i] Pulling latest image for $TAG ... ${CLR_NC}"
        docker pull $TAG || echo -e "${CLR_YELLOW}⚠️  Could not pull image $TAG. It may not exist yet.${CLR_NC}"
    fi

    if ! $FORCE_BUILD && does_image_exist $TAG; then
        echo -e "ℹ️ ${CLR_GREY}Magento image $TAG already exists. Skipping build.${CLR_NC}"
        return
    fi

    echo -e "${CLR_GREY}[i] Building Magento image $TAG ... ${CLR_NC}"
    set +e
    DOCKER_OUTPUT=$(docker build -f src/magento/Dockerfile src/magento -t $TAG \
        --platform linux/amd64 \
        --build-arg APP_DISTRO=$APP_DISTRO \
        --build-arg APP_VERSION=$APP_VERSION \
        --build-arg PHP_VERSION=$PHP_VERSION 2>&1)
    
    if [ $? -ne 0 ]; then
        echo -e "${CLR_RED}❌ Failed to build image $TAG${CLR_NC}"
        echo -e "${CLR_GREY}--- Docker Build Output ---${CLR_NC}"
        echo "$DOCKER_OUTPUT"
        echo -e "${CLR_GREY}---------------------------${CLR_NC}"
        exit 1
    fi

    UNIT_TEST_OUTPUT=$(sh tests/unit/test.sh "$TAG" 2>&1)
    if [ $? -ne 0 ]; then
        echo -e "${CLR_RED}❌ Unit tests failed for image $TAG${CLR_NC}"
        echo -e "${CLR_GREY}--- Unit Test Output ---${CLR_NC}"
        echo "$UNIT_TEST_OUTPUT"
        echo -e "${CLR_GREY}------------------------${CLR_NC}"
        exit 1
    else
        echo -e "${CLR_GREEN}✅ Unit tests passed for image $TAG${CLR_NC}"
    fi

    set -e

    if $PUSH; then
        docker push $TAG
    fi

    docker image rm $TAG >/dev/null 2>&1 || true
}

# check if positional argument exists
if [ ${#POSITIONAL_ARGS[@]} -gt 0 ]; then
    IMAGE_TAG=${POSITIONAL_ARGS[0]}
    # Explode tag in components
    PLATFORM=$(echo "$IMAGE_TAG"| awk -F/ '{print $2}' | awk -F: '{print $1}' | sed 's/-ci-testing-env//')
    VERSION_TAG=$(echo "$IMAGE_TAG" | awk -F: '{print $2}')
    APP_VERSION=$(echo "$VERSION_TAG" | sed 's/-php.*$//')
    PHP_VERSION=$(echo "$VERSION_TAG" | sed 's/^.*-php//')

    if [ "$PLATFORM" == "magento-base" ]; then
        ! [[ "$PHP_VERSION" =~ ^[0-9]+\.[0-9]+$ ]] && echo -e "${CLR_RED}❌ Invalid PHP version extracted from tag: $PHP_VERSION${CLR_NC}" && exit 1

        build_base "$PHP_VERSION"
        echo -e "✅ ${CLR_GREEN}Build completed successfully for $IMAGE_TAG.${CLR_NC}"
        exit 0
    else
        ! [[ "$PHP_VERSION" =~ ^[0-9]+\.[0-9]+$ ]] && echo -e "${CLR_RED}❌ Invalid PHP version extracted from tag: $PHP_VERSION${CLR_NC}" && exit 1
        ! [[ "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-p[0-9]+)?$ ]] && echo -e "${CLR_RED}❌ Invalid Application version extracted from tag: $APP_VERSION${CLR_NC}" && exit 1
        [ "$PLATFORM" != "magento" ] && [ "$PLATFORM" != "mage-os" ] && echo -e "${CLR_RED}❌ Invalid platform extracted from tag: $PLATFORM${CLR_NC}" && exit 1

        build_application "$PLATFORM" "$APP_VERSION" "$PHP_VERSION"
        echo -e "✅ ${CLR_GREEN}Build completed successfully for $IMAGE_TAG.${CLR_NC}"
        exit 0
    fi
fi

# Matrix if no image passed
[ ! -f manifest.json ] && echo -e "${CLR_RED}❌ manifest.json file not found!${CLR_NC}" && exit 1

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
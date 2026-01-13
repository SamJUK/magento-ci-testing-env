ARG PHP_VERSION=8.3
FROM samjuk/magento-base-ci-testing-env:${PHP_VERSION}

ARG APP_DISTRO=magento
ARG APP_VERSION=2.4.8

ENV MAGE_MODE=production

# Download Application
RUN --mount=type=cache,target=/tmp/cache \
    set -e; \
    if [ "${APP_DISTRO}" != "magento" ] && [ "${APP_DISTRO}" != "mage-os" ]; then \
        echo "Error: APP_DISTRO must be either 'magento' or 'mage-os'. \"${APP_DISTRO}\" provided."; \
        exit 1; \
    fi; \
    [ "${APP_DISTRO}" = "magento" ] && REPO="https://mirror.sdj.pw/magento/" || REPO="https://repo.mage-os.org/"; \
    composer create-project -vv --prefer-dist --repository-url=${REPO} ${APP_DISTRO}/project-community-edition:${APP_VERSION} . \
    && composer clear-cache
    # Image size optimizations;
    # && find vendor/magento -type d \( -iname 'test' -o -iname 'tests' \) -exec rm -rf {} +
    # && rm -rf dev

# Configure Local Extensions Directory
RUN mkdir -p extensions && \
    composer config repositories.local path ./extensions/*

# Allow Composer Plugins
RUN composer config --no-plugins allow-plugins.phpstan/extension-installer true && \
    composer config --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true \
    composer config --no-plugins allow-plugins.magento/* true

# Install Additional Packages
RUN composer require --dev \
    phpstan/phpstan \
    bitexpert/phpstan-magento \
    phpstan/extension-installer \
    && composer clear-cache

# Setup Magento
COPY merge-default-scope-config.php .
RUN php bin/magento module:enable --all \
    && php merge-default-scope-config.php \
    && rm merge-default-scope-config.php

RUN php bin/magento setup:di:compile \
    && php bin/magento setup:static-content:deploy -f -s compact --symlink-locale --jobs=$(nproc) \
    && rm -rf var/view_preprocessed/* var/cache/* var/page_cache/* var/generation/*

# Add our env.php
COPY env.php app/etc/env.php

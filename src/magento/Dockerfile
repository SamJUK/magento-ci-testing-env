ARG PHP_VERSION=8.3
FROM samjuk/magento-base-ci-testing-env:${PHP_VERSION}

ARG APP_DISTRO=magento
ARG APP_VERSION=2.4.8

ENV APP_VERSION=${APP_VERSION}
ENV MAGE_MODE=production

# Disable Insecure Package Audit
RUN composer config --global audit.block-insecure false || true

# Download Application
RUN --mount=type=cache,target=/root/.composer/cache \
    --mount=type=cache,target=/tmp/cache \
    set -e; \
    if [ "${APP_DISTRO}" != "magento" ] && [ "${APP_DISTRO}" != "mage-os" ]; then \
        echo "Error: APP_DISTRO must be either 'magento' or 'mage-os'. \"${APP_DISTRO}\" provided."; \
        exit 1; \
    fi; \
    [ "${APP_DISTRO}" = "magento" ] && REPO="https://mage-os.hypernode.com/mirror/" || REPO="https://repo.mage-os.org/"; \
    composer create-project --no-install --prefer-dist --repository-url=${REPO} ${APP_DISTRO}/project-community-edition:${APP_VERSION} . \
    # Setup Composer Plugins
    && composer config --no-plugins allow-plugins.phpstan/extension-installer true \
    && composer config --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true \
    && composer config --no-plugins allow-plugins.magento/* true \
    && composer config --no-plugins allow-plugins.vaimo/composer-patches true \
    && composer config --no-plugins allow-plugins.laminas/laminas-dependency-plugin true \
    # Install Extra Composer Tooling
    && composer require --no-update --dev \
        vaimo/composer-patches:* \
        phpstan/phpstan:* \
        bitexpert/phpstan-magento:* \
        phpstan/extension-installer:* \
    # Configure local Extensions directory
    && mkdir -p extensions \
    && composer config repositories.local path ./extensions/*

# Apply patches and final setup
COPY patches.json ./
COPY patches/ ./patches/
COPY ./scripts/ ./scripts/
RUN --mount=type=cache,target=/root/.composer/cache \
    set -e; \
    # Apply Patches
    jq '.extra.patches = ((.extra.patches // {}) * input)' composer.json patches.json > composer.tmp \
    && mv composer.tmp composer.json \
    # Fix broken composer constraints
    && sh  ./scripts/fix-invalid-package-versions.sh \
    # Final Installation
    && composer install \
    && composer clear-cache
    # Image size optimizations;
    # && find vendor/magento -type d \( -iname 'test' -o -iname 'tests' \) -exec rm -rf {} +
    # && rm -rf dev

# Build and generate Magento configs
RUN php bin/magento module:enable --all \
    && php ./scripts/merge-default-scope-config.php \
    && php bin/magento setup:di:compile \
    && php bin/magento setup:static-content:deploy -f -s compact --symlink-locale --jobs=$(nproc) \
    && rm -rf var/view_preprocessed/* var/cache/* var/page_cache/* var/generation/* \
    && rm -rf ./scripts/

# Add our env.php
COPY env.php app/etc/env.php

# Set Permissions
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} + \
    && find /var/www/html -type f -exec chmod 644 {} + \
    && chmod 755 /var/www/html/bin/magento \
    && chmod +x /var/www/html/vendor/bin/*
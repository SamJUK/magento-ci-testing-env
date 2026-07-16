ARG PHP_VERSION=8.3
FROM samjuk/magento-base-ci-testing-env:${PHP_VERSION}

ARG APP_DISTRO=magento
ARG APP_VERSION=2.4.8

ENV APP_VERSION=${APP_VERSION}
ENV MAGE_MODE=production

# Disable Insecure Package Audit
RUN composer config --global audit.block-insecure false || true

# Download Application and Setup
USER www-data
COPY --chown=www-data:www-data ./patches.json /tmp/
COPY --chown=www-data:www-data ./patches /tmp/patches
COPY --chown=www-data:www-data ./scripts /tmp/scripts
RUN --mount=type=cache,target=/root/.composer/cache \
    --mount=type=cache,target=/tmp/cache \
    set -e; \
    if [ "${APP_DISTRO}" != "magento" ] && [ "${APP_DISTRO}" != "mage-os" ]; then \
        echo "Error: APP_DISTRO must be either 'magento' or 'mage-os'. \"${APP_DISTRO}\" provided."; \
        exit 1; \
    fi; \
    [ "${APP_DISTRO}" = "magento" ] && REPO="https://mage-os.hypernode.com/mirror/" || REPO="https://repo.mage-os.org/"; \
    composer create-project --no-install --prefer-dist --repository-url=${REPO} ${APP_DISTRO}/project-community-edition:${APP_VERSION} . \
    # Move our assets in place
    && mv /tmp/patches ./patches \
    && mv /tmp/scripts ./scripts \
    && mv /tmp/patches.json ./patches.json \
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
    && composer config repositories.local path ./extensions/* \
    # Apply Patches
    && jq '.extra.patches = ((.extra.patches // {}) * input)' composer.json patches.json > composer.tmp \
    && mv composer.tmp composer.json \
    # Fix broken composer constraints
    && sh  ./scripts/fix-invalid-package-versions.sh \
    # Final Installation
    && composer install \
    && composer clear-cache \
    # Build and generate Magento configs
    && php bin/magento module:enable --all \
    && php ./scripts/merge-default-scope-config.php \
    && php bin/magento setup:di:compile \
    && php bin/magento setup:static-content:deploy -f -s compact --symlink-locale --jobs=$(nproc) \
    && rm -rf var/view_preprocessed/* var/cache/* var/page_cache/* var/generation/* \
    && rm -rf ./scripts/ \
    # Set Permissions
    && chmod +x /var/www/html/bin/magento \
    && chmod +x /var/www/html/vendor/bin/*

# Add our env.php
COPY --chown=www-data:www-data env.php app/etc/env.php
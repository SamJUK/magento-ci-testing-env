ARG PHP_VERSION=8.3
FROM php:${PHP_VERSION}-fpm-alpine

WORKDIR /var/www/html

# Install system dependencies and additional tools (rarely changes)
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache --update \
    freetype-dev \
	libjpeg-turbo-dev \
	icu-dev \
	libxslt-dev \
	libzip-dev \
    jq yq git patch

# Install PHP extensions (changes with PHP version)
ARG PHP_EXTENSIONS="bcmath gd intl opcache pcntl pdo_mysql soap sockets xsl zip ftp"
RUN --mount=type=cache,target=/var/cache/apk \
    PHP_VER="$(echo ${PHP_VERSION} | tr -d '.')" \
    && PHP_EXTS= && for ext in $PHP_EXTENSIONS; do \
        # OPCache is bundled and enabled by default as of PHP 8.5+
        [[ "$ext" == "opcache" && "$PHP_VER" -ge "850" ]] && continue; \
        PHP_EXTS="${PHP_EXTS} ${ext}"; \
    done \
    && apk add --no-cache --update --virtual build-deps \
        g++ \
        shadow \
        curl-dev \
        oniguruma-dev \
        libpng-dev \
        libxml2-dev \
        zlib-dev \
        autoconf \
        linux-headers \
    # Setup PHP Extensions
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) ${PHP_EXTS} \
    # Cleanup - Remove build dependencies and temp files
	&& docker-php-source delete \
    && apk del build-deps \
    && rm -rf /tmp/* /var/cache/apk/*

COPY custom.ini /usr/local/etc/php/conf.d/

#
# Helper Tools
#
RUN --mount=type=cache,target=/tmp/composer-download \
    if [[ "$PHP_VERSION" = 7.4* ]]; then \
        curl -sOL https://getcomposer.org/download/2.2.26/composer.phar; \
    else \
        curl -sOL https://getcomposer.org/download/2.9.5/composer.phar; \
    fi && \
    mv composer.phar /usr/local/bin/composer && \
    chmod 755 /usr/local/bin/composer && \
    composer --version

RUN set -e; \
    if [[ "$PHP_VERSION" = 7.4* ]]; then \
        url="https://files.magerun.net/n98-magerun2-7.5.0.phar"; \
    elif [[ "$PHP_VERSION" = 7.3* ]]; then \
        url="https://files.magerun.net/n98-magerun2-6.1.1.phar"; \
    elif [[ "$PHP_VERSION" = 7.2* ]]; then \
        url="https://files.magerun.net/n98-magerun2-4.7.0.phar"; \
    elif [[ "$PHP_VERSION" = 7.1* ]]; then \
        url="https://files.magerun.net/n98-magerun-1.103.2.phar"; \
    else \
        url="https://files.magerun.net/n98-magerun2-latest.phar"; \
    fi; \
    curl -o /usr/local/bin/n98-magerun2.phar "$url" && \
    chmod +x /usr/local/bin/n98-magerun2.phar && \
    ln -s /usr/local/bin/n98-magerun2.phar /usr/local/bin/n98-magerun2 && \
    ln -s /usr/local/bin/n98-magerun2.phar /usr/local/bin/magerun2 && \
    n98-magerun2 --version
#!/usr/bin/env sh
# This script handles pinning invalid package versions for various Magento installations

set -e 

if [ -z "$APP_VERSION" ]; then
  echo "APP_VERSION environment variable is not set. Exiting."
  exit 1
fi

if [ "$APP_VERSION" = "2.4.4" ]; then
    composer require "magento/security-package:1.1.3-p1 as 1.1.3" --no-update
    composer require "magento/inventory-metapackage:1.2.4-p1 as 1.2.4" --no-update
    composer update --no-security-blocking
fi

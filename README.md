# Docker Images for Magento Testing

A collection of docker images, aimed at facilitating Unit / Integration / E2E testing Magento modules & stores within CI Pipelines.

The main aim of these set of images, is to keep the Image size as small as possible. This allows for faster test executions, quicker builds and reduced pipelines costs. Especially important if your building and testing your modules across multiple Magento / PHP versions.


Image Name | Size (Compressed) | Link
--- | --- | ---
magento-base-ci-testing-env | 50 MB | https://hub.docker.com/repository/docker/samjuk/magento-base-ci-testing-env/general 
magento-ci-testing-env | 198 MB | https://hub.docker.com/repository/docker/samjuk/magento-ci-testing-env/general
mage-os-ci-testing-env | 190 MB | https://hub.docker.com/repository/docker/samjuk/mage-os-ci-testing-env


## Modules

For testing Magento modules, its recommended to use either the `magento-ci-testing-env` or `mage-os-ci-testing-env` images. 

Allowing you to save a substantial amount of wasted build time creating a Magento project against.

## Projects

For testing Magento projects, its recommended to use the `magento-base-ci-testing-env`. To keep the image small, as you do not need the preinstalled Magento application.
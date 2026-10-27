# syntax=docker/dockerfile:1
# OpenSearch with every bundled plugin removed. Magento's catalog search needs only core modules (analysis-common,
# lang-painless), and the plugins cost about 300 MiB of memory at idle. Ready for a read-only root filesystem with a
# tmpfs on /tmp. JVM options are left to OPENSEARCH_JAVA_OPTS, so each environment picks its own heap.
ARG BASE=mirror.gcr.io/opensearchproject/opensearch:3.9.0@sha256:adfa61f85025d06b4aeb562e7e74fde7e31c437039c93c3862c17e9acebd6c7c

FROM ${BASE} AS strip
# A plugin another one extends cannot go first, so repeat until none are left, and stop if a pass removes nothing.
RUN while left=$(bin/opensearch-plugin list) && [ -n "$left" ]; do \
        for p in $left; do bin/opensearch-plugin remove --purge --silent "$p" 2>/dev/null || true; done; \
        [ "$(bin/opensearch-plugin list)" != "$left" ] || { echo "stuck on: $left"; exit 1; }; \
    done
# For a read-only root: OpenSearch would create its keystore on first start, the JVM writes its GC log under logs/,
# and JNA and BouncyCastle FIPS (amd64 only) unpack native libraries into /tmp, which Docker and Swarm mount noexec.
# BouncyCastle falls back to pure Java, which only matters for TLS, and these stacks run none.
RUN bin/opensearch-keystore create \
    && sed -i '/-Xlog:gc\*/d' config/jvm.options \
    && arch=$(uname -m | tr _ -) \
    && mkdir lib/jna-native && cd lib/jna-native \
    && jar xf ../jna-*.jar "com/sun/jna/linux-$arch/libjnidispatch.so" \
    && mv "com/sun/jna/linux-$arch/libjnidispatch.so" . && rm -r com \
    && printf '%s\n' -Djna.boot.library.path=/usr/share/opensearch/lib/jna-native \
        -Dorg.bouncycastle.native.cpu_variant=java > ../../config/jvm.options.d/read-only.options

# One layer, so the removed plugins are not still shipped underneath.
FROM scratch
COPY --from=strip / /
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/opensearch/jdk/bin:/usr/share/opensearch/bin \
    JAVA_HOME=/usr/share/opensearch/jdk
LABEL org.opencontainers.image.source=https://github.com/SamJUK/magento-ci-testing-env \
      org.opencontainers.image.description="OpenSearch 3.9.0 without its bundled plugins, for Magento" \
      org.opencontainers.image.licenses=Apache-2.0 \
      org.opencontainers.image.version=3.9.0
USER 1000
WORKDIR /usr/share/opensearch
EXPOSE 9200 9300
ENTRYPOINT ["./opensearch-docker-entrypoint.sh"]
CMD ["opensearch"]

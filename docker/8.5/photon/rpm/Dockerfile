# PHP 8.5 on VMware Photon OS 5.x — built from RPMs produced by this repo's CI.
# Build context must contain ./repo with the binary RPMs for the target arch.
ARG PHOTON_VERSION=5.0
FROM photon:${PHOTON_VERSION}

LABEL org.opencontainers.image.title="PHP 8.5 (Photon OS)" \
      org.opencontainers.image.source="https://github.com/Lemric/photon-php" \
      org.opencontainers.image.description="PHP 8.5 CLI + FPM built as native Photon OS RPMs"

COPY repo /tmp/repo

RUN set -eux; \
    tdnf makecache -q; \
    tdnf install -y \
        /tmp/repo/libzip-[0-9]*.rpm \
        /tmp/repo/php85-common-*.rpm \
        /tmp/repo/php85-cli-*.rpm \
        /tmp/repo/php85-fpm-*.rpm \
        /tmp/repo/php85-opcache-*.rpm \
        /tmp/repo/php85-mbstring-*.rpm \
        /tmp/repo/php85-intl-*.rpm \
        /tmp/repo/php85-xml-*.rpm \
        /tmp/repo/php85-curl-*.rpm \
        /tmp/repo/php85-gd-*.rpm \
        /tmp/repo/php85-zip-*.rpm \
        /tmp/repo/php85-bcmath-*.rpm \
        /tmp/repo/php85-sockets-*.rpm \
        /tmp/repo/php85-mysqlnd-*.rpm \
        /tmp/repo/php85-pgsql-*.rpm \
        /tmp/repo/php85-8*.rpm; \
    if ls /tmp/repo/php85-pecl-igbinary-*.rpm >/dev/null 2>&1; then \
        tdnf install -y /tmp/repo/php85-pecl-igbinary-*.rpm /tmp/repo/php85-pecl-redis-*.rpm; \
    fi; \
    rm -rf /tmp/repo /var/cache/tdnf/*; \
    php -v

WORKDIR /var/www/html

EXPOSE 9000
CMD ["php-fpm", "-F"]

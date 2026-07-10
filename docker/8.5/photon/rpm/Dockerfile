# PHP 8.5 on VMware Photon OS 5.x — built from GPG-signed RPMs from CI.
# Build context: ./repo (RPMs) and ./RPM-GPG-KEY-photon-php (public key).
ARG PHOTON_VERSION=5.0
FROM photon:${PHOTON_VERSION}

LABEL org.opencontainers.image.title="PHP 8.5 (Photon OS)" \
      org.opencontainers.image.source="https://github.com/Lemric/photon-php" \
      org.opencontainers.image.description="PHP 8.5 CLI + FPM built as native Photon OS RPMs"

COPY RPM-GPG-KEY-photon-php /etc/pki/rpm-gpg/RPM-GPG-KEY-photon-php
COPY repo /tmp/repo

RUN set -eux; \
    tdnf makecache -q; \
    tdnf install -y rpm; \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-photon-php; \
    pick_latest() { ls -1 /tmp/repo/$1 2>/dev/null | sort -V | tail -1; }; \
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
        tdnf install -y \
            "$(pick_latest 'php85-pecl-igbinary-*.rpm')" \
            "$(pick_latest 'php85-pecl-redis-*.rpm')"; \
    fi; \
    rm -rf /tmp/repo /var/cache/tdnf/*; \
    php -v

WORKDIR /var/www/html

EXPOSE 9000
CMD ["php-fpm", "-F"]

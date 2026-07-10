# PHP 8.5 on VMware Photon OS 5.x — built from GPG-signed RPMs from CI.
# Build context: ./repo (RPMs), ./RPM-GPG-KEY-photon-php, install-php-rpms.sh
#
# Targets:
#   base — shared PHP modules (no SAPI)
#   cli  — PHP CLI
#   fpm  — PHP-FPM (production)
#
# Examples:
#   docker build --target cli -t php:8.5.8-cli-photon .
#   docker build --target fpm -t php:8.5.8-fpm-photon .
ARG PHOTON_VERSION=5.0

FROM photon:${PHOTON_VERSION} AS photon-base

LABEL org.opencontainers.image.source="https://github.com/Lemric/photon-php"

COPY RPM-GPG-KEY-photon-php /etc/pki/rpm-gpg/RPM-GPG-KEY-photon-php
COPY repo /tmp/repo
COPY install-php-rpms.sh /usr/local/bin/install-php-rpms.sh
RUN chmod +x /usr/local/bin/install-php-rpms.sh \
    && install-php-rpms.sh common

FROM photon-base AS base

LABEL org.opencontainers.image.title="PHP 8.5 base (Photon OS)" \
      org.opencontainers.image.description="PHP 8.5 core modules with CLI (RPM deps); add FPM target for php-fpm"

WORKDIR /var/www/html

FROM photon-base AS cli

LABEL org.opencontainers.image.title="PHP 8.5 CLI (Photon OS)" \
      org.opencontainers.image.description="PHP 8.5 command-line interface built from native Photon OS RPMs"

RUN install-php-rpms.sh cli

WORKDIR /var/www/html
CMD ["php"]

FROM photon-base AS fpm

LABEL org.opencontainers.image.title="PHP 8.5 FPM (Photon OS)" \
      org.opencontainers.image.description="PHP 8.5 FastCGI Process Manager built from native Photon OS RPMs"

RUN install-php-rpms.sh fpm

COPY php-fpm-docker.conf /etc/php85/php-fpm.d/zz-docker.conf
RUN sed -i '/^listen\.allowed_clients/d' /etc/php85/php-fpm.d/www.conf

WORKDIR /var/www/html
EXPOSE 9000
STOPSIGNAL SIGQUIT
CMD ["php-fpm", "-F"]

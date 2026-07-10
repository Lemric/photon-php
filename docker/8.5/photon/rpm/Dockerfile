# syntax=docker/dockerfile:1.7
# PHP 8.5 on VMware Photon OS 5.x — production images from GPG-signed RPMs.
# Build context: docker/8.5/photon (repo/, RPM-GPG-KEY, scripts under rpm/)
#
# Targets: base | cli | fpm
ARG PHOTON_VERSION=5.0

FROM photon:${PHOTON_VERSION} AS installer

LABEL org.opencontainers.image.source="https://github.com/Lemric/photon-php"

COPY rpm/RPM-GPG-KEY-photon-php /etc/pki/rpm-gpg/RPM-GPG-KEY-photon-php
COPY rpm/repo /tmp/repo
COPY rpm/install-php-rpms.sh /usr/local/bin/install-php-rpms.sh
COPY common/photon-runtime-cleanup.sh /usr/local/bin/photon-runtime-cleanup.sh
COPY rpm/php-fpm-docker.conf /tmp/php-fpm-docker.conf

RUN chmod +x /usr/local/bin/install-php-rpms.sh /usr/local/bin/photon-runtime-cleanup.sh \
    && install-php-rpms.sh all \
    && photon-runtime-cleanup.sh

FROM scratch AS runtime

COPY --from=installer / /

ENV PHP_FPM_UID=999 \
    PHP_FPM_GID=999

WORKDIR /var/www/html

FROM runtime AS base

LABEL org.opencontainers.image.title="PHP 8.5 base (Photon OS)" \
      org.opencontainers.image.description="PHP 8.5 core modules with CLI (RPM deps)"

CMD ["php"]

FROM runtime AS cli

LABEL org.opencontainers.image.title="PHP 8.5 CLI (Photon OS)" \
      org.opencontainers.image.description="PHP 8.5 command-line interface built from native Photon OS RPMs"

USER ${PHP_FPM_UID}:${PHP_FPM_GID}
CMD ["php"]

FROM runtime AS fpm

LABEL org.opencontainers.image.title="PHP 8.5 FPM (Photon OS)" \
      org.opencontainers.image.description="PHP 8.5 FastCGI Process Manager built from native Photon OS RPMs"

USER ${PHP_FPM_UID}:${PHP_FPM_GID}

EXPOSE 9000
STOPSIGNAL SIGQUIT

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["/usr/sbin/php-fpm", "-t"]

CMD ["/usr/sbin/php-fpm", "-F"]

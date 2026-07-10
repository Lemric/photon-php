#!/bin/bash
# Install PHP 8.5 RPMs from /tmp/repo into a Photon OS container (BUILD stage only).
# Usage: install-php-rpms.sh <common|cli|fpm|all>
set -euo pipefail

VARIANT="${1:?variant required: common|cli|fpm|all}"
REPO="${REPO_DIR:-/tmp/repo}"

pick_latest() {
    local -a matches=( "${REPO}"/$1 )
    if ((${#matches[@]} == 0)) || [[ ! -e "${matches[0]}" ]]; then
        return 1
    fi
    printf '%s\n' "${matches[@]}" | sort -V | tail -1
}

install_gpg() {
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-photon-php
}

collect_existing_rpms() {
    local pattern rpm
    for pattern in "$@"; do
        for rpm in ${pattern}; do
            [ -f "${rpm}" ] || continue
            printf '%s\n' "${rpm}"
        done
    done
}

install_local_rpms() {
    local -a rpms=()
    mapfile -t rpms < <(collect_existing_rpms "$@")

    if [ "${#rpms[@]}" -eq 0 ]; then
        echo "ERROR: no RPM files to install" >&2
        return 1
    fi

    tdnf install -y "${rpms[@]}"
}

install_pecl_redis_stack() {
    local igbinary redis
    local -a pecl_rpms=()

    igbinary="$(pick_latest 'php85-pecl-igbinary-*.rpm' || true)"
    redis="$(pick_latest 'php85-pecl-redis-*.rpm' || true)"

    [ -n "${igbinary}" ] && [ -f "${igbinary}" ] && pecl_rpms+=("${igbinary}")
    [ -n "${redis}" ] && [ -f "${redis}" ] && pecl_rpms+=("${redis}")

    if [ "${#pecl_rpms[@]}" -eq 0 ]; then
        echo "No PECL redis/igbinary RPMs in ${REPO} — skipping"
        return 0
    fi

    tdnf install -y "${pecl_rpms[@]}"
}

common_rpms() {
    install_local_rpms \
        "${REPO}"/libzip-[0-9]*.rpm \
        "${REPO}"/php85-common-*.rpm \
        "${REPO}"/php85-cli-*.rpm \
        "${REPO}"/php85-8*.rpm \
        "${REPO}"/php85-opcache-*.rpm \
        "${REPO}"/php85-mbstring-*.rpm \
        "${REPO}"/php85-intl-*.rpm \
        "${REPO}"/php85-xml-*.rpm \
        "${REPO}"/php85-curl-*.rpm \
        "${REPO}"/php85-gd-*.rpm \
        "${REPO}"/php85-zip-*.rpm \
        "${REPO}"/php85-bcmath-*.rpm \
        "${REPO}"/php85-sockets-*.rpm \
        "${REPO}"/php85-mysqlnd-*.rpm \
        "${REPO}"/php85-pgsql-*.rpm
    install_pecl_redis_stack
}

configure_fpm_for_containers() {
  if [ ! -f /etc/php85/php-fpm.d/www.conf ]; then
    return 0
  fi

  sed -i '/^listen\.allowed_clients/d' /etc/php85/php-fpm.d/www.conf
  sed -i '/^slowlog[[:space:]]*=/d' /etc/php85/php-fpm.d/www.conf
  sed -i '/^request_slowlog_timeout[[:space:]]*=/d' /etc/php85/php-fpm.d/www.conf

  install -d -m 0755 -o php-fpm -g php-fpm /var/log/php85-fpm /var/lib/php85-fpm /tmp/php-fpm
  chmod 1777 /tmp

  if [ -f /tmp/php-fpm-docker.conf ]; then
    install -m 0644 /tmp/php-fpm-docker.conf /etc/php85/php-fpm.d/zz-docker.conf
  fi
}

fpm_rpms() {
    install_local_rpms "${REPO}"/php85-fpm-*.rpm
    configure_fpm_for_containers
    php-fpm -t
}

tdnf makecache -q
tdnf install -y rpm
# Align base glibc with current Photon repos before local PHP RPM transaction.
tdnf update -y glibc glibc-libs
install_gpg

case "${VARIANT}" in
    common)
        common_rpms
        ;;
    cli)
        php -v
        ;;
    fpm)
        install_local_rpms "${REPO}"/php85-fpm-*.rpm
        configure_fpm_for_containers
        php-fpm -t
        ;;
    all)
        common_rpms
        fpm_rpms
        php -v
        ;;
    *)
        echo "Unknown variant: ${VARIANT}" >&2
        exit 1
        ;;
esac

tdnf clean all
rm -rf /var/cache/tdnf/* /tmp/repo /tmp/php-fpm-docker.conf 2>/dev/null || true

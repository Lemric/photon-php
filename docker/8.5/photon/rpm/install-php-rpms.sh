#!/bin/bash
# Install PHP 8.5 RPMs from /tmp/repo into a Photon OS container.
# Usage: install-php-rpms.sh <common|cli|fpm|all>
#
# Uses rpm -Uvh (not tdnf) so circular Requires between php85, php85-common
# and php85-cli resolve in a single transaction — same approach as build-rpm.sh.
set -euo pipefail

VARIANT="${1:?variant required: common|cli|fpm|all}"
REPO="${REPO_DIR:-/tmp/repo}"

pick_latest() {
    ls -1 "${REPO}/$1" 2>/dev/null | sort -V | tail -1
}

install_gpg() {
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-photon-php
}

install_rpm_files() {
    local -a rpms=()
    local rpm

    for rpm in "$@"; do
        [ -f "${rpm}" ] || continue
        rpms+=("${rpm}")
    done

    if [ "${#rpms[@]}" -eq 0 ]; then
        echo "ERROR: no RPM files to install" >&2
        return 1
    fi

    # shellcheck disable=SC2068
    rpm -Uvh --replacepkgs ${rpms[@]}
}

libzip_rpms() {
    printf '%s\n' "${REPO}"/libzip-[0-9]*.rpm
}

module_rpms() {
    printf '%s\n' \
        "${REPO}"/php85-common-*.rpm \
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
}

meta_rpms() {
    printf '%s\n' "${REPO}"/php85-8*.rpm
}

sapi_cli_rpms() {
    printf '%s\n' "${REPO}"/php85-cli-*.rpm
}

sapi_fpm_rpms() {
    printf '%s\n' "${REPO}"/php85-fpm-*.rpm
}

stack_without_fpm() {
    libzip_rpms
    module_rpms
    sapi_cli_rpms
    meta_rpms
}

stack_all() {
    stack_without_fpm
    sapi_fpm_rpms
}

install_pecl_redis_stack() {
    if ls "${REPO}"/php85-pecl-igbinary-*.rpm >/dev/null 2>&1; then
        install_rpm_files \
            "$(pick_latest 'php85-pecl-igbinary-*.rpm')" \
            "$(pick_latest 'php85-pecl-redis-*.rpm')"
    fi
}

cleanup_repo() {
    rm -rf "${REPO}" /var/cache/tdnf/*
}

tdnf makecache -q
tdnf install -y rpm
install_gpg

case "${VARIANT}" in
    common)
        # shellcheck disable=SC2046
        install_rpm_files $(stack_without_fpm)
        install_pecl_redis_stack
        ;;
    cli)
        cleanup_repo
        php -v
        ;;
    fpm)
        # shellcheck disable=SC2046
        install_rpm_files $(sapi_fpm_rpms)
        cleanup_repo
        php-fpm -t
        ;;
    all)
        # shellcheck disable=SC2046
        install_rpm_files $(stack_all)
        install_pecl_redis_stack
        cleanup_repo
        php -v
        ;;
    *)
        echo "Unknown variant: ${VARIANT}" >&2
        exit 1
        ;;
esac

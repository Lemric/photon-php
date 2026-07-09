#!/bin/bash
# build-rpm.sh — Build PHP 8.5 and PECL extension RPMs for Photon OS
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PHP_VERSION="${PHP_VERSION:-8.5.8}"
ARCH="${ARCH:-$(uname -m)}"
DIST="${DIST:-photon5}"
RELEASE="${RELEASE:-1}"
TARGET="${1:-all}"

RPMBUILD_DIR="${RPMBUILD_DIR:-${PROJECT_ROOT}/.rpmbuild}"
OUTPUT_DIR="${OUTPUT_DIR:-${PROJECT_ROOT}/repo/${ARCH}}"

MACROS_FILE="${PROJECT_ROOT}/packaging/macros.php85"
RPM_MACROS=(--macros="${MACROS_FILE}")

log() { echo "[build-rpm] $*"; }

setup_rpmbuild() {
    log "Setting up rpmbuild tree at ${RPMBUILD_DIR}"
    mkdir -p "${RPMBUILD_DIR}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    mkdir -p "${OUTPUT_DIR}"

    if [ -f /etc/rpm/macros.php85 ]; then
        :
    elif [ "$(id -u)" -eq 0 ]; then
        install -m 0644 "${MACROS_FILE}" /etc/rpm/macros.php85
    else
        log "Installing macros via --macros flag (not root)"
    fi
}

build_spec() {
    local spec_file="$1"
    local spec_name
    spec_name="$(basename "${spec_file}")"

    log "Building ${spec_name} for ${ARCH}"

    cp -f "${spec_file}" "${RPMBUILD_DIR}/SPECS/${spec_name}"

    # Copy include fragments for php85.spec
    if [[ "${spec_name}" == "php85.spec" ]]; then
        cp -f "${PROJECT_ROOT}/packaging/php85-"*.spec "${RPMBUILD_DIR}/SPECS/"
        cp -f "${PROJECT_ROOT}/packaging/configs/"* "${RPMBUILD_DIR}/SOURCES/"
    fi

    # Copy extension macro includes
    if [[ "${spec_file}" == */extensions/* ]]; then
        cp -f "${PROJECT_ROOT}/extensions/macros.inc" "${RPMBUILD_DIR}/SPECS/"
    fi

    rpmbuild -ba \
        "${RPM_MACROS[@]}" \
        --define "_topdir ${RPMBUILD_DIR}" \
        --define "_sourcedir ${RPMBUILD_DIR}/SOURCES" \
        --define "dist .${DIST}" \
        --target "${ARCH}" \
        "${RPMBUILD_DIR}/SPECS/${spec_name}"

    find "${RPMBUILD_DIR}/RPMS/${ARCH}" -name '*.rpm' -exec cp -f {} "${OUTPUT_DIR}/" \;
    find "${RPMBUILD_DIR}/SRPMS" -name '*.src.rpm' -exec cp -f {} "${OUTPUT_DIR}/" \; 2>/dev/null || true
}

detect_php_api() {
  if command -v php-config >/dev/null 2>&1; then
    local api
    api="$(php-config --phpapi 2>/dev/null || true)"
    if [ -n "${api}" ]; then
      log "Detected PHP API version: ${api}"
      sed -i "s/%global php85_api.*/%global php85_api          ${api}/" "${MACROS_FILE}" 2>/dev/null || \
        sed -i '' "s/%global php85_api.*/%global php85_api          ${api}/" "${MACROS_FILE}" 2>/dev/null || true
    fi
  fi
}

build_re2c() {
    log "Building re2c >= 3.x (required by PHP 8.5)"
    if command -v re2c >/dev/null 2>&1; then
        local ver
        ver="$(re2c --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
        if awk "BEGIN {exit !(${ver:-0} >= 3.0)}"; then
            log "System re2c ${ver} is sufficient, skipping RPM build"
            return 0
        fi
    fi
    build_spec "${PROJECT_ROOT}/packaging/re2c.spec"
    tdnf install -y "${OUTPUT_DIR}"/re2c-*.rpm 2>/dev/null || \
        rpm -Uvh --nodeps "${OUTPUT_DIR}"/re2c-*.rpm 2>/dev/null || true
}

build_rabbitmq_c() {
    if rpm -q rabbitmq-c-devel >/dev/null 2>&1; then
        log "rabbitmq-c-devel already installed"
        return 0
    fi
    if tdnf info rabbitmq-c-devel >/dev/null 2>&1; then
        tdnf install -y rabbitmq-c-devel && return 0
    fi
    log "Building rabbitmq-c from source (not in Photon repos)"
    build_spec "${PROJECT_ROOT}/packaging/rabbitmq-c.spec"
    tdnf install -y "${OUTPUT_DIR}"/rabbitmq-c-*.rpm 2>/dev/null || \
        rpm -Uvh --nodeps "${OUTPUT_DIR}"/rabbitmq-c-*.rpm 2>/dev/null || true
}

build_libzip() {
    if pkg-config --exists libzip 2>/dev/null || rpm -q libzip-devel >/dev/null 2>&1; then
        log "libzip already installed"
        return 0
    fi
    log "Building libzip (not in Photon OS repos)"
    build_spec "${PROJECT_ROOT}/packaging/libzip.spec"
    tdnf install -y "${OUTPUT_DIR}"/libzip-*.rpm 2>/dev/null || \
        rpm -Uvh --nodeps "${OUTPUT_DIR}"/libzip-*.rpm 2>/dev/null || true
}

build_php() {
    log "Building PHP ${PHP_VERSION}"
    build_spec "${PROJECT_ROOT}/packaging/php85.spec"

    log "Installing PHP RPMs for extension builds"
    for pkg in common cli devel fpm opcache mbstring intl xml curl gd zip bcmath \
               soap sockets pcntl mysqlnd pgsql process; do
        tdnf install -y "${OUTPUT_DIR}/php85-${pkg}-"*.rpm 2>/dev/null || \
            rpm -Uvh --nodeps "${OUTPUT_DIR}/php85-${pkg}-"*.rpm 2>/dev/null || true
    done
    tdnf install -y "${OUTPUT_DIR}/php85-"[0-9]*.rpm 2>/dev/null || \
        rpm -Uvh --nodeps "${OUTPUT_DIR}/php85-"[0-9]*.rpm 2>/dev/null || true

    detect_php_api
}

build_extensions() {
    log "Building PECL extensions"
    build_rabbitmq_c
    local ext_specs=(
        igbinary
        redis
        apcu
        amqp
        imagick
        xdebug
    )

    export PHP_CONFIG=/usr/bin/php-config
    export PHP_PREFIX=/usr

    for ext in "${ext_specs[@]}"; do
        log "Building extension: ${ext}"
        build_spec "${PROJECT_ROOT}/extensions/${ext}.spec"
    done
}

main() {
    setup_rpmbuild

    case "${TARGET}" in
        re2c)
            build_re2c
            ;;
        libzip)
            build_libzip
            ;;
        php)
            build_re2c
            build_libzip
            build_php
            ;;
        extensions)
            build_extensions
            ;;
        all)
            build_re2c
            build_libzip
            build_php
            build_extensions
            ;;
        *)
            echo "Usage: $0 [re2c|libzip|php|extensions|all]" >&2
            exit 1
            ;;
    esac

    log "RPMs written to ${OUTPUT_DIR}"
    ls -la "${OUTPUT_DIR}"/*.rpm 2>/dev/null || true
}

main "$@"

#!/bin/bash
# Build one PHP stage (php or extension:NAME) using bootstrap RPMs from /published.
set -euo pipefail

export LC_ALL=C
export LANG=C

STAGE="${1:?stage required: php|extension:NAME}"

ARCH="${ARCH:?ARCH is required}"
OUTPUT_DIR="${OUTPUT_DIR:-/build/repo/${ARCH}}"
RPMBUILD_DIR="${RPMBUILD_DIR:-/build/.rpmbuild-${ARCH}}"
REPO_BASEURL="${REPO_BASEURL:-https://pkgs.photon.lemric.com}"
PUBLISHED_DIR="${PUBLISHED_DIR:-/published}"

log() { echo "[ci-php] $*"; }

export ARCH OUTPUT_DIR RPMBUILD_DIR REPO_BASEURL PUBLISHED_DIR

seed_output_from_published() {
    mkdir -p "${OUTPUT_DIR}"
    if [ ! -d "${PUBLISHED_DIR}" ] || ! ls "${PUBLISHED_DIR}"/*.rpm >/dev/null 2>&1; then
        return 0
    fi
    log "Seeding ${OUTPUT_DIR} from published RPMs"
    cp -f "${PUBLISHED_DIR}"/*.rpm "${OUTPUT_DIR}/"
}

install_bootstrap_from_published() {
    if [ ! -d "${PUBLISHED_DIR}" ] || ! ls "${PUBLISHED_DIR}"/*.rpm >/dev/null 2>&1; then
        log "ERROR: bootstrap RPMs not found in ${PUBLISHED_DIR}" >&2
        log "Publish bootstrap packages first (Build Photon Bootstrap workflow)" >&2
        exit 1
    fi

    log "Installing bootstrap RPMs from ${PUBLISHED_DIR}"
    local rpm
    for rpm in \
        "${PUBLISHED_DIR}"/re2c-*.rpm \
        "${PUBLISHED_DIR}"/libzip-*.rpm \
        "${PUBLISHED_DIR}"/libzip-devel-*.rpm \
        "${PUBLISHED_DIR}"/rabbitmq-c-*.rpm \
        "${PUBLISHED_DIR}"/rabbitmq-c-devel-*.rpm; do
        [ -f "${rpm}" ] || continue
        rpm -Uvh --replacepkgs "${rpm}"
    done
}

if [ "${CI_SKIP_ENV_SETUP:-0}" = "1" ]; then
    log "=== Using pre-built RPM environment (CI_SKIP_ENV_SETUP) ==="
else
    log "=== Installing build dependencies ==="
    scripts/install-build-deps.sh
fi

install_bootstrap_from_published

seed_output_from_published

# shellcheck source=rpm-gpg-common.sh
source scripts/rpm-gpg-common.sh
rpm_gpg_require_ci
rpm_gpg_setup

case "${STAGE}" in
    php)
        log "=== Building PHP ${PHP_VERSION:-8.5.8} ==="
        scripts/build-rpm.sh php
        ;;
    extension:*)
        log "=== Building PECL extension: ${STAGE#extension:} ==="
        scripts/build-rpm.sh "${STAGE}"
        ;;
    *)
        log "ERROR: unknown PHP stage '${STAGE}'" >&2
        exit 1
        ;;
esac

log "=== PHP stage ${STAGE} complete for ${ARCH} ==="
ls -la "${OUTPUT_DIR}"/*.rpm 2>/dev/null || true

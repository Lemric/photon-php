#!/bin/bash
# Build one bootstrap RPM stage (re2c, libzip, or rabbitmq-c).
set -euo pipefail

export LC_ALL=C
export LANG=C

STAGE="${1:?stage required: re2c|libzip|rabbitmq-c}"

ARCH="${ARCH:?ARCH is required}"
OUTPUT_DIR="${OUTPUT_DIR:-/build/repo/${ARCH}}"
RPMBUILD_DIR="${RPMBUILD_DIR:-/build/.rpmbuild-${ARCH}}"
REPO_BASEURL="${REPO_BASEURL:-https://pkgs.photon.lemric.com}"

log() { echo "[ci-bootstrap] $*"; }

export ARCH OUTPUT_DIR RPMBUILD_DIR REPO_BASEURL

case "${STAGE}" in
    re2c|libzip|rabbitmq-c) ;;
    *)
        log "ERROR: unknown bootstrap stage '${STAGE}'" >&2
        exit 1
        ;;
esac

if [ "${CI_SKIP_ENV_SETUP:-0}" = "1" ]; then
    log "=== Using pre-built RPM environment (CI_SKIP_ENV_SETUP) ==="
else
    log "=== Installing build dependencies ==="
    scripts/install-build-deps.sh
fi

log "=== Building stage: ${STAGE} ==="
scripts/build-rpm.sh "${STAGE}"

log "=== Bootstrap stage ${STAGE} complete for ${ARCH} ==="
ls -la "${OUTPUT_DIR}"/*.rpm 2>/dev/null || true

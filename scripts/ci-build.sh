#!/bin/bash
# CI build entrypoint — runs the full RPM chain in one container session.
set -euo pipefail

ARCH="${ARCH:?ARCH is required}"
OUTPUT_DIR="${OUTPUT_DIR:-/build/repo/${ARCH}}"
RPMBUILD_DIR="${RPMBUILD_DIR:-/build/.rpmbuild-${ARCH}}"
REPO_BASEURL="${REPO_BASEURL:-https://pkgs.photon.lemric.com}"

log() { echo "[ci-build] $*"; }

export ARCH OUTPUT_DIR RPMBUILD_DIR REPO_BASEURL

log "=== Stage 0: install build dependencies ==="
scripts/install-build-deps.sh

for stage in re2c libzip rabbitmq-c php extensions; do
    log "=== Stage: ${stage} ==="
    scripts/build-rpm.sh "${stage}"
done

log "=== Stage: repository metadata ==="
tdnf install -y createrepo_c
scripts/build-repo.sh

log "=== Build complete for ${ARCH} ==="
ls -la "${OUTPUT_DIR}"/*.rpm 2>/dev/null | wc -l | xargs -I{} log "Binary RPMs: {}"

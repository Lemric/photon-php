#!/bin/bash
# Run a single RPM package build inside the pre-built Photon builder image.
set -euo pipefail

GROUP="${1:?group required: bootstrap|php}"
ARCH="${2:?arch required}"
STAGE="${3:?stage required}"
PLATFORM="${4:?platform required}"
BUILDER_IMAGE="${5:?builder image required}"

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_SCRIPT="ci-build-${GROUP}.sh"

log() { echo "[ci-run-build] $*"; }

if [ ! -f "${WORKSPACE}/scripts/${BUILD_SCRIPT}" ]; then
    log "ERROR: missing ${BUILD_SCRIPT}" >&2
    exit 1
fi

mkdir -p "${WORKSPACE}/repo/${ARCH}"

docker_args=(
    run --privileged --rm
    --platform "${PLATFORM}"
    -v "${WORKSPACE}:/build"
    -w /build
    -e "ARCH=${ARCH}"
    -e "CI_SKIP_ENV_SETUP=1"
    -e "OUTPUT_DIR=/build/repo/${ARCH}"
    -e "RPMBUILD_DIR=/build/.rpmbuild-${ARCH}"
    -e "REPO_BASEURL=${REPO_BASEURL:-https://pkgs.photon.lemric.com}"
    -e "PHP_VERSION=${PHP_VERSION:-8.5.8}"
)

if [ "${GROUP}" = "php" ]; then
    if [ ! -d "${WORKSPACE}/published/${ARCH}" ]; then
        log "ERROR: published/${ARCH} not found — checkout gh-pages before PHP builds" >&2
        exit 1
    fi
    docker_args+=(-v "${WORKSPACE}/published/${ARCH}:/published:ro")
fi

log "Building ${GROUP}/${STAGE} for ${ARCH} using ${BUILDER_IMAGE}"
# shellcheck disable=SC2068
docker "${docker_args[@]}" "${BUILDER_IMAGE}" \
    bash -c "scripts/${BUILD_SCRIPT} ${STAGE}"

if ! ls "${WORKSPACE}/repo/${ARCH}"/*.rpm >/dev/null 2>&1; then
    log "ERROR: no RPMs produced for ${GROUP}/${STAGE} on ${ARCH}" >&2
    exit 1
fi

log "Built $(find "${WORKSPACE}/repo/${ARCH}" -maxdepth 1 -name '*.rpm' | wc -l | tr -d ' ') RPM(s) for ${STAGE}"

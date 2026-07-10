#!/bin/bash
# Build or reuse the privileged Photon RPM builder image on GHCR.
set -euo pipefail

ARCH="${1:?arch required (x86_64 or aarch64)}"
PLATFORM="${2:?platform required (linux/amd64 or linux/arm64)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PHOTON_VERSION="${PHOTON_VERSION:-5.0}"
FORCE_REBUILD="${CI_FORCE_BUILDER_REBUILD:-0}"
WORKSPACE="${GITHUB_WORKSPACE:-${PROJECT_ROOT}}"
RUN_ID="${GITHUB_RUN_ID:-local}"

log() { echo "[ci-builder] $*"; }

deps_hash() {
    local photon_ver="$1"
    local deps_file="$2"
    printf '%s-%s' "${photon_ver}" "$(sha256sum "${deps_file}" | awk '{print $1}')"
}

image_ref() {
    "${SCRIPT_DIR}/ci-builder-image-ref.sh" "${ARCH}"
}

latest_tag_for_arch() {
    case "${ARCH}" in
        x86_64) echo "latest" ;;
        aarch64) echo "latest-aarch64" ;;
        *)
            log "ERROR: unsupported arch '${ARCH}'" >&2
            exit 1
            ;;
    esac
}

existing_hash() {
    local image="$1"
    docker image inspect -f '{{index .Config.Labels "photon-php.builder-deps-hash"}}' "${image}" 2>/dev/null || true
}

if [ "${FORCE_REBUILD}" = "1" ] || [ "${FORCE_REBUILD}" = "true" ]; then
    log "CI_FORCE_BUILDER_REBUILD set — rebuilding builder image"
else
    if docker pull --platform "${PLATFORM}" "$(image_ref)" >/dev/null 2>&1; then
        wanted_hash="$(deps_hash "${PHOTON_VERSION}" "${WORKSPACE}/scripts/install-build-deps.sh")"
        current_hash="$(existing_hash "$(image_ref)")"
        if [ -n "${current_hash}" ] && [ "${current_hash}" = "${wanted_hash}" ]; then
            log "Reusing existing builder image $(image_ref) (deps hash ${wanted_hash:0:12}…)"
            exit 0
        fi
        log "Builder image present but deps hash changed (${current_hash:-none} -> ${wanted_hash:0:12}…)"
    else
        log "No builder image in GHCR yet — building $(image_ref)"
    fi
fi

chmod +x "${WORKSPACE}/scripts/install-build-deps.sh"

IMAGE="$(image_ref)"
LATEST_TAG="$(latest_tag_for_arch)"
IMAGE_BASE="${IMAGE%:*}"
CONTAINER="photon-builder-${ARCH}-${RUN_ID}"
WANTED_HASH="$(deps_hash "${PHOTON_VERSION}" "${WORKSPACE}/scripts/install-build-deps.sh")"

cleanup() {
    docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker pull --platform "${PLATFORM}" "photon:${PHOTON_VERSION}"

log "Installing RPM build dependencies in privileged container"
docker run --privileged \
    --platform "${PLATFORM}" \
    -v "${WORKSPACE}/scripts/install-build-deps.sh:/tmp/install-build-deps.sh:ro" \
    --name "${CONTAINER}" \
    "photon:${PHOTON_VERSION}" \
    bash /tmp/install-build-deps.sh

docker commit \
    --change "LABEL photon-php.builder-deps-hash=${WANTED_HASH}" \
    --change "LABEL org.opencontainers.image.source=${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-Lemric/photon-php}" \
    "${CONTAINER}" "${IMAGE}"

docker tag "${IMAGE}" "${IMAGE_BASE}:${LATEST_TAG}"

cleanup
trap - EXIT

log "Pushing ${IMAGE_BASE}:{${ARCH},${LATEST_TAG}}"
docker push "${IMAGE}"
docker push "${IMAGE_BASE}:${LATEST_TAG}"

log "Builder image ready: ${IMAGE} (+ ${LATEST_TAG})"

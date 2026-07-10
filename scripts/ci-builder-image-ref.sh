#!/bin/bash
# Print GHCR image reference for the Photon RPM builder (per architecture).
set -euo pipefail

ARCH="${1:?arch required (x86_64 or aarch64)}"
REPOSITORY="${GITHUB_REPOSITORY:-Lemric/photon-php}"

echo "ghcr.io/$(echo "${REPOSITORY}" | tr '[:upper:]' '[:lower:]')/photon-builder:${ARCH}"

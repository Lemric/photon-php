#!/bin/bash
# Merge RPM artifacts from a CI wave and publish to gh-pages (--rpms-only).
set -euo pipefail

ARCH="${1:?architecture required}"
WAVE_LABEL="${2:?wave label required}"
ARTIFACTS_ROOT="${3:-artifacts}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEST_DIR="${PROJECT_ROOT}/repo/${ARCH}"

log() { echo "[ci-publish-artifacts] $*"; }

mkdir -p "${DEST_DIR}"
shopt -s nullglob

copied=0
while IFS= read -r -d '' rpm; do
    cp -f "${rpm}" "${DEST_DIR}/"
    copied=$((copied + 1))
done < <(find "${ARTIFACTS_ROOT}" -type f -name "*.${ARCH}.rpm" -print0 2>/dev/null)

if [ "${copied}" -eq 0 ]; then
    log "No RPM artifacts to publish for ${ARCH}/${WAVE_LABEL}"
    exit 0
fi

log "Publishing ${copied} RPM(s) from ${WAVE_LABEL} for ${ARCH}"
"${SCRIPT_DIR}/ci-publish-rpms.sh" "${ARCH}" "${DEST_DIR}" --rpms-only "${WAVE_LABEL}"

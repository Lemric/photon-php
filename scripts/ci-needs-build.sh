#!/bin/bash
# Exit 0 when a package stage should be rebuilt (version not yet published).
set -euo pipefail

STAGE="${1:?stage required}"
ARCH="${2:?arch required}"
PUBLISHED_DIR="${3:-published}"
FORCE="${CI_FORCE_BUILD:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${FORCE}" = "1" ] || [ "${FORCE}" = "true" ]; then
    exit 0
fi

if [ ! -d "${PUBLISHED_DIR}/${ARCH}" ]; then
    exit 0
fi

mapfile -t patterns < <("${SCRIPT_DIR}/ci-package-version.py" "${STAGE}" "${ARCH}")

for pattern in "${patterns[@]}"; do
    if ! compgen -G "${PUBLISHED_DIR}/${ARCH}/${pattern}" >/dev/null; then
        exit 0
    fi
done

exit 1

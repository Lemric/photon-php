#!/bin/bash
# Register OUTPUT_DIR as a local tdnf repo for chained RPM builds.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=rpm-gpg-common.sh
source "${SCRIPT_DIR}/rpm-gpg-common.sh"

OUTPUT_DIR="${OUTPUT_DIR:-/build/repo/$(uname -m)}"
REPO_ID="${REPO_ID:-photon-php-build}"

OUTPUT_DIR="$(cd "${OUTPUT_DIR}" && pwd)"

if [ ! -d "${OUTPUT_DIR}" ]; then
    echo "[setup-local-repo] ERROR: ${OUTPUT_DIR} does not exist" >&2
    exit 1
fi

mkdir -p "${OUTPUT_DIR}/srpms"
find "${OUTPUT_DIR}" -maxdepth 1 -name '*.src.rpm' -exec mv -f {} "${OUTPUT_DIR}/srpms/" \; 2>/dev/null || true

if ! ls "${OUTPUT_DIR}"/*.rpm >/dev/null 2>&1; then
    echo "[setup-local-repo] WARNING: no binary RPMs in ${OUTPUT_DIR} yet"
fi

if ! command -v createrepo_c >/dev/null 2>&1; then
    tdnf install -y createrepo_c
fi

# Default gzip metadata — Photon tdnf/libsolv cannot read xz repodata (Solv I/O error).
run_createrepo --update "${OUTPUT_DIR}" 2>/dev/null \
    || run_createrepo "${OUTPUT_DIR}"

cat > "/etc/yum.repos.d/${REPO_ID}.repo" << EOF
[${REPO_ID}]
name=Photon PHP local build
baseurl=file://${OUTPUT_DIR}
enabled=1
$(rpm_gpg_repo_file_snippet "file://${OUTPUT_DIR}")
priority=1
EOF

tdnf makecache || echo "[setup-local-repo] WARNING: tdnf makecache failed (rpm -Uvh fallback still works)"

#!/bin/bash
# build-repo.sh — Create tdnf-compatible RPM repository with createrepo_c
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ARCH="${ARCH:-$(uname -m)}"
REPO_DIR="${REPO_DIR:-${PROJECT_ROOT}/repo/${ARCH}}"
OUTPUT_DIR="${OUTPUT_DIR:-${PROJECT_ROOT}/repo}"
REPO_BASEURL="${REPO_BASEURL:-https://pkgs.photon.lemric.com}"

log() { echo "[build-repo] $*"; }

if ! command -v createrepo_c >/dev/null 2>&1; then
    log "Installing createrepo_c"
    tdnf install -y createrepo_c
fi

if [ ! -d "${REPO_DIR}" ] || [ -z "$(ls -A "${REPO_DIR}"/*.rpm 2>/dev/null)" ]; then
    log "ERROR: No RPMs found in ${REPO_DIR}"
    exit 1
fi

log "Creating repository metadata in ${REPO_DIR}"
# Default gzip metadata — Photon tdnf/libsolv cannot read xz repodata (Solv I/O error).
createrepo_c "${REPO_DIR}"

for arch_dir in "${OUTPUT_DIR}"/*/; do
    [ -d "${arch_dir}" ] || continue
    if ls "${arch_dir}"/*.rpm >/dev/null 2>&1; then
        log "Creating metadata for ${arch_dir}"
        createrepo_c "${arch_dir}"
    fi
done

# Generate repo manifest
cat > "${OUTPUT_DIR}/repodata.json" << EOF
{
  "name": "photon-php",
  "description": "PHP 8.5 RPM repository for VMware Photon OS 5.x",
  "baseurl": "${REPO_BASEURL}",
  "architectures": ["x86_64", "aarch64"],
  "packages": [
    "php85", "php85-cli", "php85-fpm", "php85-common", "php85-devel",
    "php85-opcache", "php85-mbstring", "php85-intl", "php85-xml",
    "php85-curl", "php85-gd", "php85-zip", "php85-bcmath", "php85-soap",
    "php85-sockets", "php85-pcntl", "php85-mysqlnd", "php85-pgsql",
    "php85-pecl-redis", "php85-pecl-igbinary", "php85-pecl-apcu",
    "php85-pecl-amqp", "php85-pecl-imagick", "php85-pecl-xdebug"
  ]
}
EOF

log "Repository ready at ${OUTPUT_DIR}"
log "Public URL: ${REPO_BASEURL}/${ARCH}"
log "Configure tdnf:"
echo ""
echo "  [photon-php]"
echo "  name=Photon PHP 8.5"
echo "  baseurl=${REPO_BASEURL}/${ARCH}"
echo "  enabled=1"
echo "  gpgcheck=0"
echo ""

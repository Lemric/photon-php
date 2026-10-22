#!/bin/bash
# build-repo.sh — Create tdnf-compatible RPM repository with createrepo_c
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=rpm-gpg-common.sh
source "${SCRIPT_DIR}/rpm-gpg-common.sh"
# shellcheck source=php-series.sh
source "${SCRIPT_DIR}/php-series.sh"

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
rpm_gpg_setup
rpm_gpg_sign_directory "${REPO_DIR}"
# Default gzip metadata — Photon tdnf/libsolv cannot read xz repodata (Solv I/O error).
run_createrepo "${REPO_DIR}"

for arch_dir in "${OUTPUT_DIR}"/*/; do
    [ -d "${arch_dir}" ] || continue
    if ls "${arch_dir}"/*.rpm >/dev/null 2>&1; then
        log "Creating metadata for ${arch_dir}"
        rpm_gpg_sign_directory "${arch_dir}"
        run_createrepo "${arch_dir}"
    fi
done

# Generate repo manifest
cat > "${OUTPUT_DIR}/repodata.json" << EOF
{
  "name": "photon-php",
  "description": "PHP RPM repository for VMware Photon OS 5.x",
  "baseurl": "${REPO_BASEURL}",
  "architectures": ["x86_64", "aarch64"],
  "packages": [
    "php${PHP_MAJOR}", "php${PHP_MAJOR}-cli", "php${PHP_MAJOR}-fpm", "php${PHP_MAJOR}-common", "php${PHP_MAJOR}-devel",
    "php${PHP_MAJOR}-opcache", "php${PHP_MAJOR}-mbstring", "php${PHP_MAJOR}-intl", "php${PHP_MAJOR}-xml",
    "php${PHP_MAJOR}-curl", "php${PHP_MAJOR}-gd", "php${PHP_MAJOR}-zip", "php${PHP_MAJOR}-bcmath", "php${PHP_MAJOR}-sodium", "php${PHP_MAJOR}-soap",
    "php${PHP_MAJOR}-sockets", "php${PHP_MAJOR}-pcntl", "php${PHP_MAJOR}-mysqlnd", "php${PHP_MAJOR}-pgsql",
    "php${PHP_MAJOR}-pecl-redis", "php${PHP_MAJOR}-pecl-igbinary", "php${PHP_MAJOR}-pecl-apcu",
    "php${PHP_MAJOR}-pecl-amqp", "php${PHP_MAJOR}-pecl-imagick", "php${PHP_MAJOR}-pecl-xdebug"
  ]
}
EOF

log "Repository ready at ${OUTPUT_DIR}"
log "Public URL: ${REPO_BASEURL}/${ARCH}"
log "Configure tdnf:"
echo ""
echo "  [photon-php]"
echo "  name=Photon PHP"
echo "  baseurl=${REPO_BASEURL}/${ARCH}"
echo "  enabled=1"
rpm_gpg_repo_file_snippet "${REPO_BASEURL}/\${ARCH}" "${REPO_BASEURL}/${RPM_GPG_KEY_FILE_NAME}"
echo ""

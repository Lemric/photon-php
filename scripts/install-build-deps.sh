#!/bin/bash
# install-build-deps.sh — Install RPM build dependencies on VMware Photon OS 5.x
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root." >&2
    exit 1
fi

log() { echo "==> $*"; }

install_pkgs() {
    tdnf install -y "$@"
}

log "Refreshing tdnf metadata"
tdnf makecache

log "Installing Photon OS base build toolchain"
# Photon OS 5.x uses libstdc++-devel instead of gcc-c++, shadow instead of shadow-utils
install_pkgs \
    gcc \
    libstdc++-devel \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    bison \
    rpm-build \
    rpmdevtools \
    createrepo_c \
    tar \
    xz \
    wget \
    curl \
    git \
    shadow \
    systemd-devel \
    findutils \
    which \
    gnupg \
    gawk \
    binutils

log "Installing library development headers (Photon package names)"
# Photon OS package naming differs from Fedora/RHEL — see packaging/photon-packages.md
install_pkgs \
    openssl-devel \
    libxml2-devel \
    sqlite-devel \
    zlib-devel \
    oniguruma-devel \
    icu-devel \
    curl-devel \
    libpng-devel \
    libjpeg-turbo-devel \
    freetype2-devel \
    libwebp-devel \
    postgresql18-devel \
    libsodium-devel \
    libargon2-devel \
    readline-devel

log "Installing optional extension build dependencies"
install_pkgs \
    ImageMagick-devel \
    || log "WARNING: ImageMagick-devel not available — imagick extension may fail."

log "Setting up rpmbuild tree"
rpmdev-setuptree 2>/dev/null || {
    mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
}

log "Installing PHP 8.5 RPM macros"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
install -m 0644 "${PROJECT_ROOT}/packaging/macros.php85" /etc/rpm/macros.php85

log "Build dependencies installed successfully."
log "Note: re2c >= 3.x and libzip are built from source RPMs by scripts/build-rpm.sh"
log "Next: run scripts/build-rpm.sh to build re2c, libzip, and PHP RPMs."

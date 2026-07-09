#!/bin/bash
# install-build-deps.sh — Install RPM build dependencies on VMware Photon OS 5.x
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root." >&2
    exit 1
fi

echo "==> Refreshing tdnf metadata"
tdnf makecache

echo "==> Installing Photon OS base build toolchain"
tdnf install -y \
    gcc \
    gcc-c++ \
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
    shadow-utils \
    systemd-devel \
    findutils \
    which

echo "==> Installing library development headers"
tdnf install -y \
    openssl-devel \
    libxml2-devel \
    sqlite-devel \
    zlib-devel \
    libzip-devel \
    oniguruma-devel \
    libicu-devel \
    libcurl-devel \
    libpng-devel \
    libjpeg-turbo-devel \
    freetype-devel \
    libwebp-devel \
    postgresql-devel \
    || true

echo "==> Installing optional extension build dependencies"
tdnf install -y \
    ImageMagick-devel \
    rabbitmq-c-devel \
    || echo "WARNING: Some optional -devel packages are not in Photon repos."
echo "    Build ImageMagick/rabbitmq-c RPMs from source if needed (see README)."

echo "==> Setting up rpmbuild tree"
rpmdev-setuptree 2>/dev/null || {
    mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
}

echo "==> Installing PHP 8.5 RPM macros"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
install -m 0644 "${PROJECT_ROOT}/packaging/macros.php85" /etc/rpm/macros.php85

echo "==> Build dependencies installed successfully."
echo "    Next: run scripts/build-rpm.sh to build re2c and PHP RPMs."

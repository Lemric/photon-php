#!/bin/bash
# Strip build-time tooling and non-runtime files from a Photon OS container rootfs.
# Intended to run in the Docker BUILD stage (installer), before COPY --from=… /.
set -euo pipefail

log() { echo "==> photon-runtime-cleanup: $*"; }

remove_tdnf_safe() {
    if command -v tdnf >/dev/null 2>&1; then
        tdnf remove -y "$@" 2>/dev/null || true
        tdnf clean all 2>/dev/null || true
    fi
}

remove_rpm_safe() {
    local pkg
    for pkg in "$@"; do
        if command -v rpm >/dev/null 2>&1 && rpm -q "${pkg}" >/dev/null 2>&1; then
            rpm -e --nodeps "${pkg}" 2>/dev/null || true
        fi
    done
}

log "Removing fetch tools and package managers via tdnf (before rpm DB is removed)"
remove_tdnf_safe \
    curl \
    photon-repos \
    elfutils \
    elfutils-libelf \
    tdnf \
    tdnf-cli-libs

log "Removing systemd RPM hooks (not required for php-fpm -F in containers)"
remove_rpm_safe \
    systemd \
    systemd-libs \
    systemd-pam \
    systemd-rpm-macros

log "Removing rpm tooling last"
remove_tdnf_safe rpm rpm-libs rpm-sequoia 2>/dev/null || true
remove_rpm_safe rpm rpm-libs rpm-sequoia

log "Removing documentation, licenses, package manager caches, and orphaned tools"
rm -rf \
    /usr/share/doc \
    /usr/share/man \
    /usr/share/info \
    /usr/share/licenses \
    /var/cache/tdnf \
    /var/cache/* \
    /var/tmp/* \
    /tmp/repo \
    /usr/lib/systemd \
    /usr/lib64/systemd \
    /etc/systemd \
    /root/.cache \
    /root/.gnupg \
    /var/lib/rpm \
    /usr/bin/tdnf \
    /usr/bin/curl \
    /usr/bin/wget \
    /usr/bin/rpm \
    /usr/sbin/rpm \
    /usr/local/bin/install-php-rpms.sh

find /tmp -mindepth 1 -maxdepth 1 ! -name 'hsperfdata_*' -exec rm -rf {} + 2>/dev/null || true

log "Stripping debug symbols from PHP binaries and modules"
if command -v strip >/dev/null 2>&1; then
    strip --strip-unneeded /usr/bin/php /usr/sbin/php-fpm 2>/dev/null || true
    find /usr/lib64/php85/modules -name '*.so' -exec strip --strip-unneeded {} + 2>/dev/null || true
fi

log "Runtime cleanup complete"

#!/bin/bash
# Remove superseded RPM files from a repository directory.
set -euo pipefail

ci_prune_log() { echo "[ci-prune] $*"; }

ensure_rpm_query() {
    if command -v rpm >/dev/null 2>&1; then
        return 0
    fi
    if command -v apt-get >/dev/null 2>&1; then
        ci_prune_log "Installing rpm for package pruning"
        sudo apt-get update -qq
        sudo apt-get install -y rpm
        return 0
    fi
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y rpm
        return 0
    fi
    ci_prune_log "WARNING: rpm not available — skipping prune" >&2
    return 1
}

rpm_pkg_name() {
    rpm -qp --queryformat '%{NAME}' "$1"
}

# Match RPM NAME exactly — never use "${name}-*.rpm" globs (php85-* would match all subpackages).
remove_rpms_with_name() {
    local arch_dir="$1" target_name="$2" existing existing_name

    for existing in "${arch_dir}"/*.rpm; do
        [ -f "${existing}" ] || continue
        existing_name="$(rpm_pkg_name "${existing}")"
        if [ "${existing_name}" = "${target_name}" ]; then
            rm -f "${existing}"
        fi
    done
}

list_rpms_with_name() {
    local arch_dir="$1" target_name="$2" existing existing_name

    for existing in "${arch_dir}"/*.rpm; do
        [ -f "${existing}" ] || continue
        existing_name="$(rpm_pkg_name "${existing}")"
        if [ "${existing_name}" = "${target_name}" ]; then
            basename "${existing}"
        fi
    done
}

# Drop older files in ARCH_DIR that share RPM NAME with RPMs being published.
prune_before_publish() {
    local arch_dir="$1" source_dir="$2" rpm pkg_name

    ensure_rpm_query || return 0

    for rpm in "${source_dir}"/*.rpm; do
        [ -f "${rpm}" ] || continue
        pkg_name="$(rpm_pkg_name "${rpm}")"
        remove_rpms_with_name "${arch_dir}" "${pkg_name}"
    done
}

# Keep only the newest RPM per exact package NAME (by filename sort).
prune_arch_duplicates() {
    local arch_dir="$1"
    local -A names=()
    local pkg_name files latest f rpm

    ensure_rpm_query || return 0

    for rpm in "${arch_dir}"/*.rpm; do
        [ -f "${rpm}" ] || continue
        names["$(rpm_pkg_name "${rpm}")"]=1
    done

    for pkg_name in "${!names[@]}"; do
        mapfile -t files < <(list_rpms_with_name "${arch_dir}" "${pkg_name}" | sort -V)
        if [ "${#files[@]}" -le 1 ]; then
            continue
        fi
        latest="${files[-1]}"
        for f in "${files[@]}"; do
            [ "${f}" = "${latest}" ] && continue
            rm -f "${arch_dir}/${f}"
            ci_prune_log "Removed superseded RPM: ${f}"
        done
    done
}

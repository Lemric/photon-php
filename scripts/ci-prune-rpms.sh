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

# Drop older files in ARCH_DIR that share NAME with RPMs being published.
prune_before_publish() {
    local arch_dir="$1" source_dir="$2" rpm pkg_name

    ensure_rpm_query || return 0

    for rpm in "${source_dir}"/*.rpm; do
        [ -f "${rpm}" ] || continue
        pkg_name="$(rpm -qp --queryformat '%{NAME}' "${rpm}")"
        find "${arch_dir}" -maxdepth 1 -name "${pkg_name}-*.rpm" -delete
    done
}

# Keep only the newest RPM per package NAME (by filename sort).
prune_arch_duplicates() {
    local arch_dir="$1" pkg_name

    ensure_rpm_query || return 0

    while IFS= read -r pkg_name; do
        [ -n "${pkg_name}" ] || continue
        mapfile -t files < <(
            find "${arch_dir}" -maxdepth 1 -name "${pkg_name}-*.rpm" -printf '%f\n' 2>/dev/null \
                | sort -V
        )
        if [ "${#files[@]}" -le 1 ]; then
            continue
        fi
        local latest="${files[-1]}" f
        for f in "${files[@]}"; do
            [ "${f}" = "${latest}" ] && continue
            rm -f "${arch_dir}/${f}"
            ci_prune_log "Removed superseded RPM: ${f}"
        done
    done < <(
        find "${arch_dir}" -maxdepth 1 -name '*.rpm' -print0 \
            | xargs -0 -r rpm -qp --queryformat '%{NAME}\n' 2>/dev/null \
            | sort -u
    )
}

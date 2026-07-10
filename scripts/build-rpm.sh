#!/bin/bash
# build-rpm.sh — Build PHP 8.5 and PECL extension RPMs for Photon OS
#
# Dependency order (each stage installs into the local repo, then tdnf):
#   1. re2c      — Photon ships 1.x; PHP 8.5 needs >= 3.x
#   2. libzip    — not in Photon repos; required by php85-zip
#   3. rabbitmq-c — not in Photon repos; required by php85-pecl-amqp
#   4. php85     — requires re2c >= 3 and libzip-devel
#   5. extensions — require php85-devel
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PHP_VERSION="${PHP_VERSION:-8.5.8}"
ARCH="${ARCH:-$(uname -m)}"
DIST="${DIST:-photon5}"
RELEASE="${RELEASE:-1}"
TARGET="${1:-all}"

RPMBUILD_DIR="${RPMBUILD_DIR:-${PROJECT_ROOT}/.rpmbuild}"
OUTPUT_DIR="${OUTPUT_DIR:-${PROJECT_ROOT}/repo/${ARCH}}"
PUBLISHED_DIR="${PUBLISHED_DIR:-}"

MACROS_FILE="${PROJECT_ROOT}/packaging/macros.php85"

# Ordered stages — do not reorder without updating BuildRequires in specs.
BUILD_STAGES=(re2c libzip rabbitmq-c php extensions)

log() { echo "[build-rpm] $*"; }

refresh_local_repo() {
    OUTPUT_DIR="${OUTPUT_DIR}" REPO_ID=photon-php-build \
        "${SCRIPT_DIR}/setup-local-repo.sh"
}

binary_rpms_in_output() {
    local pattern="${1:?pattern required}"
    local -A seen=()
    local dir rpm base results=()

    for dir in "${OUTPUT_DIR}" ${PUBLISHED_DIR:+"${PUBLISHED_DIR}"}; do
        [ -d "${dir}" ] || continue
        while IFS= read -r rpm; do
            [ -n "${rpm}" ] || continue
            base="$(basename "${rpm}")"
            [ -n "${seen[${base}]+x}" ] && continue
            seen["${base}"]=1
            results+=("${rpm}")
        done < <(find "${dir}" -maxdepth 1 -name "${pattern}" ! -name '*.src.rpm' -type f 2>/dev/null | sort)
    done

    if [ "${#results[@]}" -gt 0 ]; then
        printf '%s\n' "${results[@]}"
    fi
}

install_from_local_repo() {
    local pkg="${1:?package name required}"
    local rpms
    rpms="$(binary_rpms_in_output "${pkg}-*.${ARCH}.rpm" | tr '\n' ' ')"
    if [ -z "${rpms}" ]; then
        log "ERROR: package ${pkg} not found in ${OUTPUT_DIR}${PUBLISHED_DIR:+ or ${PUBLISHED_DIR}}" >&2
        return 1
    fi
    refresh_local_repo
    log "Installing ${pkg} via rpm"
    # tdnf file:// repos fail on bind mounts in CI (Solv I/O error) — rpm -Uvh is reliable.
    # shellcheck disable=SC2086
    rpm -Uvh --replacepkgs ${rpms}
}

re2c_version_ok() {
    command -v re2c >/dev/null 2>&1 || return 1
    local ver
    ver="$(re2c --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo 0)"
    awk "BEGIN {exit !(${ver:-0} >= 3.0)}"
}

libzip_installed() {
    pkg-config --exists libzip 2>/dev/null || rpm -q libzip-devel >/dev/null 2>&1
}

rabbitmq_c_installed() {
    rpm -q rabbitmq-c-devel >/dev/null 2>&1
}

igbinary_build_headers_installed() {
    test -f /usr/include/php85/php/ext/igbinary/igbinary.h
}

ensure_igbinary() {
    if igbinary_build_headers_installed; then
        log "php85-pecl-igbinary headers already installed"
        return 0
    fi
    if [ -n "$(binary_rpms_in_output "php85-pecl-igbinary-*.${ARCH}.rpm")" ]; then
        log "Installing pre-built php85-pecl-igbinary from local/published repo"
        install_from_local_repo php85-pecl-igbinary
        igbinary_build_headers_installed && return 0
    fi
    log "Building php85-pecl-igbinary (redis requires igbinary.h headers)"
    build_spec "${PROJECT_ROOT}/extensions/igbinary.spec"
    install_from_local_repo php85-pecl-igbinary
    igbinary_build_headers_installed || {
        log "ERROR: php85-pecl-igbinary with headers required before building redis" >&2
        return 1
    }
}

php85_devel_installed() {
    rpm -q php85-devel >/dev/null 2>&1
}

install_php85_stack() {
    local rpms
    rpms="$(
        find "${OUTPUT_DIR}" -maxdepth 1 -name "php85*.${ARCH}.rpm" \
            ! -name 'php85-pecl-*' ! -name '*.src.rpm' -type f 2>/dev/null \
            | sort | tr '\n' ' '
    )"
    if [ -z "${rpms}" ]; then
        log "ERROR: php85 packages not found in ${OUTPUT_DIR}" >&2
        return 1
    fi
    refresh_local_repo
    log "Installing PHP stack (single transaction for circular Requires)"
    # php85 <-> php85-common have circular Requires — one rpm -Uvh for all core packages.
    # shellcheck disable=SC2086
    rpm -Uvh --replacepkgs ${rpms}
}

fetch_remote_sources() {
    local spec_file="$1"
    local spec_name
    spec_name="$(basename "${spec_file}")"
    local spec_path="${RPMBUILD_DIR}/SPECS/${spec_name}"
    local spec_dir="${RPMBUILD_DIR}/SPECS"
    local sourcedir="${RPMBUILD_DIR}/SOURCES"
    local urls=""

    mkdir -p "${sourcedir}"

    if ! command -v rpmspec >/dev/null 2>&1; then
        log "ERROR: rpmspec not found — cannot expand Source URLs for ${spec_name}" >&2
        return 1
    fi

    # Run rpmspec from SPECS/ so %include fragments (php85-*.spec, macros.inc) resolve.
    urls="$(cd "${spec_dir}" && rpmspec -P \
        --define "_topdir ${RPMBUILD_DIR}" \
        --define "dist .${DIST}" \
        "${spec_name}" 2>/dev/null \
        | grep -E '^Source[0-9]+:[[:space:]]*https?://' \
        | sed -E 's/^Source[0-9]+:[[:space:]]*//' || true)"

    if [ -z "${urls}" ]; then
        local version="" name=""
        version="$(cd "${spec_dir}" && rpmspec -q --qf '%{version}' \
            --define "_topdir ${RPMBUILD_DIR}" \
            --define "dist .${DIST}" \
            "${spec_name}" 2>/dev/null || true)"
        name="$(cd "${spec_dir}" && rpmspec -q --qf '%{name}' \
            --define "_topdir ${RPMBUILD_DIR}" \
            --define "dist .${DIST}" \
            "${spec_name}" 2>/dev/null || true)"
        while IFS= read -r line; do
            [[ "${line}" =~ ^Source[0-9]+[[:space:]]*:[[:space:]]*(https?://.+) ]] || continue
            local url="${BASH_REMATCH[1]}"
            url="${url//%\{version\}/${version}}"
            url="${url//%\{name\}/${name}}"
            [[ "${url}" == *"%{"* ]] && continue
            urls+="${url}"$'\n'
        done < "${spec_path}"
    fi

    if [ -z "${urls}" ]; then
        log "ERROR: no remote Source URLs found in ${spec_name}" >&2
        return 1
    fi

    while IFS= read -r url; do
        [ -n "${url}" ] || continue
        local dest="${sourcedir}/$(basename "${url}")"
        if [ -f "${dest}" ]; then
            log "Source already present: $(basename "${dest}")"
            continue
        fi
        log "Downloading source: ${url}"
        curl -fSL -o "${dest}" "${url}"
    done <<< "${urls}"
}

setup_rpmbuild() {
    log "Setting up rpmbuild tree at ${RPMBUILD_DIR}"
    mkdir -p "${RPMBUILD_DIR}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    mkdir -p "${OUTPUT_DIR}"
}

build_spec() {
    local spec_file="$1"
    local spec_name
    spec_name="$(basename "${spec_file}")"

    log "Building ${spec_name} for ${ARCH}"

    cp -f "${spec_file}" "${RPMBUILD_DIR}/SPECS/${spec_name}"

    if [[ "${spec_name}" == "php85.spec" ]]; then
        cp -f "${PROJECT_ROOT}/packaging/php85-"*.spec "${RPMBUILD_DIR}/SPECS/"
        cp -f "${PROJECT_ROOT}/packaging/configs/"* "${RPMBUILD_DIR}/SOURCES/"
    fi

    if [[ "${spec_file}" == */extensions/* ]]; then
        cp -f "${PROJECT_ROOT}/extensions/macros.inc" "${RPMBUILD_DIR}/SPECS/"
    fi

    fetch_remote_sources "${spec_file}"

    (cd "${RPMBUILD_DIR}/SPECS" && rpmbuild -ba \
        --define "_topdir ${RPMBUILD_DIR}" \
        --define "_sourcedir ${RPMBUILD_DIR}/SOURCES" \
        --define "dist .${DIST}" \
        --target "${ARCH}" \
        "${spec_name}")

    find "${RPMBUILD_DIR}/RPMS/${ARCH}" -name '*.rpm' ! -name '*.src.rpm' \
        -exec cp -f {} "${OUTPUT_DIR}/" \;
    find "${RPMBUILD_DIR}/SRPMS" -name '*.src.rpm' -exec cp -f {} "${OUTPUT_DIR}/" \; 2>/dev/null || true

    refresh_local_repo
}

detect_php_api() {
    if ! command -v php-config >/dev/null 2>&1; then
        return 0
    fi

    local extdir api zend_api
    extdir="$(php-config --extension-dir 2>/dev/null || true)"
    api="${extdir##*-}"
    if [[ "${api}" =~ ^[0-9]{8}$ ]]; then
        zend_api="4${api}"
        log "Detected PHP API version: ${api} (zend ${zend_api})"
        sed -i "s/%global php85_api.*/%global php85_api          ${api}/" "${MACROS_FILE}" 2>/dev/null || \
            sed -i '' "s/%global php85_api.*/%global php85_api          ${api}/" "${MACROS_FILE}" 2>/dev/null || true
        sed -i "s/%define php85_zend_api.*/%define php85_zend_api ${zend_api}/" "${MACROS_FILE}" 2>/dev/null || \
            sed -i '' "s/%define php85_zend_api.*/%define php85_zend_api ${zend_api}/" "${MACROS_FILE}" 2>/dev/null || true
    fi
}

ensure_re2c() {
    if re2c_version_ok; then
        log "re2c $(re2c --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1) already available"
        return 0
    fi
    if [ -n "$(binary_rpms_in_output "re2c-*.${ARCH}.rpm")" ]; then
        log "Installing pre-built re2c from ${OUTPUT_DIR}"
        install_from_local_repo re2c
        re2c_version_ok && return 0
    fi
    build_re2c
}

ensure_libzip() {
    if libzip_installed; then
        log "libzip-devel already installed"
        return 0
    fi
    if [ -n "$(binary_rpms_in_output "libzip-*.${ARCH}.rpm")" ]; then
        log "Installing pre-built libzip from ${OUTPUT_DIR}"
        install_from_local_repo libzip
        install_from_local_repo libzip-devel
        libzip_installed && return 0
    fi
    build_libzip
}

ensure_rabbitmq_c() {
    if rabbitmq_c_installed; then
        log "rabbitmq-c-devel already installed"
        return 0
    fi
    if tdnf info rabbitmq-c-devel >/dev/null 2>&1; then
        tdnf install -y rabbitmq-c-devel
        return 0
    fi
    if [ -n "$(binary_rpms_in_output "rabbitmq-c-*.${ARCH}.rpm")" ]; then
        log "Installing pre-built rabbitmq-c from ${OUTPUT_DIR}"
        install_from_local_repo rabbitmq-c
        install_from_local_repo rabbitmq-c-devel
        rabbitmq_c_installed && return 0
    fi
    build_rabbitmq_c
}

ensure_php() {
    if php85_devel_installed; then
        log "php85-devel already installed"
        return 0
    fi
    if [ -n "$(binary_rpms_in_output "php85-devel-*.${ARCH}.rpm")" ]; then
        log "Installing pre-built php85 from ${OUTPUT_DIR}"
        install_php85_stack
        php85_devel_installed && return 0
    fi
    build_php
}

build_re2c() {
    log "Stage 1/5: re2c >= 3.x (PHP 8.5 build dependency)"
    build_spec "${PROJECT_ROOT}/packaging/re2c.spec"
    install_from_local_repo re2c
    re2c_version_ok || { log "ERROR: re2c >= 3 not available after install"; exit 1; }
    re2c --version
}

build_libzip() {
    log "Stage 2/5: libzip (php85-zip dependency)"
    build_spec "${PROJECT_ROOT}/packaging/libzip.spec"
    install_from_local_repo libzip
    install_from_local_repo libzip-devel
}

build_rabbitmq_c() {
    log "Stage 3/5: rabbitmq-c (php85-pecl-amqp dependency)"
    build_spec "${PROJECT_ROOT}/packaging/rabbitmq-c.spec"
    install_from_local_repo rabbitmq-c
    install_from_local_repo rabbitmq-c-devel
}

build_php() {
    log "Stage 4/5: PHP ${PHP_VERSION} (requires re2c >= 3, libzip-devel)"
    ensure_re2c
    ensure_libzip

    build_spec "${PROJECT_ROOT}/packaging/php85.spec"

    log "Installing PHP RPMs for extension builds"
    install_php85_stack

    php85_devel_installed || { log "ERROR: php85-devel not installed"; exit 1; }
    detect_php_api
}

imagick_build_available() {
    pkg-config ImageMagick --exists 2>/dev/null \
        || rpm -q ImageMagick-devel >/dev/null 2>&1
}

PECL_EXTENSIONS=(igbinary redis apcu amqp imagick xdebug)

build_single_extension() {
    local ext="${1:?extension name required}"
    ensure_re2c
    ensure_libzip
    ensure_php
    if [ "${ext}" = amqp ]; then
        ensure_rabbitmq_c
    fi
    if [ "${ext}" = redis ]; then
        ensure_igbinary
    fi
    if [ "${ext}" = imagick ] && ! imagick_build_available; then
        log "Skipping imagick — ImageMagick-devel not available on this platform"
        return 0
    fi

    export PHP_CONFIG=/usr/bin/php-config
    export PHP_PREFIX=/usr

    log "Building extension: ${ext}"
    build_spec "${PROJECT_ROOT}/extensions/${ext}.spec"
    install_from_local_repo "php85-pecl-${ext}"
}

build_extensions() {
    log "Stage 5/5: PECL extensions (require php85-devel)"
    local ext
    for ext in "${PECL_EXTENSIONS[@]}"; do
        build_single_extension "${ext}"
    done
}

run_stage() {
    case "${1}" in
        re2c) build_re2c ;;
        libzip) ensure_re2c; build_libzip ;;
        rabbitmq-c) build_rabbitmq_c ;;
        php) build_php ;;
        extensions) build_extensions ;;
        *) echo "Unknown stage: ${1}" >&2; return 1 ;;
    esac
}

main() {
    setup_rpmbuild

    case "${TARGET}" in
        re2c) run_stage re2c ;;
        libzip) run_stage libzip ;;
        rabbitmq-c) run_stage rabbitmq-c ;;
        php) run_stage php ;;
        extensions) run_stage extensions ;;
        extension:*)
            build_single_extension "${TARGET#extension:}"
            ;;
        deps)
            run_stage re2c
            run_stage libzip
            run_stage rabbitmq-c
            ;;
        all)
            for stage in "${BUILD_STAGES[@]}"; do
                run_stage "${stage}"
            done
            ;;
        *)
            echo "Usage: $0 [re2c|libzip|rabbitmq-c|php|extensions|extension:NAME|deps|all]" >&2
            echo "  re2c            — bootstrap re2c >= 3.x" >&2
            echo "  libzip          — re2c, then libzip" >&2
            echo "  rabbitmq-c      — rabbitmq-c only" >&2
            echo "  php             — re2c, libzip, then php85" >&2
            echo "  extensions      — full chain through php85, then PECL" >&2
            echo "  extension:NAME  — single PECL extension (e.g. extension:redis)" >&2
            echo "  deps            — bootstrap packages only (re2c, libzip, rabbitmq-c)" >&2
            echo "  all             — complete repository (default)" >&2
            exit 1
            ;;
    esac

    log "RPMs written to ${OUTPUT_DIR}"
    ls -la "${OUTPUT_DIR}"/*.rpm 2>/dev/null || true
}

main "$@"

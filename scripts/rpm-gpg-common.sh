#!/bin/bash
# GPG signing helpers for Photon PHP RPM packages and repository metadata.
set -euo pipefail

RPM_GPG_KEY_FILE_NAME="${RPM_GPG_KEY_FILE_NAME:-RPM-GPG-KEY-photon-php}"

rpm_gpg_log() { echo "[rpm-gpg] $*"; }

rpm_gpg_enabled() {
    [ -n "${RPM_GPG_PRIVATE_KEY:-}" ] && [ -n "${RPM_GPG_KEY_ID:-}" ]
}

rpm_gpg_require_ci() {
    if [ -n "${GITHUB_ACTIONS:-}" ] && ! rpm_gpg_enabled; then
        rpm_gpg_log "ERROR: CI requires RPM_GPG_PRIVATE_KEY and RPM_GPG_KEY_ID GitHub secrets" >&2
        rpm_gpg_log "See packaging/GPG.md for setup instructions" >&2
        exit 1
    fi
}

rpm_gpg_home() {
    echo "${RPM_GPG_HOME:-${HOME}/.gnupg-photon-php}"
}

rpm_gpg_setup() {
    if ! rpm_gpg_enabled; then
        rpm_gpg_log "GPG signing disabled (no RPM_GPG_PRIVATE_KEY / RPM_GPG_KEY_ID)"
        return 0
    fi

    local gpg_home key_id macros_file passphrase_arg
    gpg_home="$(rpm_gpg_home)"
    key_id="${RPM_GPG_KEY_ID:?RPM_GPG_KEY_ID is required when RPM_GPG_PRIVATE_KEY is set}"
    macros_file="${HOME}/.rpmmacros"

    if ! command -v gpg >/dev/null 2>&1; then
        rpm_gpg_log "ERROR: gpg not found" >&2
        exit 1
    fi
    if ! command -v rpmsign >/dev/null 2>&1; then
        rpm_gpg_log "ERROR: rpmsign not found" >&2
        exit 1
    fi

    mkdir -p "${gpg_home}"
    chmod 700 "${gpg_home}"

    if [ -n "${RPM_GPG_PRIVATE_KEY:-}" ]; then
        gpg --homedir "${gpg_home}" --batch --import <<< "${RPM_GPG_PRIVATE_KEY}"
    fi

    # Ubuntu's rpm does not expand %{__key_id} in %__gpg_sign_cmd — use the literal key id.
    cat > "${macros_file}" <<EOF
%_signature gpg
%_gpg_name ${key_id}
%_gpg_path ${gpg_home}
EOF

    if [ -n "${RPM_GPG_PASSPHRASE:-}" ]; then
        cat >> "${macros_file}" <<EOF
%__gpg_sign_cmd %{__gpg} gpg --homedir ${gpg_home} --batch --no-tty --pinentry-mode loopback --passphrase ${RPM_GPG_PASSPHRASE} --no-permission-warning -q -u ${key_id} -o %{__signature_filename} -s %{__plaintext_filename}
EOF
    else
        cat >> "${macros_file}" <<EOF
%__gpg_sign_cmd %{__gpg} gpg --homedir ${gpg_home} --batch --no-tty --pinentry-mode loopback --no-permission-warning -q -u ${key_id} -o %{__signature_filename} -s %{__plaintext_filename}
EOF
    fi

    export GNUPGHOME="${gpg_home}"
    export GPG_TTY="${GPG_TTY:-}"
    rpm_gpg_log "GPG signing configured for key ${key_id}"
}

rpm_gpg_is_signed() {
    local rpm="$1"
    rpm -Kv "${rpm}" 2>&1 | grep -qiE 'RSA|DSA|ECDSA|EDDSA' \
        && ! rpm -Kv "${rpm}" 2>&1 | grep -qi 'NOT OK'
}

rpm_gpg_sign_file() {
    local rpm="$1"

    if ! rpm_gpg_enabled; then
        return 0
    fi

    if rpm_gpg_is_signed "${rpm}"; then
        rpm_gpg_log "Already signed: $(basename "${rpm}")"
        return 0
    fi

    rpm_gpg_log "Signing $(basename "${rpm}")"
    rpmsign --addsign "${rpm}"
}

rpm_gpg_sign_directory() {
    local dir="$1" rpm

    if ! rpm_gpg_enabled; then
        return 0
    fi

    shopt -s nullglob
    for rpm in "${dir}"/*.rpm; do
        [[ "${rpm}" == *.src.rpm ]] && continue
        rpm_gpg_sign_file "${rpm}"
    done
}

rpm_gpg_export_public_key() {
    local dest="$1"

    if ! rpm_gpg_enabled; then
        rpm_gpg_log "ERROR: cannot export public key without GPG configuration" >&2
        return 1
    fi

    gpg --homedir "$(rpm_gpg_home)" --batch --armor --export "${RPM_GPG_KEY_ID}" > "${dest}"
    rpm_gpg_log "Exported public key to ${dest}"
}

rpm_gpg_publish_public_key() {
    local dest_dir="$1"
    local pages_key="${2:-}"
    local dest="${dest_dir}/${RPM_GPG_KEY_FILE_NAME}"

    mkdir -p "${dest_dir}"

    if rpm_gpg_enabled; then
        rpm_gpg_export_public_key "${dest}"
        return 0
    fi

    if [ -n "${pages_key}" ] && [ -f "${pages_key}" ]; then
        cp -f "${pages_key}" "${dest}"
        return 0
    fi

    rpm_gpg_log "WARNING: no GPG public key available for publish" >&2
    return 1
}

createrepo_gpg_args() {
    if rpm_gpg_enabled; then
        printf '%s\n' --gpg-sign "--gpg-key=${RPM_GPG_KEY_ID}"
    fi
}

run_createrepo() {
    local dir="$1"
    shift || true
    local -a gpg_args=()
    mapfile -t gpg_args < <(createrepo_gpg_args)
    if [ "${#gpg_args[@]}" -gt 0 ]; then
        createrepo_c "${gpg_args[@]}" "$@" "${dir}"
    else
        createrepo_c "$@" "${dir}"
    fi
}

rpm_gpg_repo_file_snippet() {
    local baseurl="${1:-https://pkgs.photon.lemric.com/\$basearch}"
    local gpgkey_url="${2:-https://pkgs.photon.lemric.com/${RPM_GPG_KEY_FILE_NAME}}"

    if rpm_gpg_enabled; then
        cat <<EOF
gpgcheck=1
gpgkey=${gpgkey_url}
EOF
    else
        echo "gpgcheck=0"
    fi
}

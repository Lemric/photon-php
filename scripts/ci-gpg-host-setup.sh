#!/bin/bash
# Prepare GPG signing on GitHub Actions host runners (publish/reindex).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v apt-get >/dev/null 2>&1; then
    if ! command -v gpg >/dev/null 2>&1 || ! command -v rpmsign >/dev/null 2>&1; then
        sudo apt-get update -qq
        sudo apt-get install -y gnupg rpm
    fi
fi

# shellcheck source=rpm-gpg-common.sh
source "${SCRIPT_DIR}/rpm-gpg-common.sh"
rpm_gpg_require_ci
rpm_gpg_setup

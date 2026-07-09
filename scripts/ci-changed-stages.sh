#!/bin/bash
# Print build stages that need rebuilding for the given group and architecture.
set -euo pipefail

GROUP="${1:?group required: bootstrap|php}"
ARCH="${2:?arch required}"
PUBLISHED_DIR="${3:-published}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${GROUP}" in
    bootstrap) stages=(re2c libzip rabbitmq-c) ;;
    php)
        stages=(php)
        for ext in igbinary redis apcu amqp imagick xdebug; do
            stages+=("extension:${ext}")
        done
        ;;
    *)
        echo "ERROR: unknown group '${GROUP}'" >&2
        exit 1
        ;;
esac

for stage in "${stages[@]}"; do
    if [ "${GROUP}" = "php" ] && [ "${stage}" != "php" ] && "${SCRIPT_DIR}/ci-needs-build.sh" php "${ARCH}" "${PUBLISHED_DIR}"; then
        echo "${stage}"
        continue
    fi
    if "${SCRIPT_DIR}/ci-needs-build.sh" "${stage}" "${ARCH}" "${PUBLISHED_DIR}"; then
        echo "${stage}"
    fi
done

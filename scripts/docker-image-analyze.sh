#!/usr/bin/env bash
# Analyze Docker image size, layers, and optionally run dive/trivy scans.
# Usage: scripts/docker-image-analyze.sh <image> [output_dir]
set -euo pipefail

IMAGE="${1:?image reference required}"
OUT_DIR="${2:-docker/image-analysis}"

mkdir -p "${OUT_DIR}"
SAFE_NAME="$(echo "${IMAGE}" | tr '/:' '__')"
REPORT="${OUT_DIR}/${SAFE_NAME}.txt"
JSON="${OUT_DIR}/${SAFE_NAME}.json"

bytes_to_human() {
    local bytes="$1"
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec-i --suffix=B "${bytes}"
    else
        echo "${bytes} bytes"
    fi
}

SIZE_BYTES="$(docker image inspect "${IMAGE}" --format '{{.Size}}')"
LAYER_COUNT="$(docker image inspect "${IMAGE}" --format '{{len .RootFS.Layers}}')"

{
    echo "Image: ${IMAGE}"
    echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    echo "IMAGE_SIZE=$(bytes_to_human "${SIZE_BYTES}") (${SIZE_BYTES} bytes)"
    echo "LAYERS=${LAYER_COUNT}"
    echo
    echo "=== docker history (top 20) ==="
    docker history "${IMAGE}" --no-trunc --format '{{.Size}}\t{{.CreatedBy}}' | head -20
    echo
    echo "=== largest top-level directories (if runnable) ==="
    if docker run --rm --entrypoint '' "${IMAGE}" sh -c 'du -sh /* 2>/dev/null | sort -hr | head -15' 2>/dev/null; then
        :
    else
        echo "(image has no shell — skipped du)"
    fi
    echo
    echo "=== installed RPMs (if rpm available) ==="
    docker run --rm --entrypoint '' "${IMAGE}" sh -c 'rpm -qa 2>/dev/null | sort | wc -l; rpm -qa 2>/dev/null | sort' 2>/dev/null \
        || echo "(rpm not available in runtime image)"
} | tee "${REPORT}"

docker image inspect "${IMAGE}" > "${JSON}"

if command -v dive >/dev/null 2>&1; then
    echo "=== dive ===" | tee -a "${REPORT}"
    CI=true dive "${IMAGE}" --source docker-archive 2>&1 | tee -a "${REPORT}" || true
else
    echo "dive: not installed (optional)" | tee -a "${REPORT}"
fi

if command -v trivy >/dev/null 2>&1; then
    echo "=== trivy filesystem (container) ===" | tee -a "${REPORT}"
    trivy image --severity HIGH,CRITICAL --no-progress "${IMAGE}" 2>&1 | tee -a "${REPORT}" || true
else
    echo "trivy: not installed (optional)" | tee -a "${REPORT}"
fi

echo "Report written to ${REPORT}"

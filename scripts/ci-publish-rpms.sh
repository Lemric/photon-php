#!/bin/bash
# Incrementally merge RPMs into the gh-pages package repository and push.
# Called from GitHub Actions on the host runner after each build stage.
set -euo pipefail

ARCH="${1:?architecture required (x86_64 or aarch64)}"
SOURCE_DIR="${2:?source directory with *.rpm required}"
STAGE="${3:-packages}"
RPMS_ONLY=0

if [ "${STAGE}" = "--rpms-only" ]; then
    RPMS_ONLY=1
    STAGE="${4:-packages}"
fi

PHP_VERSION="${PHP_VERSION:-8.5.8}"
REPO_BASEURL="${REPO_BASEURL:-https://pkgs.photon.lemric.com}"
PUBLISH_BRANCH="${PUBLISH_BRANCH:-gh-pages}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
GITHUB_SHA="${GITHUB_SHA:-local}"
GITHUB_TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="$(cd "${SOURCE_DIR}" && pwd)"
PAGES_DIR="${PROJECT_ROOT}/pages"

log() { echo "[ci-publish] $*"; }

if ! ls "${SOURCE_DIR}"/*.rpm >/dev/null 2>&1; then
    log "WARNING: no RPMs in ${SOURCE_DIR} — skipping publish for ${STAGE}"
    exit 0
fi

if ! command -v createrepo_c >/dev/null 2>&1; then
    log "Installing createrepo_c"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq
        sudo apt-get install -y createrepo-c
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y createrepo_c
    else
        log "ERROR: createrepo_c not found and cannot be installed" >&2
        exit 1
    fi
fi

generate_repodata_json() {
    local publish_arch="$1"
    local publish_stage="$2"
    python3 - "${publish_arch}" "${publish_stage}" "${PHP_VERSION}" "${REPO_BASEURL}" "${GITHUB_SHA}" <<'PY'
import glob
import json
import os
import sys
from datetime import datetime, timezone

publish_arch, publish_stage, php_version, baseurl, commit = sys.argv[1:6]
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

existing = {}
if os.path.isfile("repodata.json"):
    try:
        with open("repodata.json", encoding="utf-8") as fh:
            existing = json.load(fh)
    except (json.JSONDecodeError, OSError):
        existing = {}

architectures = {}
all_packages = set()

def prior_arch(existing_data, arch_name):
    raw = existing_data.get("architectures")
    if isinstance(raw, dict):
        return raw.get(arch_name, {})
    return {}

for arch in ("x86_64", "aarch64"):
    rpms = sorted(glob.glob(f"{arch}/*.rpm"))
    if not rpms:
        continue

    rpm_names = [os.path.basename(rpm) for rpm in rpms]
    pkg_names = sorted({name.rsplit(".", 2)[0] for name in rpm_names})
    all_packages.update(pkg_names)

    prev = prior_arch(existing, arch)
    architectures[arch] = {
        "package_count": len(rpm_names),
        "packages": rpm_names,
        "package_names": pkg_names,
        "last_updated": now if arch == publish_arch else prev.get("last_updated", now),
        "last_stage": publish_stage if arch == publish_arch else prev.get("last_stage"),
    }

manifest = {
    "name": existing.get("name", "photon-php"),
    "description": existing.get(
        "description",
        "PHP 8.5 RPM repository for VMware Photon OS 5.x",
    ),
    "baseurl": baseurl,
    "php_version": php_version,
    "architectures": architectures,
    "packages": sorted(all_packages),
    "updated": now,
    "commit": commit,
    "last_publish": {
        "arch": publish_arch,
        "stage": publish_stage,
        "updated": now,
    },
}

with open("repodata.json", "w", encoding="utf-8") as fh:
    json.dump(manifest, fh, indent=2)
    fh.write("\n")
PY
}

apply_publish() {
    mkdir -p "${ARCH}"
    cp -a "${SOURCE_DIR}"/*.rpm "${ARCH}/"
    find "${ARCH}" -maxdepth 1 -name '*.src.rpm' -delete 2>/dev/null || true

    if [ "${RPMS_ONLY}" -eq 1 ]; then
        log "Copied RPMs to ${ARCH} (index rebuild deferred)"
        return 0
    fi

    log "Regenerating createrepo metadata for ${ARCH} ($(find "${ARCH}" -maxdepth 1 -name '*.rpm' | wc -l | tr -d ' ') RPMs)"
    rm -rf "${ARCH}/repodata"
    # Default gzip metadata — Photon tdnf/libsolv cannot read xz repodata (Solv I/O error).
    createrepo_c "${ARCH}"

    cp "${PAGES_DIR}/CNAME" "${PAGES_DIR}/.nojekyll" "${PAGES_DIR}/photon-php.repo" "${PAGES_DIR}/index.html" .
    cp "${PAGES_DIR}/BRANCH-README.md" README.md
    sed -i "s/@PHP_VERSION@/${PHP_VERSION}/g" index.html
    sed -i "s|@GITHUB_REPOSITORY@|${GITHUB_REPOSITORY}|g" index.html

    generate_repodata_json "${ARCH}" "${STAGE}"
}

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

if git clone --depth 1 --branch "${PUBLISH_BRANCH}" "${REPO_URL}" "${WORKDIR}/repo" 2>/dev/null; then
    log "Checked out existing ${PUBLISH_BRANCH}"
else
    log "Initializing new ${PUBLISH_BRANCH} branch"
    git -c init.defaultBranch="${PUBLISH_BRANCH}" init "${WORKDIR}/repo"
fi

cd "${WORKDIR}/repo"
git config user.name 'github-actions[bot]'
git config user.email 'github-actions[bot]@users.noreply.github.com'

if ! git rev-parse --verify "${PUBLISH_BRANCH}" >/dev/null 2>&1; then
    git checkout -b "${PUBLISH_BRANCH}"
elif [ "$(git branch --show-current)" != "${PUBLISH_BRANCH}" ]; then
    git checkout "${PUBLISH_BRANCH}"
fi

COMMIT_MSG="publish: ${ARCH} ${STAGE} (${GITHUB_SHA:0:7})"
if [ "${RPMS_ONLY}" -eq 1 ]; then
    COMMIT_MSG="publish: ${ARCH} ${STAGE} rpms (${GITHUB_SHA:0:7})"
fi

apply_publish
git add -A

if git diff --staged --quiet; then
    log "No changes to publish for ${ARCH}/${STAGE}"
    exit 0
fi

git commit -m "${COMMIT_MSG}"

for attempt in 1 2 3 4 5 6; do
    if git push origin "HEAD:${PUBLISH_BRANCH}"; then
        log "Published ${ARCH}/${STAGE} to ${PUBLISH_BRANCH}"
        exit 0
    fi

    log "Push conflict (attempt ${attempt}) — rebasing on remote and re-applying publish"
    git fetch origin "${PUBLISH_BRANCH}"
    git reset --hard "origin/${PUBLISH_BRANCH}"
    apply_publish
    git add -A
    if git diff --staged --quiet; then
        log "Remote already contains ${ARCH}/${STAGE}"
        exit 0
    fi
    git commit -m "${COMMIT_MSG}"
    sleep $((attempt * 2))
done

log "ERROR: failed to push ${PUBLISH_BRANCH} after retries" >&2
exit 1

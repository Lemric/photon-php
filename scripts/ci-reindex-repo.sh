#!/bin/bash
# Rebuild createrepo metadata and repodata.json for all architectures on gh-pages.
set -euo pipefail

PHP_VERSION="${PHP_VERSION:-8.5.8}"
REPO_BASEURL="${REPO_BASEURL:-https://pkgs.photon.lemric.com}"
PUBLISH_BRANCH="${PUBLISH_BRANCH:-gh-pages}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
GITHUB_SHA="${GITHUB_SHA:-local}"
GITHUB_TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PAGES_DIR="${PROJECT_ROOT}/pages"

log() { echo "[ci-reindex] $*"; }

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
    python3 - "reindex" "${PHP_VERSION}" "${REPO_BASEURL}" "${GITHUB_SHA}" <<'PY'
import glob
import json
import os
import sys
from datetime import datetime, timezone

publish_stage, php_version, baseurl, commit = sys.argv[1:5]
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

for arch in ("x86_64", "aarch64"):
    rpms = sorted(glob.glob(f"{arch}/*.rpm"))
    if not rpms:
        continue

    rpm_names = [os.path.basename(rpm) for rpm in rpms]
    pkg_names = sorted({name.rsplit(".", 2)[0] for name in rpm_names})
    all_packages.update(pkg_names)

    prev = (existing.get("architectures") or {}).get(arch, {})
    architectures[arch] = {
        "package_count": len(rpm_names),
        "packages": rpm_names,
        "package_names": pkg_names,
        "last_updated": now,
        "last_stage": publish_stage,
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
        "arch": "all",
        "stage": publish_stage,
        "updated": now,
    },
}

with open("repodata.json", "w", encoding="utf-8") as fh:
    json.dump(manifest, fh, indent=2)
    fh.write("\n")
PY
}

apply_reindex() {
    local arch reindexed=0

    for arch in x86_64 aarch64; do
        if ! ls "${arch}"/*.rpm >/dev/null 2>&1; then
            log "No RPMs in ${arch} — skipping createrepo"
            continue
        fi
        log "Regenerating createrepo metadata for ${arch} ($(find "${arch}" -maxdepth 1 -name '*.rpm' | wc -l | tr -d ' ') RPMs)"
        rm -rf "${arch}/repodata"
        createrepo_c --general-compress-type xz "${arch}"
        reindexed=1
    done

    if [ "${reindexed}" -eq 0 ]; then
        log "WARNING: no RPMs found in gh-pages — nothing to index" >&2
        return 1
    fi

    cp "${PAGES_DIR}/CNAME" "${PAGES_DIR}/.nojekyll" "${PAGES_DIR}/photon-php.repo" "${PAGES_DIR}/index.html" .
    cp "${PAGES_DIR}/BRANCH-README.md" README.md
    sed -i "s/@PHP_VERSION@/${PHP_VERSION}/g" index.html
    sed -i "s|@GITHUB_REPOSITORY@|${GITHUB_REPOSITORY}|g" index.html
    generate_repodata_json
}

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

if git clone --depth 1 --branch "${PUBLISH_BRANCH}" "${REPO_URL}" "${WORKDIR}/repo" 2>/dev/null; then
    log "Checked out existing ${PUBLISH_BRANCH}"
else
    log "ERROR: ${PUBLISH_BRANCH} branch not found — publish RPMs first" >&2
    exit 1
fi

cd "${WORKDIR}/repo"
git config user.name 'github-actions[bot]'
git config user.email 'github-actions[bot]@users.noreply.github.com'

COMMIT_MSG="reindex: package repository (${GITHUB_SHA:0:7})"

apply_reindex
git add -A

if git diff --staged --quiet; then
    log "Repository index already up to date"
    exit 0
fi

git commit -m "${COMMIT_MSG}"

for attempt in 1 2 3 4 5 6; do
    if git push origin "HEAD:${PUBLISH_BRANCH}"; then
        log "Reindexed ${PUBLISH_BRANCH}"
        exit 0
    fi

    log "Push conflict (attempt ${attempt}) — rebasing and re-applying reindex"
    git fetch origin "${PUBLISH_BRANCH}"
    git reset --hard "origin/${PUBLISH_BRANCH}"
    apply_reindex
    git add -A
    if git diff --staged --quiet; then
        log "Remote index already up to date"
        exit 0
    fi
    git commit -m "${COMMIT_MSG}"
    sleep $((attempt * 2))
done

log "ERROR: failed to push ${PUBLISH_BRANCH} after retries" >&2
exit 1

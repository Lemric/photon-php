#!/bin/bash
# Incrementally merge RPMs into the gh-pages package repository and push.
# Called from GitHub Actions on the host runner after each build stage.
set -euo pipefail

ARCH="${1:?architecture required (x86_64 or aarch64)}"
SOURCE_DIR="${2:?source directory with *.rpm required}"
STAGE="${3:-packages}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="$(cd "${SOURCE_DIR}" && pwd)"
PAGES_DIR="${PROJECT_ROOT}/pages"

PHP_VERSION="${PHP_VERSION:-8.5.8}"
REPO_BASEURL="${REPO_BASEURL:-https://pkgs.photon.lemric.com}"
PUBLISH_BRANCH="${PUBLISH_BRANCH:-gh-pages}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
GITHUB_SHA="${GITHUB_SHA:-local}"
GITHUB_TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

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

mkdir -p "${ARCH}"
cp -a "${SOURCE_DIR}"/*.rpm "${ARCH}/"
find "${ARCH}" -maxdepth 1 -name '*.src.rpm' -delete 2>/dev/null || true

createrepo_c --update "${ARCH}"

cp "${PAGES_DIR}/CNAME" "${PAGES_DIR}/.nojekyll" "${PAGES_DIR}/photon-php.repo" "${PAGES_DIR}/index.html" .
cp "${PAGES_DIR}/BRANCH-README.md" README.md
sed -i "s/@PHP_VERSION@/${PHP_VERSION}/g" index.html
sed -i "s|@GITHUB_REPOSITORY@|${GITHUB_REPOSITORY}|g" index.html

cat > repodata.json << EOF
{
  "name": "photon-php",
  "baseurl": "${REPO_BASEURL}",
  "php_version": "${PHP_VERSION}",
  "architectures": ["x86_64", "aarch64"],
  "updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "commit": "${GITHUB_SHA}",
  "stage": "${STAGE}"
}
EOF

git add -A
if git diff --staged --quiet; then
    log "No changes to publish for ${ARCH}/${STAGE}"
    exit 0
fi

git commit -m "publish: ${ARCH} ${STAGE} (${GITHUB_SHA:0:7})"

for attempt in 1 2 3 4 5 6; do
    if git push origin "HEAD:${PUBLISH_BRANCH}"; then
        log "Published ${ARCH}/${STAGE} to ${PUBLISH_BRANCH}"
        exit 0
    fi
    log "Push conflict (attempt ${attempt}) — rebasing and retrying"
    git fetch origin "${PUBLISH_BRANCH}" || true
    git rebase "origin/${PUBLISH_BRANCH}" || git rebase --abort
    sleep $((attempt * 2))
done

log "ERROR: failed to push ${PUBLISH_BRANCH} after retries" >&2
exit 1

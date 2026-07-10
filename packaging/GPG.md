# GPG signing for Photon PHP RPM repository

Production RPM packages and repository metadata are signed in CI. Clients must trust the public key before `tdnf install`.

## 1. Generate a dedicated signing key

Use a **package-signing only** key (no passphrase recommended for CI, or store passphrase in GitHub Secrets):

```bash
gpg --batch --gen-key <<'EOF'
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Photon PHP RPM Repository
Name-Email: packages@lemric.com
Expire-Date: 3y
%no-protection
%commit
EOF
```

With passphrase, omit `%no-protection` and enter a passphrase when prompted.

## 2. Export keys

```bash
# Key ID (last 16 chars of fingerprint)
gpg --list-secret-keys --keyid-format long packages@lemric.com

export RPM_GPG_KEY_ID="ABCD1234EFGH5678"   # your key id

gpg --armor --export-secret-keys "${RPM_GPG_KEY_ID}" > photon-php-signing.key
gpg --armor --export "${RPM_GPG_KEY_ID}" > pages/RPM-GPG-KEY-photon-php
```

**Never commit `photon-php-signing.key`** — only the public key in `pages/RPM-GPG-KEY-photon-php` is safe to commit (CI also publishes it to gh-pages on each reindex).

## 3. GitHub Actions secrets

In repository **Settings → Secrets and variables → Actions**, add:

| Secret | Value |
|--------|--------|
| `RPM_GPG_PRIVATE_KEY` | Full armored private key (`gpg --armor --export-secret-keys …`) |
| `RPM_GPG_KEY_ID` | Key ID or email (`packages@lemric.com`) |
| `RPM_GPG_PASSPHRASE` | Optional — only if the key has a passphrase |

CI **requires** these secrets; builds fail without them.

## 4. Install on Photon OS (production)

```bash
curl -fsSL https://pkgs.photon.lemric.com/RPM-GPG-KEY-photon-php \
  -o /etc/pki/rpm-gpg/RPM-GPG-KEY-photon-php
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-photon-php

curl -fsSL https://pkgs.photon.lemric.com/photon-php.repo \
  -o /etc/yum.repos.d/photon-php.repo

tdnf makecache
tdnf install -y php85 php85-fpm php85-opcache
```

## 5. Local builds (optional signing)

Without secrets, local `build-rpm.sh` skips signing (`gpgcheck=0` in local repos).

To sign locally:

```bash
export RPM_GPG_PRIVATE_KEY="$(gpg --armor --export-secret-keys YOUR_KEY_ID)"
export RPM_GPG_KEY_ID="YOUR_KEY_ID"
./scripts/build-rpm.sh all
```

## 6. Re-signing existing packages

`ci-reindex-repo.sh` re-signs all RPMs on gh-pages and regenerates signed repodata. Run the **Build PHP 8.5 RPMs** workflow (or reindex job) after adding secrets to migrate unsigned packages.

## What is signed

- Each binary RPM (`rpmsign` after `rpmbuild`)
- Repository metadata (`createrepo_c --gpg-sign`)

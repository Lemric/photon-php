# Photon PHP — PHP 8.5 RPM Repository for VMware Photon OS

Production-ready RPM packaging system for **PHP >= 8.5.8** compiled from official [php.net](https://www.php.net/) sources, targeting **VMware Photon OS 5.x** with full `tdnf` compatibility.

## Features

- PHP 8.5.8 built from source with optimized flags (`-O2`, LTO, stack protector, FORTIFY_SOURCE)
- Split RPM subpackages: CLI, FPM, OPcache, and 15+ standard extensions
- PECL extensions: redis, igbinary, apcu, amqp, imagick, xdebug
- Production PHP-FPM configuration with security hardening
- Multi-architecture builds: `x86_64` and `aarch64` via Docker Buildx + QEMU
- Public RPM repository via GitHub Pages: **https://pkgs.photon.lemric.com**
- Kubernetes-ready Docker images (docker-library/php compatible layout)

## Project structure

```
├── .github/workflows/     # CI/CD pipelines
├── packaging/             # PHP, re2c, rabbitmq-c RPM specs
├── extensions/            # PECL extension specs
├── docker/                # Photon OS docker-library/php compatible images
│   └── 8.5/photon/        # CLI + FPM
├── pages/                 # GitHub Pages templates (deployed to gh-pages branch)
├── scripts/               # Build automation
└── repo/                  # Local build output (not committed)
```

## Requirements

- VMware Photon OS 5.x (or `photon:5.0` Docker image)
- `tdnf`, `rpm-build`, `createrepo_c`
- Root access for local builds
- Docker + Buildx + QEMU for multi-arch builds

## Local build

### 1. Install build dependencies

On a Photon OS 5.x host or container:

```bash
git clone https://github.com/YOUR_ORG/photon-php.git
cd photon-php
sudo ./scripts/install-build-deps.sh
```

### 2. Build RPMs

```bash
# Build everything (re2c → PHP → extensions)
sudo ./scripts/build-rpm.sh all

# Or step by step:
sudo ./scripts/build-rpm.sh re2c      # re2c >= 3.x (required by PHP 8.5)
sudo ./scripts/build-rpm.sh php       # PHP core + extensions
sudo ./scripts/build-rpm.sh extensions # PECL extensions only
```

RPMs are written to `repo/$(uname -m)/`.

### 3. Create repository

```bash
sudo ./scripts/build-repo.sh
```

### 4. Build with Docker (recommended)

```bash
# Builder image
docker build -f docker/Dockerfile.builder -t photon-php-builder .

# Build RPMs
docker run --rm -v "$(pwd):/build" -w /build photon-php-builder all

# Create repo metadata
docker run --privileged --rm -v "$(pwd):/build" -w /build photon:5.0 \
  bash -c "tdnf install -y createrepo_c && ./scripts/build-repo.sh"
```

### Multi-architecture build

```bash
docker buildx create --use --name photon-builder 2>/dev/null || true

for ARCH in x86_64 aarch64; do
  PLATFORM=$([ "$ARCH" = "aarch64" ] && echo "linux/arm64" || echo "linux/amd64")
  docker run --privileged --rm --platform "$PLATFORM" \
    -v "$(pwd):/build" -w /build \
    -e ARCH="$ARCH" \
    -e OUTPUT_DIR="/build/repo/$ARCH" \
    photon:5.0 \
    bash -c "chmod +x scripts/*.sh && scripts/install-build-deps.sh && scripts/build-rpm.sh all"
done

docker run --privileged --rm -v "$(pwd):/build" -w /build photon:5.0 \
  bash -c "tdnf install -y createrepo_c && ./scripts/build-repo.sh"
```

## Installing RPMs

### From GitHub Pages (recommended)

Public repository: **https://pkgs.photon.lemric.com**

```bash
ARCH=$(uname -m)

curl -fsSL https://pkgs.photon.lemric.com/photon-php.repo \
  | sed "s|/x86_64|/${ARCH}|g" \
  > /etc/yum.repos.d/photon-php.repo

tdnf makecache
tdnf install -y php85 php85-fpm php85-opcache
```

Or configure manually:

```bash
ARCH=$(uname -m)

cat > /etc/yum.repos.d/photon-php.repo << EOF
[photon-php]
name=Photon PHP 8.5
baseurl=https://pkgs.photon.lemric.com/${ARCH}
enabled=1
gpgcheck=0
EOF

tdnf makecache
```

### From local build

### Install packages

```bash
# Minimal web stack
tdnf install -y php85 php85-fpm php85-opcache

# Full production stack
tdnf install -y \
  php85 php85-cli php85-fpm php85-common php85-opcache \
  php85-mbstring php85-intl php85-xml php85-curl php85-gd \
  php85-zip php85-bcmath php85-mysqlnd php85-pgsql \
  php85-pecl-redis php85-pecl-igbinary
```

### Verify installation

```bash
php -v
php -m
php-fpm -t
systemctl enable --now php85-php-fpm
```

## PHP configuration

| Path | Purpose |
|------|---------|
| `/etc/php85/php.ini` | Main PHP configuration (production) |
| `/etc/php85/conf.d/` | Extension `.ini` drop-ins |
| `/etc/php85/php-fpm.conf` | FPM global config |
| `/etc/php85/php-fpm.d/www.conf` | Default pool |
| `/usr/lib64/php85/modules/` | PHP extension `.so` files |

### Security defaults

- `expose_php = Off`
- `display_errors = Off`, `log_errors = On`
- Dangerous functions disabled (`exec`, `shell_exec`, etc.)
- FPM: `clear_env = yes`, `security.limit_extensions = .php`
- OPcache: `validate_timestamps = 0` (production), JIT tracing enabled

## Docker images (Photon OS)

Docker images compile PHP from source following the [docker-library/php](https://github.com/docker-library/php) layout on **Photon OS 5.x**.

### Build

```bash
docker build -f docker/8.5/photon/cli/Dockerfile -t php:8.5.8-cli-photon docker/8.5/photon/cli
docker build -f docker/8.5/photon/fpm/Dockerfile -t php:8.5.8-fpm-photon docker/8.5/photon/fpm
```

### Usage

```bash
docker run --rm -it php:8.5.8-cli-photon php -v
docker run -d --name php-fpm -p 9000:9000 php:8.5.8-fpm-photon
docker run --rm php:8.5.8-cli-photon docker-php-ext-install pdo_mysql gd
```

### Kubernetes (FPM)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-fpm
spec:
  replicas: 2
  selector:
    matchLabels:
      app: php-fpm
  template:
    metadata:
      labels:
        app: php-fpm
    spec:
      containers:
        - name: php-fpm
          image: php:8.5.8-fpm-photon
          ports:
            - containerPort: 9000
          readinessProbe:
            exec:
              command: ["php-fpm", "-t"]
            initialDelaySeconds: 5
          livenessProbe:
            exec:
              command: ["php-fpm", "-t"]
            periodSeconds: 30
```

See [docker/README.md](docker/README.md) for details.

### RPM vs Docker

| | RPM (`tdnf`) | Docker |
|---|---|---|
| Distribution | https://pkgs.photon.lemric.com | Container image |
| Binary | `/usr/bin/php` | `/usr/local/bin/php` |
| Configuration | `/etc/php85/` | `/usr/local/etc/php/` |
| Compatibility | Photon OS native | docker-library/php |
| Extensions | Separate RPMs | `docker-php-ext-install` |

Both approaches compile PHP 8.5.8 from php.net sources.

## GitHub Pages

The RPM repository is published to the dedicated **`gh-pages`** branch and served at **https://pkgs.photon.lemric.com**.

| Branch | Contents |
|--------|----------|
| `main` | Source code, specs, CI workflows |
| `gh-pages` | RPM packages only (`x86_64/`, `aarch64/`, repo metadata) |

The `gh-pages` branch is updated automatically on every push to `main` by the `pages.yml` workflow. Do not commit source code to `gh-pages`.

### GitHub repository settings

1. **Settings → Pages → Build and deployment**
2. **Source:** Deploy from a branch
3. **Branch:** `gh-pages` / `/ (root)`
4. **Custom domain:** `pkgs.photon.lemric.com`
5. Enable **Enforce HTTPS** after DNS propagation

### DNS configuration

| Type | Name | Value |
|------|------|-------|
| CNAME | `pkgs.photon` | `<org>.github.io` |

4. Enable **Enforce HTTPS** after DNS propagation.

## GitHub Actions

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `pages.yml` | Push to main, release | Build RPMs and publish to `gh-pages` branch |
| `build-php85.yml` | Push to main | Build PHP core RPMs (CI validation) |
| `build-extensions.yml` | Push to extensions/ | Build PECL extension RPMs |
| `test-install.yml` | Push/PR | Install RPMs and run functional tests |
| `release.yml` | Tag `php-8.5.*` | Build, package, and publish GitHub Release |

### Creating a release

```bash
git tag php-8.5.8
git push origin php-8.5.8
```

This triggers a release with RPM tarballs for both architectures.

## Updating PHP

1. Update version in `packaging/macros.php85` and `packaging/php85.spec`
2. Update `Source0` URL (auto-derived from `Version`)
3. Update `extensions/macros.inc` with new PHP version
4. Rebuild PECL extensions (API version may change)
5. Run full test suite: `./scripts/build-rpm.sh all`
6. Tag and release: `git tag php-8.5.X && git push origin php-8.5.X`

The build script auto-detects PHP API version from `php-config --phpapi` after building PHP core.

## Dependencies not in Photon OS

Some packages may not exist in default Photon OS 5.x repositories. This project provides specs to build them:

| Package | Spec | Required for |
|---------|------|-------------|
| `re2c` >= 3.x | `packaging/re2c.spec` | PHP 8.5 build |
| `libzip` | `packaging/libzip.spec` | php85-zip extension |
| `rabbitmq-c` | `packaging/rabbitmq-c.spec` | php85-pecl-amqp |

See [packaging/photon-packages.md](packaging/photon-packages.md) for Photon OS vs Fedora package name mapping.

Build order is handled automatically by `scripts/build-rpm.sh`.

### ImageMagick

If `ImageMagick-devel` is not available in Photon repos:

```bash
# Check availability
tdnf info ImageMagick-devel

# If missing, install from Photon contrib or build from source
# then rebuild: ./scripts/build-rpm.sh extensions
```

## Build flags

```spec
CFLAGS  = -O2 -flto=auto -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC
LDFLAGS = -Wl,-z,relro -Wl,-z,now -flto=auto
```

PHP configure includes all required extensions as shared modules for clean RPM splitting. Binaries are stripped to minimize package size.

## RPM hardening

- Files installed only under `/usr`, `/etc`, `/var`
- Correct ownership and permissions (`%defattr`)
- Dedicated `php-fpm` system user
- FPM systemd unit with `ProtectSystem`, `NoNewPrivileges`, syscall filtering
- Rootless Docker compatible

## License

PHP is licensed under the [PHP License v3.01](https://www.php.net/license/3_01.txt). PECL extensions follow their respective licenses. Build scripts and specs in this repository are provided as-is for production use.

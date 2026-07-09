# Docker images

Docker images compile PHP 8.5.8 from php.net sources following the [docker-library/php](https://github.com/docker-library/php) Alpine layout — minimal `tdnf` footprint, source compile, build-deps cleanup, `/usr/local` install path, and `docker-php-*` helper scripts.

Base image: **VMware Photon OS 5.x** (`photon:5.0`).

## Why Docker is fast vs RPM CI

| | Docker (this directory) | RPM (`scripts/install-build-deps.sh`) |
|---|---|---|
| Goal | Runnable PHP container | `tdnf install php85` packages |
| Package install | ~15 devel headers, then removed | ~500 MB toolchain + rpm-build + llvm + postgresql + … |
| PHP build | Single `configure && make install` | re2c RPM → libzip RPM → php85 RPM → PECL RPMs |
| Typical CI time | ~5–15 min | ~30–60+ min |

RPM builds are slow because Photon OS has no `re2c >= 3`, `libzip-devel`, or `rabbitmq-c-devel` — everything must be bootstrapped through `rpmbuild`. Docker skips RPM entirely and compiles PHP directly, exactly like [Alpine 3.23 CLI](https://github.com/docker-library/php/blob/master/8.5/alpine3.23/cli/Dockerfile).

## Structure

```
docker/8.5/photon/
├── common/          # shared docker-php-* scripts
├── cli/Dockerfile   # PHP CLI + phpdbg + embed
└── fpm/Dockerfile   # PHP-FPM (production)
```

## Build

```bash
# from repository root
docker build -f docker/8.5/photon/cli/Dockerfile -t php:8.5.8-cli-photon docker/8.5/photon
docker build -f docker/8.5/photon/fpm/Dockerfile -t php:8.5.8-fpm-photon docker/8.5/photon
```

## Usage

```bash
docker run --rm -it php:8.5.8-cli-photon php -v
docker run -d --name php-fpm -p 9000:9000 php:8.5.8-fpm-photon
docker run --rm php:8.5.8-cli-photon docker-php-ext-install pdo_mysql gd
```

Extensions such as `gd` and `intl` are **not** baked into the base image (same as Alpine). Install them at runtime with `docker-php-ext-install`.

## `docker-php-*` scripts

| Script | Description |
|--------|-------------|
| `docker-php-entrypoint` | Entrypoint — forwards flags to `php` |
| `docker-php-source` | Extract/delete PHP source tarball |
| `docker-php-ensure-re2c` | Build re2c 3.x when Photon repos only ship 1.x |
| `docker-php-build` | Compile PHP from source and remove build deps |
| `docker-php-ext-configure` | Run `./configure` for an extension |
| `docker-php-ext-install` | Compile and install extensions |
| `docker-php-ext-enable` | Enable a `.so` module in `conf.d` |

## RPM vs Docker

| | RPM (`tdnf`) | Docker |
|---|---|---|
| Distribution | https://pkgs.photon.lemric.com | Container image |
| PHP binary | `/usr/bin/php` | `/usr/local/bin/php` |
| Configuration | `/etc/php85/` | `/usr/local/etc/php/` |
| Extensions | Separate RPMs | `docker-php-ext-install` |

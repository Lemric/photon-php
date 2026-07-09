# Docker images

Docker images compile PHP 8.5.8 from php.net sources following the [docker-library/php](https://github.com/docker-library/php) layout — installation under `/usr/local`, `docker-php-*` helper scripts, and the same entrypoint and FPM configuration.

Base image: **VMware Photon OS 5.x** (`photon:5.0`).

## Structure

```
docker/
├── 8.5/photon/
│   ├── cli/     # PHP CLI + docker-php-ext-*
│   └── fpm/     # PHP-FPM (production)
├── Dockerfile.builder
└── README.md
```

## Build

```bash
docker build -f docker/8.5/photon/cli/Dockerfile -t php:8.5.8-cli-photon docker/8.5/photon/cli
docker build -f docker/8.5/photon/fpm/Dockerfile -t php:8.5.8-fpm-photon docker/8.5/photon/fpm
```

## Usage

```bash
docker run --rm -it php:8.5.8-cli-photon php -v
docker run -d --name php-fpm -p 9000:9000 php:8.5.8-fpm-photon
docker run --rm php:8.5.8-cli-photon docker-php-ext-install pdo_mysql gd
```

## `docker-php-*` scripts

| Script | Description |
|--------|-------------|
| `docker-php-entrypoint` | Entrypoint — forwards flags to `php` |
| `docker-php-source` | Extract/delete PHP source tarball |
| `docker-php-ext-configure` | Run `./configure` for an extension |
| `docker-php-ext-install` | Compile and install extensions |
| `docker-php-ext-enable` | Enable a `.so` module in `conf.d` |

Scripts are extended with `tdnf` support (similar to `apk` handling in upstream).

## RPM vs Docker

| | RPM (`tdnf`) | Docker |
|---|---|---|
| Distribution | https://pkgs.photon.lemric.com | Container image |
| PHP binary | `/usr/bin/php` | `/usr/local/bin/php` |
| Configuration | `/etc/php85/` | `/usr/local/etc/php/` |
| Extensions | Separate RPMs | `docker-php-ext-install` |

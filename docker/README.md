# Docker images

PHP 8.5 container images for **VMware Photon OS 5.x** (`photon:5.0`), built from GPG-signed RPMs published by CI.

## Published images (GHCR)

| Image | Description | Default command |
|-------|-------------|-----------------|
| `ghcr.io/lemric/php85-photon-base` | Core modules + CLI (RPM Requires chain) | `php` |
| `ghcr.io/lemric/php85-photon-cli` | PHP CLI | `php` |
| `ghcr.io/lemric/php85-photon-fpm` | PHP-FPM (+ CLI, required by RPM deps) | `php-fpm -F` |
| `ghcr.io/lemric/php85-photon` | Legacy alias → FPM | `php-fpm -F` |

Nginx (reverse proxy) lives in `docker/8.5/photon/nginx/` — see [Nginx + FPM](#nginx--fpm) below.

Tags: `8.5.8`, `latest`, plus per-arch tags (`8.5.8-x86_64`, …).

## Structure

```
docker/8.5/photon/rpm/
├── Dockerfile            # multi-stage: base, cli, fpm
├── install-php-rpms.sh   # shared RPM install logic
├── repo/                 # populated at CI build time from gh-pages
└── RPM-GPG-KEY-photon-php

docker/8.5/photon/cli/    # legacy: compile from php.net sources
docker/8.5/photon/fpm/    # legacy: compile from php.net sources
```

Production images use **`rpm/`** (native RPM packages, fast CI). The `cli/` and `fpm/` source-compile Dockerfiles remain for local development without a published repo.

## Local build

```bash
# Copy RPMs from gh-pages checkout into repo/
cp /path/to/gh-pages/x86_64/*.rpm docker/8.5/photon/rpm/repo/
cp /path/to/gh-pages/RPM-GPG-KEY-photon-php docker/8.5/photon/rpm/

docker build --target cli -f docker/8.5/photon/rpm/Dockerfile \
  -t php:8.5.8-cli-photon docker/8.5/photon/rpm

docker build --target fpm -f docker/8.5/photon/rpm/Dockerfile \
  -t php:8.5.8-fpm-photon docker/8.5/photon/rpm
```

## Usage

```bash
# CLI
docker run --rm -it ghcr.io/lemric/php85-photon-cli:8.5.8 php -v
docker run --rm ghcr.io/lemric/php85-photon-cli:8.5.8 php script.php

# FPM
docker run -d --name php-fpm -p 9000:9000 ghcr.io/lemric/php85-photon-fpm:8.5.8
```

PHP binaries and configuration use RPM paths (`/usr/bin/php`, `/etc/php85/`).

## Nginx + FPM

The FPM image exposes port **9000** only. Use a separate nginx container as reverse proxy.

```bash
cd docker/8.5/photon
docker compose up --build
# http://localhost:8080
```

### Nginx `Permission denied` on `/etc/nginx/client_body_temp`

This happens when nginx runs as **non-root** (Kubernetes `runAsNonRoot`, `nginxinc/nginx-unprivileged`, etc.) but the config still has:

- `user nginx;` at the top level (ignored without root — harmless warning)
- temp paths under `/etc/nginx/` (not writable)

**Fix:** point temp directories to `/tmp` or `/var/cache/nginx` and drop the `user` directive:

```nginx
pid /tmp/nginx.pid;

http {
    client_body_temp_path /tmp/nginx/client_body;
    proxy_temp_path /tmp/nginx/proxy;
    fastcgi_temp_path /tmp/nginx/fastcgi;
    # ...
}
```

Use the provided `docker/8.5/photon/nginx/nginx.conf` or base image `nginxinc/nginx-unprivileged`.

### FPM rejects nginx (`Connection refused` / timeout)

Default RPM pool `www.conf` sets `listen.allowed_clients = 127.0.0.1`. The FPM Docker image removes this via `php-fpm-docker.conf` so nginx in another container can connect on `php-fpm:9000`.

## RPM vs source-compile Docker

| | `rpm/` (CI) | `cli/` + `fpm/` (legacy) |
|---|---|---|
| PHP source | Published RPMs | Compiled from php.net |
| Binary path | `/usr/bin/php` | `/usr/local/bin/php` |
| Config | `/etc/php85/` | `/usr/local/etc/php/` |
| Extensions | Pre-built RPMs (redis, igbinary, …) | `docker-php-ext-install` |
| CI trigger | After RPM publish | Manual only |

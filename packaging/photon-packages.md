# Photon OS 5.x package name mapping

VMware Photon OS uses different package names than Fedora/RHEL. This project targets Photon names exclusively.

## Build toolchain

| Fedora/RHEL | Photon OS 5.x |
|-------------|---------------|
| `gcc-c++` | `libstdc++-devel` (C++ compiler is in `gcc`) |
| `shadow-utils` | `shadow` |
| `gnupg2` | `gnupg` |

## Development headers

| Fedora/RHEL | Photon OS 5.x |
|-------------|---------------|
| `libcurl-devel` | `curl-devel` |
| `libicu-devel` | `icu-devel` |
| `freetype-devel` | `freetype2-devel` |
| `postgresql-devel` | `postgresql18-devel` |
| `libzip-devel` | Built from `packaging/libzip.spec` |

## Runtime libraries

| Fedora/RHEL | Photon OS 5.x |
|-------------|---------------|
| `libcurl` | `curl` |
| `libicu` | `icu` |
| `freetype` | `freetype2` |
| `postgresql-libs` | `postgresql18-libs` |

## Built from source (not in Photon repos)

| Package | Spec |
|---------|------|
| `re2c` >= 3.x | `packaging/re2c.spec` |
| `libzip` | `packaging/libzip.spec` |
| `rabbitmq-c` | `packaging/rabbitmq-c.spec` |

## Build order (RPM dependency chain)

`scripts/build-rpm.sh` builds and installs packages in this order. Each stage
publishes RPMs to `repo/$ARCH/`, refreshes a local `tdnf` repo, then installs
the built package before the next stage starts.

```
re2c ──┬──> libzip ──┬──> php85 ──> PECL extensions
       │             │
rabbitmq-c ──────────┘ (required by php85-pecl-amqp only; built before extensions)
```

| Stage | Spec | Required by |
|-------|------|-------------|
| 1. `re2c` | `packaging/re2c.spec` | `php85` (`BuildRequires: re2c >= 3`) |
| 2. `libzip` | `packaging/libzip.spec` | `php85-zip` (`BuildRequires: libzip-devel`) |
| 3. `rabbitmq-c` | `packaging/rabbitmq-c.spec` | `php85-pecl-amqp` |
| 4. `php` | `packaging/php85.spec` | PECL specs (`BuildRequires: php85-devel`) |
| 5. `extensions` | `extensions/*.spec` | — |

Commands:

```bash
scripts/build-rpm.sh all          # full repository
scripts/build-rpm.sh php          # re2c → libzip → php85 (chain enforced)
scripts/build-rpm.sh extensions # full chain through php85, then PECL
scripts/build-rpm.sh deps       # bootstrap only: re2c, libzip, rabbitmq-c
```

### RPM 6 on Photon OS

Photon OS 5 ships **RPM 6.0**. Custom macro files passed via `rpmbuild --macros` break built-in RPM macros. This project:

- embeds `%define` globals directly in spec files
- pre-downloads sources with `curl` in `build-rpm.sh`
- uses only `--define "_topdir ..."` when invoking `rpmbuild`

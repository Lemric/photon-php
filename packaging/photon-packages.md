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

Build order: `re2c` → `libzip` → `php85` → PECL extensions (handled by `scripts/build-rpm.sh`).

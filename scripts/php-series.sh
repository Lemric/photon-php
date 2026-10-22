#!/bin/bash
# php-series.sh — load a PHP series definition (source this file).
#
#   PHP_SERIES=86 source scripts/php-series.sh
#
# Exports PHP_MAJOR/PHP_VERSION/... from packaging/series/<PHP_SERIES>.conf and
# fills PHP_RPM_DEFINES with the rpmbuild/rpmspec --define arguments that the
# php and extension specs expect (php_major, php_ver, php_srcurl, ...).

_php_series_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PHP_SERIES="${PHP_SERIES:-85}"
_php_series_conf="${_php_series_root}/packaging/series/${PHP_SERIES}.conf"

if [ ! -f "${_php_series_conf}" ]; then
    echo "ERROR: unknown PHP_SERIES '${PHP_SERIES}' (no ${_php_series_conf})" >&2
    return 1 2>/dev/null || exit 1
fi

# shellcheck disable=SC1090
source "${_php_series_conf}"

PHP_SRCVER="${PHP_VERSION}${PHP_PRERELEASE}"
# RPM sorts 8.6.0RC4 above 8.6.0, so pre-releases get Release 0.<pre>.N instead.
PHP_RELPFX=""
if [ -n "${PHP_PRERELEASE}" ]; then
    PHP_RELPFX="0.$(echo "${PHP_PRERELEASE}" | tr '[:upper:]' '[:lower:]')."
fi

PHP_RPM_DEFINES=(
    --define "php_major ${PHP_MAJOR}"
    --define "php_branch ${PHP_BRANCH}"
    --define "php_ver ${PHP_VERSION}"
    --define "php_srcver ${PHP_SRCVER}"
    --define "php_srcurl ${PHP_SRCURL}"
    --define "php_srcdir ${PHP_SRCDIR}"
    --define "php_conflicts ${PHP_CONFLICTS}"
)
# RPM 6 rejects --define with an empty body, so only pass php_relpfx for pre-releases.
[ -n "${PHP_RELPFX}" ] && PHP_RPM_DEFINES+=(--define "php_relpfx ${PHP_RELPFX}")
export PHP_SERIES PHP_MAJOR PHP_BRANCH PHP_VERSION PHP_PRERELEASE PHP_SRCVER PHP_RELPFX

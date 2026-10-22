# PHP — main RPM spec for VMware Photon OS 5.x
# Produces php<NN>, php<NN>-common, php<NN>-cli, php<NN>-fpm, php<NN>-devel,
# php<NN>-opcache, -process, -mbstring, -intl, -xml, -curl, -gd, -zip,
# -bcmath, -sodium, -soap, -sockets, -pcntl, -mysqlnd, -pgsql.
#
# The PHP series is selected by scripts/build-rpm.sh (PHP_SERIES, default 85),
# which passes these macros from packaging/series/<NN>.conf:
#   php_major  php_branch  php_ver  php_srcver  php_srcurl  php_srcdir
#   php_relpfx  php_conflicts
# Pre-releases (RC) use Version=<x.y.z> and Release=0.<pre>.N so the final
# release sorts higher; php_srcver carries the upstream tarball version.

%global php_confdir      /etc/php%{php_major}
%global php_extdir       %{php_confdir}/conf.d
%global php_moddir       /usr/lib64/php%{php_major}/modules
%global php_includedir   /usr/include/php%{php_major}
%global php_fpm_user     php-fpm
%global php_fpm_group    php-fpm
%global php_fpm_logdir   /var/log/php%{php_major}-fpm
%global php_fpm_rundir   /run/php%{php_major}-fpm
%global php_cflags       -O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC
%global php_cxxflags     -O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC
%global php_ldflags      -Wl,-z,relro -Wl,-z,now
%global debug_package %{nil}

Name:           php%{php_major}
Version:        %{php_ver}
Release:        %{?php_relpfx}1%{?dist}
Summary:        PHP scripting language (version %{php_branch})
License:        PHP-3.01
URL:            https://www.php.net/
Source0:        %{php_srcurl}
Source1:        php.ini-production
Source2:        php-fpm.conf
Source3:        www.conf
Source4:        php-fpm.service
Source5:        10-opcache.ini

BuildRequires:  gcc
BuildRequires:  libstdc++-devel
BuildRequires:  make
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool
BuildRequires:  pkg-config
BuildRequires:  bison
BuildRequires:  re2c >= 3
BuildRequires:  openssl-devel
BuildRequires:  libxml2-devel
BuildRequires:  sqlite-devel
BuildRequires:  zlib-devel
BuildRequires:  libzip-devel
BuildRequires:  oniguruma-devel
BuildRequires:  icu-devel
BuildRequires:  curl-devel
BuildRequires:  libpng-devel
BuildRequires:  libjpeg-turbo-devel
BuildRequires:  freetype2-devel
BuildRequires:  libwebp-devel
BuildRequires:  postgresql18-devel
BuildRequires:  systemd-devel
BuildRequires:  libsodium-devel
BuildRequires:  libargon2-devel

Provides:       php = %{version}
Provides:       php-cli = %{version}
Provides:       php-fpm = %{version}
Provides:       php-common = %{version}
%{?php_conflicts:Conflicts:      %{php_conflicts}}
Requires:       %{name}-cli = %{version}-%{release}
Requires:       %{name}-common = %{version}-%{release}

%include php-common.spec
%include php-cli.spec
%include php-fpm.spec
%include php-devel.spec

%package opcache
Summary:        OPcache configuration for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description opcache
OPcache is built into PHP %{php_branch} and always loaded. This package installs
production OPcache/JIT settings under %{php_extdir}.

%files opcache
%defattr(-,root,root,-)
%config(noreplace) %{php_extdir}/10-opcache.ini

%package process
Summary:        process extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description process
The process extension provides process control functions.

%files process
%defattr(-,root,root,-)
%{php_moddir}/sysvmsg.so
%{php_moddir}/sysvsem.so
%{php_moddir}/sysvshm.so

%package mbstring
Summary:        mbstring extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       oniguruma

%description mbstring
Multibyte string handling extension for PHP.

%files mbstring
%defattr(-,root,root,-)
%{php_moddir}/mbstring.so
%config(noreplace) %{php_extdir}/20-mbstring.ini

%package intl
Summary:        intl extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       icu

%description intl
Internationalization extension for PHP.

%files intl
%defattr(-,root,root,-)
%{php_moddir}/intl.so
%config(noreplace) %{php_extdir}/20-intl.ini

%package xml
Summary:        XML extensions for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       libxml2

%description xml
DOM, SimpleXML, XML, XMLReader and XMLWriter extensions for PHP.
Built as shared modules for modular RPM packaging.

%files xml
%defattr(-,root,root,-)
%{php_moddir}/dom.so
%{php_moddir}/simplexml.so
%{php_moddir}/xml.so
%{php_moddir}/xmlreader.so
%{php_moddir}/xmlwriter.so
%config(noreplace) %{php_extdir}/20-xml.ini

%package curl
Summary:        curl extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       curl

%description curl
cURL extension for PHP.

%files curl
%defattr(-,root,root,-)
%{php_moddir}/curl.so
%config(noreplace) %{php_extdir}/20-curl.ini

%package gd
Summary:        GD imaging extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       libpng
Requires:       libjpeg-turbo
Requires:       freetype2
Requires:       libwebp

%description gd
GD imaging library extension for PHP.

%files gd
%defattr(-,root,root,-)
%{php_moddir}/gd.so
%config(noreplace) %{php_extdir}/20-gd.ini

%package zip
Summary:        zip extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       libzip

%description zip
ZIP archive handling extension for PHP.

%files zip
%defattr(-,root,root,-)
%{php_moddir}/zip.so
%config(noreplace) %{php_extdir}/20-zip.ini

%package bcmath
Summary:        bcmath extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description bcmath
Arbitrary precision mathematics extension for PHP.

%files bcmath
%defattr(-,root,root,-)
%{php_moddir}/bcmath.so
%config(noreplace) %{php_extdir}/20-bcmath.ini

%package sodium
Summary:        libsodium extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       libsodium

%description sodium
The sodium extension provides a PHP binding for libsodium (Ed25519, XChaCha20-Poly1305, etc.).

%files sodium
%defattr(-,root,root,-)
%{php_moddir}/sodium.so
%config(noreplace) %{php_extdir}/20-sodium.ini

%package soap
Summary:        SOAP extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       %{name}-xml = %{version}-%{release}

%description soap
SOAP protocol extension for PHP.

%files soap
%defattr(-,root,root,-)
%{php_moddir}/soap.so
%config(noreplace) %{php_extdir}/20-soap.ini

%package sockets
Summary:        sockets extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description sockets
Low-level socket interface extension for PHP.

%files sockets
%defattr(-,root,root,-)
%{php_moddir}/sockets.so
%config(noreplace) %{php_extdir}/20-sockets.ini

%package pcntl
Summary:        pcntl extension for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description pcntl
Process Control extension for PHP (CLI only).

%files pcntl
%defattr(-,root,root,-)
%{php_moddir}/pcntl.so
%config(noreplace) %{php_extdir}/20-pcntl.ini

%package mysqlnd
Summary:        MySQL Native Driver extensions for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}

%description mysqlnd
MySQL Native Driver with mysqli and PDO MySQL extensions.

%files mysqlnd
%defattr(-,root,root,-)
%{php_moddir}/mysqli.so
%{php_moddir}/pdo_mysql.so
%config(noreplace) %{php_extdir}/20-mysqlnd.ini

%package pgsql
Summary:        PostgreSQL extensions for PHP %{version}
Requires:       %{name}-common = %{version}-%{release}
Requires:       postgresql18-libs

%description pgsql
PostgreSQL database extensions (pgsql and pdo_pgsql) for PHP.

%files pgsql
%defattr(-,root,root,-)
%{php_moddir}/pgsql.so
%{php_moddir}/pdo_pgsql.so
%config(noreplace) %{php_extdir}/20-pgsql.ini

%description
PHP is an HTML-embedded scripting language. This meta-package pulls in
the PHP %{version} CLI interpreter and common files.

%prep
%autosetup -n %{php_srcdir}

%build
export CFLAGS="%{php_cflags}"
export CXXFLAGS="%{php_cxxflags}"
export LDFLAGS="%{php_ldflags}"

./buildconf --force

./configure \
    --prefix=/usr \
    --exec-prefix=/usr \
    --sysconfdir=%{php_confdir} \
    --with-config-file-path=%{php_confdir} \
    --with-config-file-scan-dir=%{php_extdir} \
    --libdir=%{_libdir} \
    --includedir=%{php_includedir} \
    --localstatedir=/var \
    --enable-fpm \
    --with-fpm-user=%{php_fpm_user} \
    --with-fpm-group=%{php_fpm_group} \
    --with-fpm-acl \
    --enable-cli \
    --enable-bcmath=shared \
    --enable-dom=shared \
    --enable-simplexml=shared \
    --enable-xml=shared \
    --enable-xmlreader=shared \
    --enable-xmlwriter=shared \
    --enable-mbstring=shared \
    --enable-intl=shared \
    --enable-soap=shared \
    --enable-sockets=shared \
    --enable-pcntl=shared \
    --enable-sysvmsg=shared \
    --enable-sysvsem=shared \
    --enable-sysvshm=shared \
    --enable-pdo=shared \
    --without-pdo-sqlite \
    --with-openssl \
    --with-zlib \
    --with-curl=shared \
    --with-zip=shared \
    --with-mysqli=shared,mysqlnd \
    --with-pdo-mysql=shared,mysqlnd \
    --with-pgsql=shared \
    --with-pdo-pgsql=shared \
    --enable-gd=shared \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    --with-sodium=shared \
    --with-password-argon2 \
    --enable-shared \
    --disable-static \
    --disable-debug \
    --disable-rpath \
    --disable-cgi \
    --disable-phpdbg \
    --disable-phar \
    --without-pear \
    --enable-embed=shared

%make_build

%install
# PHP's Makefile uses INSTALL_ROOT, not DESTDIR — %%make_install would install
# into the build container's real filesystem and leave BUILDROOT empty.
make install INSTALL_ROOT=%{buildroot}

# Config templates carry @PHP_MAJOR@ placeholders for versioned paths.
render() { sed 's/@PHP_MAJOR@/%{php_major}/g' "$1" > "$2" && chmod 0644 "$2"; }

install -d %{buildroot}%{php_confdir}
install -d %{buildroot}%{php_extdir}
install -d %{buildroot}%{php_moddir}
install -d %{buildroot}%{php_fpm_logdir}
install -d %{buildroot}%{php_fpm_rundir}
install -d %{buildroot}/var/lib/php%{php_major}-fpm
install -d %{buildroot}%{_unitdir}

render %{SOURCE1} %{buildroot}%{php_confdir}/php.ini
render %{SOURCE2} %{buildroot}%{php_confdir}/php-fpm.conf
install -d %{buildroot}%{php_confdir}/php-fpm.d
render %{SOURCE3} %{buildroot}%{php_confdir}/php-fpm.d/www.conf
render %{SOURCE4} %{buildroot}%{_unitdir}/php%{php_major}-php-fpm.service
render %{SOURCE5} %{buildroot}%{php_extdir}/10-opcache.ini
echo "extension=pdo.so" > %{buildroot}%{php_extdir}/15-pdo.ini

for ext in mbstring intl curl gd zip bcmath sodium soap sockets pcntl; do
    echo "extension=${ext}.so" > %{buildroot}%{php_extdir}/20-${ext}.ini
done

cat > %{buildroot}%{php_extdir}/20-xml.ini << 'XMLEOF'
extension=dom.so
extension=simplexml.so
extension=xml.so
extension=xmlreader.so
extension=xmlwriter.so
XMLEOF

cat > %{buildroot}%{php_extdir}/20-mysqlnd.ini << 'MYSQLEOF'
extension=mysqli.so
extension=pdo_mysql.so
MYSQLEOF

cat > %{buildroot}%{php_extdir}/20-pgsql.ini << 'PGSQLEOF'
extension=pgsql.so
extension=pdo_pgsql.so
PGSQLEOF

# PHP 8.x installs shared extensions under $libdir/php/extensions/<build>-<api>/,
# not under php/modules/ (that path is used by older layouts and PECL builds).
find %{buildroot}%{_libdir}/php/extensions -name '*.so' -exec mv {} %{buildroot}%{php_moddir}/ \; 2>/dev/null || true
find %{buildroot}%{_libdir} -path '*/php/modules/*.so' -exec mv {} %{buildroot}%{php_moddir}/ \; 2>/dev/null || true

if [ -f %{buildroot}%{_libdir}/libphp.so ]; then
    mv %{buildroot}%{_libdir}/libphp.so %{buildroot}%{_libdir}/libphp%{php_major}.so
fi

find %{buildroot}%{php_moddir} -name '*.so' -exec strip --strip-unneeded {} \;

missing=""
for mod in pdo bcmath mbstring intl dom simplexml xml xmlreader xmlwriter curl gd zip sodium \
           soap sockets pcntl sysvmsg sysvsem sysvshm mysqli pdo_mysql pgsql pdo_pgsql; do
    if [ ! -f %{buildroot}%{php_moddir}/${mod}.so ]; then
        missing="${missing} ${mod}.so"
    fi
done
if [ -n "${missing}" ]; then
    echo "ERROR: missing shared modules:${missing}" >&2
    ls -la %{buildroot}%{php_moddir}/ >&2 || true
    exit 1
fi

# PHP installs man pages under $prefix/php/man, not %{_mandir}.
if [ -d %{buildroot}/usr/php/man ]; then
    mkdir -p %{buildroot}%{_mandir}
    cp -a %{buildroot}/usr/php/man/. %{buildroot}%{_mandir}/
fi
rm -rf %{buildroot}/usr/php

rm -f %{buildroot}%{php_confdir}/php-fpm.conf.default

# Keep %{_libdir}/php/build for phpize; drop runtime extension trees.
rm -rf %{buildroot}%{_libdir}/php/modules 2>/dev/null || true
rm -rf %{buildroot}%{_libdir}/php/extensions 2>/dev/null || true
rm -rf %{buildroot}%{_libdir}/php%{php_major}
rm -rf %{buildroot}%{_datadir}/php
rm -rf %{buildroot}%{_localstatedir}/log/php-fpm.log 2>/dev/null || true

%check
sapi/cli/php -n -v
sapi/cli/php -n -m | head -20
sapi/cli/php -n -r 'exit(defined("PASSWORD_ARGON2ID") ? 0 : 1);'
test -f modules/sodium.so

%files
%defattr(-,root,root,-)
%license LICENSE
%doc README.md

%changelog
* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 8.5.12-1
- Upgrade to PHP 8.5.12 (security release)

* Wed Oct 21 2026 Photon PHP Build <build@photon-php.local> - 8.5.11-3
- Rebuild against ICU 78 from current Photon 5.0 updates

* Fri Jul 10 2026 Photon PHP Build <build@photon-php.local> - 8.5.11-2
- Add php85-sodium (libsodium); build with libargon2 for PASSWORD_ARGON2*
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 8.5.11-8
- Package pdo.so in php85-common; disable cgi/phpdbg/phar SAPIs
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 8.5.11-7
- Disable pdo_sqlite (pdo is shared; no sqlite subpackage in repo)
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 8.5.11-6
- Build all modular extensions as shared (.so); verify modules in %%install
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 8.5.11-5
- php85-opcache is config-only; OPcache is built into PHP 8.5 (no opcache.so)
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 8.5.11-4
- Move shared modules from php/extensions/<api>/ into %{php85_moddir}
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 8.5.11-3
- Relocate man pages from /usr/php/man to %{_mandir}; keep php/build for phpize
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 8.5.11-2
- Drop -flto=auto (breaks OPcache JIT global register variables on GCC 14)
* Thu Jul 09 2026 Photon PHP Build <build@photon-php.local> - 8.5.11-1
- Initial PHP 8.5.11 build for VMware Photon OS 5.x
